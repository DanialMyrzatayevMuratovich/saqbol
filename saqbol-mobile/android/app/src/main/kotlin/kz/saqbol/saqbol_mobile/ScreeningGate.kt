package kz.saqbol.saqbol_mobile

import java.util.concurrent.ExecutorService
import java.util.concurrent.Future
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * Gives every screened call exactly one answer, inside its own deadline.
 *
 * Answering ends our chance to warn: Telecom unbinds the screening service as
 * soon as it has an answer, and an app in the background can then be frozen.
 * Telecom also ignores an answer that comes too late. So each call races its
 * reputation lookup against a deadline that starts when [screen] is entered:
 *
 * - the lookup wins: `onResult` runs first (the warning is posted while the
 *   service is still bound), then the call is answered;
 * - the deadline wins: the call is answered straight from the deadline thread,
 *   without waiting behind other lookups, and the lookup is cancelled. A result
 *   that still arrives is dropped: after the answer the app may be frozen at
 *   any moment, so a late warning could not be relied on and might even show
 *   up after the call is over.
 *
 * Either way the answer is "allow". The call itself is never blocked.
 *
 * The class has no Android dependencies, so the timing is tested on the JVM.
 */
class ScreeningGate(
    /** Runs the lookups. A busy pool only delays lookups, never answers. */
    private val lookups: ExecutorService,
    /** Fires the deadlines. Its tasks only answer calls, so they never wait. */
    private val deadlines: ScheduledExecutorService,
    private val deadlineMillis: Long = DEADLINE_MILLIS,
    private val log: (message: String, error: Throwable?) -> Unit = { _, _ -> },
) {

    /**
     * Screens one call. [respond] is called exactly once: right away for a
     * blank [number], otherwise when [lookup] finishes or the deadline passes,
     * whichever comes first. A failed lookup counts as "no result".
     *
     * [lookup] runs on the lookup pool and should stop when its [Cancellation]
     * fires. [onResult] runs only if the lookup beat the deadline.
     */
    fun <R : Any> screen(
        number: String?,
        lookup: (number: String, cancellation: Cancellation) -> R?,
        onResult: (number: String, result: R) -> Unit,
        respond: () -> Unit,
    ) {
        if (number.isNullOrBlank()) {
            respond()
            return
        }

        val call = PendingCall(respond)
        try {
            // Scheduled before the lookup is queued, so a busy pool can never
            // push the fallback answer back.
            call.deadline = deadlines.schedule(
                { expire(call) },
                deadlineMillis,
                TimeUnit.MILLISECONDS,
            )
            val task = lookups.submit { finish(call, number, lookup, onResult) }
            call.cancellation.onCancel { task.cancel(true) }
        } catch (error: RejectedExecutionException) {
            // The service is shutting down and nothing can run the lookup.
            log("screening rejected, allowing at once", error)
            call.deadline?.cancel(false)
            if (call.claim()) respond()
        }
    }

    /**
     * Stops taking new calls. Lookups already queued still run, and deadlines
     * already scheduled still answer their calls (the default policy of
     * [java.util.concurrent.ScheduledThreadPoolExecutor]).
     */
    fun shutdown() {
        lookups.shutdown()
        deadlines.shutdown()
    }

    private fun <R : Any> finish(
        call: PendingCall,
        number: String,
        lookup: (String, Cancellation) -> R?,
        onResult: (String, R) -> Unit,
    ) {
        // Expired while it was still in the queue: the call has its answer.
        if (call.cancellation.isCancelled) return

        val result = try {
            lookup(number, call.cancellation)
        } catch (error: Exception) {
            // Offline or backend down: screening is best-effort.
            if (!call.cancellation.isCancelled) log("reputation lookup failed", error)
            null
        }

        // The deadline answered first, so this result is too late to use.
        if (!call.claim()) return
        call.deadline?.cancel(false)

        try {
            if (result != null) onResult(number, result)
        } catch (error: Exception) {
            log("could not act on the reputation", error)
        } finally {
            call.respond()
        }
    }

    private fun expire(call: PendingCall) {
        if (!call.claim()) return
        try {
            call.respond()
        } finally {
            log("no reputation within $deadlineMillis ms, allowed without it", null)
            val hooks = call.cancellation.cancel()
            // Hooks can block, so they get a short-lived thread of their own
            // and never hold up the next call's deadline. Expiry is rare: it
            // takes a backend slower than the deadline.
            if (hooks.isNotEmpty()) {
                thread(isDaemon = true, name = "screening-cancel") {
                    hooks.forEach { hook -> runCatching(hook) }
                }
            }
        }
    }

    private class PendingCall(val respond: () -> Unit) {
        val cancellation = Cancellation()

        @Volatile
        var deadline: Future<*>? = null

        private val answered = AtomicBoolean(false)

        /** True for exactly one caller: the one that answers the call. */
        fun claim(): Boolean = answered.compareAndSet(false, true)
    }

    companion object {
        /**
         * Telecom gives screening about 5 s, but that clock starts before
         * onScreenCall runs: it also covers binding the service and, when the
         * app is not running, starting its process. Answering 3.5 s after the
         * callback leaves 1.5 s for those steps and for the answer itself.
         */
        const val DEADLINE_MILLIS = 3_500L

        /**
         * Lookups the service runs at once. Calls beyond that only queue their
         * lookups; each call is still answered by its own deadline.
         */
        const val LOOKUP_THREADS = 4
    }
}

/**
 * Tells a lookup that its call has already been answered and the work is no
 * longer needed. A lookup checks [isCancelled] between steps and registers an
 * [onCancel] hook to break out of blocking I/O, e.g. by disconnecting.
 */
class Cancellation {

    @Volatile
    var isCancelled = false
        private set

    private val hooks = mutableListOf<() -> Unit>()

    /**
     * Runs [hook] when the work is cancelled, or right away if it already was.
     * The hook may block: on the JVM, `HttpURLConnection.disconnect()` waits
     * for a read in progress to return.
     */
    fun onCancel(hook: () -> Unit) {
        synchronized(hooks) {
            if (!isCancelled) {
                hooks += hook
                return
            }
        }
        hook()
    }

    /** Marks the work cancelled and returns the hooks to run, only the first time. */
    internal fun cancel(): List<() -> Unit> = synchronized(hooks) {
        if (isCancelled) return emptyList()
        isCancelled = true
        hooks.toList().also { hooks.clear() }
    }
}
