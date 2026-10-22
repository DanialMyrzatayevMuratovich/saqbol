package kz.saqbol.saqbol_mobile

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Runs the unchanged ScreeningGate from PR18 with a deliberately blocked result
 * callback. This is a JVM callback-budget probe, not an Android-device test.
 * No network, credentials, notifications, or phone numbers are used.
 */
fun main() {
    val lookups = Executors.newFixedThreadPool(1)
    val deadlines = ScheduledThreadPoolExecutor(1).apply { removeOnCancelPolicy = true }
    val gate = ScreeningGate(lookups, deadlines)
    val resultEntered = CountDownLatch(1)
    val releaseResult = CountDownLatch(1)
    val answered = CountDownLatch(1)
    val answers = AtomicInteger()
    val elapsedMillis = AtomicLong(-1)
    val start = System.nanoTime()
    try {
        gate.screen(
            number = "local-probe",
            lookup = { _, _ -> "result" },
            onResult = { _, _ ->
                resultEntered.countDown()
                check(releaseResult.await(8, TimeUnit.SECONDS))
            },
            respond = {
                answers.incrementAndGet()
                elapsedMillis.set(TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start))
                answered.countDown()
            },
        )
        check(resultEntered.await(1, TimeUnit.SECONDS))
        val answeredWithinFiveSeconds = answered.await(5, TimeUnit.SECONDS)
        val beforeRelease = answers.get()
        releaseResult.countDown()
        check(answered.await(1, TimeUnit.SECONDS))
        gate.shutdown()
        check(lookups.awaitTermination(1, TimeUnit.SECONDS))
        check(deadlines.awaitTermination(1, TimeUnit.SECONDS))
        println(
            "{\"configured_deadline_ms\":${ScreeningGate.DEADLINE_MILLIS}," +
                "\"answered_within_5s_after_result_started\":$answeredWithinFiveSeconds," +
                "\"answer_count_before_release\":$beforeRelease," +
                "\"answer_count_final\":${answers.get()}," +
                "\"answer_ms_from_entry\":${elapsedMillis.get()}}"
        )
        check(!answeredWithinFiveSeconds && beforeRelease == 0)
        check(answers.get() == 1 && elapsedMillis.get() >= 5000)
    } finally {
        releaseResult.countDown()
        lookups.shutdownNow()
        deadlines.shutdownNow()
    }
}
