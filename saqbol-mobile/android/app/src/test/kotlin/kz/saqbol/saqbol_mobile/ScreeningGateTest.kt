package kz.saqbol.saqbol_mobile

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.Closeable
import java.io.IOException
import java.io.InputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.URL
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.ThreadLocalRandom
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.thread

/**
 * Timing of call screening, on the JVM: the real [ReputationHttp] code talks
 * to a server on loopback. This checks when the call is answered, not how a
 * phone rings or shows the warning; that is checked on a device (SAQ-45).
 */
class ScreeningGateTest {

    private val deadline = ScreeningGate.DEADLINE_MILLIS
    private val closeables = mutableListOf<Closeable>()
    private val pools = mutableListOf<ExecutorService>()
    private val logged = CopyOnWriteArrayList<String>()

    @After
    fun tearDown() {
        pools.forEach { it.shutdownNow() }
        closeables.forEach { it.close() }
    }

    @Test
    fun `fast lookup answers with its result well before the deadline`() {
        val backend = backend(Backend.fast(RISKY))
        val gate = Gate()

        val call = gate.screen { _, cancellation -> ReputationHttp.get(backend.url, TOKEN, cancellation) }
        assertTrue(call.answered.await(deadline, TimeUnit.MILLISECONDS))
        gate.drain()
        val drainedAt = call.now()

        report("fast lookup", "answered at ${call.answeredAt} ms with the result")
        assertEquals(1, call.answers.get())
        assertEquals(listOf<Any>(RISKY), call.results)
        assertTrue("the warning must come before the answer", call.resultBeforeAnswer)
        assertTrue(call.answeredAt < 500)
        // The deadline was cancelled: otherwise draining would wait for it.
        assertTrue("drained at $drainedAt ms", drainedAt < deadline)
        assertTrue(backend.exchanges.single().head.contains("Authorization: Bearer $TOKEN"))
    }

    @Test
    fun `slowly delivered body is cut off at the deadline with one fallback answer`() {
        val backend = backend(Backend.slow(RISKY, pieces = 7, gapMillis = 1000))
        val gate = Gate()

        val call = gate.screen { _, cancellation -> ReputationHttp.get(backend.url, TOKEN, cancellation) }
        assertTrue(call.answered.await(deadline + 1000, TimeUnit.MILLISECONDS))
        gate.drain()
        val exchange = backend.exchanges.single()
        assertTrue(exchange.finished.await(5, TimeUnit.SECONDS))

        report(
            "slow body",
            "answered at ${call.answeredAt} ms (deadline $deadline ms); lookup stopped at " +
                "${call.lookupEndedAt} ms; server saw the client disconnect at " +
                "${call.at(exchange.clientGoneAt)} ms after ${exchange.chunksSent} of 7 chunks " +
                "(the whole body takes 6000 ms)",
        )
        assertEquals(1, call.answers.get())
        assertTrue(call.results.isEmpty())
        assertAnsweredAtDeadline(call)
        assertTrue(call.lookupEndedAt in deadline until 6000L)
        assertTrue("client must disconnect", exchange.clientGoneAt > 0)
        assertTrue(exchange.chunksSent < 7)
    }

    @Test
    fun `queued callback is answered by its own deadline behind a slow lookup`() {
        val slow = backend(Backend.slow(RISKY, pieces = 7, gapMillis = 1000))
        val fast = backend(Backend.fast(RISKY))
        // One worker, as in the old service: the second lookup has to queue.
        val gate = Gate(lookupThreads = 1)

        val first = gate.screen { _, cancellation -> ReputationHttp.get(slow.url, TOKEN, cancellation) }
        val second = gate.screen { _, cancellation -> ReputationHttp.get(fast.url, TOKEN, cancellation) }
        assertTrue(second.answered.await(deadline + 1000, TimeUnit.MILLISECONDS))
        gate.drain()

        report(
            "queued callback",
            "first (slow) answered at ${first.answeredAt} ms, its lookup stopped at " +
                "${first.lookupEndedAt} ms; second (queued) answered at ${second.answeredAt} ms " +
                "from its own entry, its lookup ran ${fast.requests.get()} times",
        )
        for (call in listOf(first, second)) {
            assertEquals(1, call.answers.get())
            assertTrue(call.results.isEmpty())
            assertAnsweredAtDeadline(call)
        }
        assertTrue(first.lookupEndedAt < 6000)
        // The queued lookup expired before a worker was free and was dropped.
        assertEquals(0, fast.requests.get())
    }

    @Test
    fun `service pool runs a fast lookup next to a slow one`() {
        val slow = backend(Backend.slow(RISKY, pieces = 7, gapMillis = 1000))
        val fast = backend(Backend.fast(RISKY))
        val gate = Gate(lookupThreads = ScreeningGate.LOOKUP_THREADS)

        val first = gate.screen { _, cancellation -> ReputationHttp.get(slow.url, TOKEN, cancellation) }
        val second = gate.screen { _, cancellation -> ReputationHttp.get(fast.url, TOKEN, cancellation) }
        assertTrue(first.answered.await(deadline + 1000, TimeUnit.MILLISECONDS))
        gate.drain()

        report(
            "service pool",
            "slow call answered at ${first.answeredAt} ms by the deadline; " +
                "fast call answered at ${second.answeredAt} ms with the result",
        )
        assertEquals(1, first.answers.get())
        assertTrue(first.results.isEmpty())
        assertAnsweredAtDeadline(first)
        assertEquals(1, second.answers.get())
        assertEquals(listOf<Any>(RISKY), second.results)
        assertTrue(second.answeredAt < 500)
    }

    @Test
    fun `offline backend allows the call at once`() {
        val gate = Gate()
        val url = closedPortUrl()

        val call = gate.screen { _, cancellation -> ReputationHttp.get(url, TOKEN, cancellation) }
        assertTrue(call.answered.await(deadline, TimeUnit.MILLISECONDS))
        gate.drain()

        report("offline", "answered at ${call.answeredAt} ms after ${call.lookupError}")
        assertEquals(1, call.answers.get())
        assertTrue(call.results.isEmpty())
        assertTrue(call.answeredAt < 500)
        assertTrue(call.lookupError is IOException)
        assertTrue(logged.contains("reputation lookup failed"))
    }

    @Test
    fun `backend error status allows the call at once`() {
        val backend = backend(Backend.status(503))
        val gate = Gate()

        val call = gate.screen { _, cancellation -> ReputationHttp.get(backend.url, TOKEN, cancellation) }
        assertTrue(call.answered.await(deadline, TimeUnit.MILLISECONDS))
        gate.drain()

        report("error status", "answered at ${call.answeredAt} ms after HTTP 503")
        assertEquals(1, call.answers.get())
        assertTrue(call.results.isEmpty())
        assertTrue(call.answeredAt < 500)
    }

    @Test
    fun `failing lookup or failing warning still allows the call once`() {
        val gate = Gate()

        val failedLookup = gate.screen<String> { _, _ -> throw IllegalStateException("boom") }
        val failedWarning = gate.screen(
            onResult = { _, _ -> throw IllegalStateException("no notification") },
        ) { _, _ -> RISKY }
        for (call in listOf(failedLookup, failedWarning)) {
            assertTrue(call.answered.await(deadline, TimeUnit.MILLISECONDS))
        }
        gate.drain()

        for (call in listOf(failedLookup, failedWarning)) {
            assertEquals(1, call.answers.get())
            assertTrue(call.answeredAt < 500)
        }
        assertTrue(logged.contains("reputation lookup failed"))
        assertTrue(logged.contains("could not act on the reputation"))
    }

    @Test
    fun `blank number is allowed immediately without a lookup`() {
        val gate = Gate()
        val lookups = AtomicInteger()

        for (number in listOf(null, "", "   ")) {
            val call = gate.screen(number = number) { _, _ -> lookups.incrementAndGet(); RISKY }
            // Answered before screen() returned, on the callback's own thread.
            assertEquals(1, call.answers.get())
            assertEquals(Thread.currentThread(), call.answerThread)
        }
        gate.drain()

        assertEquals(0, lookups.get())
        assertEquals(0L, gate.deadlines.taskCount)
    }

    @Test
    fun `deadline interrupts a lookup that is stuck without network`() {
        val gate = Gate(deadlineMillis = 200)

        val call = gate.screen<String> { _, _ ->
            CountDownLatch(1).await()
            RISKY
        }
        gate.drain()

        report("stuck lookup", "answered at ${call.answeredAt} ms, lookup stopped at ${call.lookupEndedAt} ms")
        assertEquals(1, call.answers.get())
        assertTrue(call.answeredAt in 200L until 400L)
        assertTrue(call.lookupEndedAt < 600)
        assertTrue(call.lookupError is InterruptedException)
    }

    @Test
    fun `lookup and deadline racing still give exactly one answer`() {
        val gate = Gate(lookupThreads = 8, deadlineMillis = 20)

        val calls = (1..300).map {
            gate.screen { _, _ ->
                Thread.sleep(ThreadLocalRandom.current().nextLong(0, 40))
                RISKY
            }
        }
        gate.drain()

        val byLookup = calls.count { it.results.isNotEmpty() }
        report("race", "300 calls: $byLookup answered by the lookup, ${300 - byLookup} by the deadline")
        for (call in calls) {
            assertEquals(1, call.answers.get())
            // A result is used only before the answer, never after it.
            if (call.results.isNotEmpty()) assertTrue(call.resultBeforeAnswer)
        }
        assertTrue(byLookup in 1 until 300)
    }

    // ------------------------------------------------------------- helpers

    private fun assertAnsweredAtDeadline(call: Probe) {
        assertTrue("answered at ${call.answeredAt} ms", call.answeredAt in deadline..deadline + 300)
    }

    private fun report(name: String, line: String) = println("[timing] $name: $line")

    private fun backend(handler: (Exchange) -> Unit) = Backend(handler).also { closeables += it }

    /** A port nothing listens on, so connecting fails like an offline backend. */
    private fun closedPortUrl(): URL {
        val port = ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { it.localPort }
        return URL("http://127.0.0.1:$port/numbers/%2B77770001100/risk")
    }

    private inner class Gate(lookupThreads: Int = 2, deadlineMillis: Long = deadline) {
        val lookups: ExecutorService = Executors.newFixedThreadPool(lookupThreads).also { pools += it }
        val deadlines = ScheduledThreadPoolExecutor(1)
            .apply { removeOnCancelPolicy = true } // as in CallGuardService
            .also { pools += it }
        val gate = ScreeningGate(lookups, deadlines, deadlineMillis) { message, _ ->
            logged += message
        }

        /** Screens one call, timed from this moment as from callback entry. */
        fun <R : Any> screen(
            number: String? = NUMBER,
            onResult: ((Probe, R) -> Unit)? = null,
            lookup: (String, Cancellation) -> R?,
        ): Probe {
            val call = Probe()
            gate.screen(
                number,
                lookup = { n, cancellation ->
                    try {
                        lookup(n, cancellation)
                    } catch (error: Exception) {
                        call.lookupError = error
                        throw error
                    } finally {
                        call.lookupEndedAt = call.now()
                    }
                },
                onResult = { _, result ->
                    if (onResult != null) onResult(call, result) else call.result(result)
                },
                respond = call::respond,
            )
            return call
        }

        /**
         * Waits until every lookup has stopped and every deadline has fired.
         * A lookup that ignored its cancellation would keep this waiting.
         */
        fun drain() {
            gate.shutdown()
            for (pool in listOf(lookups, deadlines)) {
                assertTrue(pool.awaitTermination(10, TimeUnit.SECONDS))
            }
        }
    }

    /** Records what happened to one screened call, in ms from its start. */
    private class Probe {
        private val start = System.nanoTime()
        val answers = AtomicInteger()
        val answered = CountDownLatch(1)
        val results = CopyOnWriteArrayList<Any>()

        @Volatile var answeredAt = -1L
        @Volatile var answerThread: Thread? = null
        @Volatile var resultBeforeAnswer = false
        @Volatile var lookupEndedAt = -1L
        @Volatile var lookupError: Throwable? = null

        fun now() = at(System.nanoTime())

        fun at(nanos: Long) = TimeUnit.NANOSECONDS.toMillis(nanos - start)

        fun respond() {
            if (answers.incrementAndGet() == 1) {
                answeredAt = now()
                answerThread = Thread.currentThread()
            }
            answered.countDown()
        }

        fun result(value: Any) {
            resultBeforeAnswer = answers.get() == 0
            results += value
        }
    }

    /** A minimal HTTP/1.1 server on loopback, one thread per request. */
    private class Backend(private val handler: (Exchange) -> Unit) : Closeable {
        private val server = ServerSocket(0, 50, InetAddress.getLoopbackAddress())
        val url = URL("http://127.0.0.1:${server.localPort}/numbers/%2B77770001100/risk")
        val requests = AtomicInteger()
        val exchanges = CopyOnWriteArrayList<Exchange>()

        init {
            thread(isDaemon = true, name = "fake-backend") {
                while (true) {
                    val socket = try {
                        server.accept()
                    } catch (closed: IOException) {
                        return@thread
                    }
                    requests.incrementAndGet()
                    val exchange = Exchange(socket).also { exchanges += it }
                    thread(isDaemon = true) { exchange.run(handler) }
                }
            }
        }

        override fun close() = server.close()

        companion object {
            fun fast(body: String): (Exchange) -> Unit = { exchange ->
                exchange.write(
                    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" +
                        "Content-Length: ${body.toByteArray().size}\r\nConnection: close\r\n\r\n$body",
                )
            }

            fun status(code: Int): (Exchange) -> Unit = { exchange ->
                exchange.write("HTTP/1.1 $code Error\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
            }

            /** As in the review of PR #18: the body comes in [pieces] chunks, [gapMillis] apart. */
            fun slow(body: String, pieces: Int, gapMillis: Long): (Exchange) -> Unit = { exchange ->
                exchange.write(
                    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" +
                        "Transfer-Encoding: chunked\r\n\r\n",
                )
                for (index in 0 until pieces) {
                    if (index > 0) Thread.sleep(gapMillis)
                    if (exchange.clientGoneAt > 0) break
                    val piece = body.substring(index * body.length / pieces, (index + 1) * body.length / pieces)
                    exchange.write("${Integer.toHexString(piece.length)}\r\n$piece\r\n")
                    exchange.chunksSent++
                }
                if (exchange.clientGoneAt <= 0) exchange.write("0\r\n\r\n")
            }
        }
    }

    private class Exchange(private val socket: Socket) {
        val finished = CountDownLatch(1)

        @Volatile var head = ""
        @Volatile var chunksSent = 0
        /** System.nanoTime() when the client closed the connection, or 0. */
        @Volatile var clientGoneAt = 0L
        @Volatile private var serverDone = false

        fun run(handler: (Exchange) -> Unit) {
            try {
                socket.use {
                    val input = socket.getInputStream()
                    head = readHead(input)
                    // The client sends nothing more, so the next read only
                    // returns when it closes the connection.
                    thread(isDaemon = true) {
                        try {
                            while (input.read() >= 0) Unit
                        } catch (_: IOException) {
                        }
                        if (!serverDone) clientGoneAt = System.nanoTime()
                    }
                    handler(this)
                    serverDone = true
                }
            } catch (_: IOException) {
                // The client went away in the middle of the response.
            } finally {
                finished.countDown()
            }
        }

        fun write(text: String) {
            socket.getOutputStream().apply {
                write(text.toByteArray())
                flush()
            }
        }

        private fun readHead(input: InputStream): String {
            val head = StringBuilder()
            while (!head.endsWith("\r\n\r\n")) {
                val byte = input.read()
                if (byte < 0) break
                head.append(byte.toChar())
            }
            return head.toString()
        }
    }

    private companion object {
        const val NUMBER = "+77770001100"
        const val TOKEN = "test-token"
        const val RISKY = """{"known":true,"risk_score":0.93,"reports_count":12}"""
    }
}
