package kz.saqbol.saqbol_mobile

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.annotation.RequiresApi
import org.json.JSONObject
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledThreadPoolExecutor

/**
 * Screens every incoming call and warns when the caller's number has a bad
 * reputation on the backend.
 *
 * The call is always allowed through: reputation is probabilistic, and silently
 * dropping a legitimate call is worse than a warning the user can ignore.
 */
@RequiresApi(Build.VERSION_CODES.N)
class CallGuardService : CallScreeningService() {

    private val gate = ScreeningGate(
        lookups = Executors.newFixedThreadPool(ScreeningGate.LOOKUP_THREADS),
        // A deadline whose lookup answered first leaves the queue at once.
        deadlines = ScheduledThreadPoolExecutor(1).apply { removeOnCancelPolicy = true },
        log = { message, error -> Log.w(TAG, message, error) },
    )

    override fun onScreenCall(callDetails: Call.Details) {
        // Answer only after the lookup, or when the per-call deadline passes.
        // Telecom unbinds the service as soon as it has an answer, and an app
        // in the background can then be frozen before the warning is shown.
        // The answer is always "allow", so the call itself is never blocked.
        gate.screen(
            number = callDetails.handle?.schemeSpecificPart,
            lookup = ::fetchRisk,
            onResult = { number, risk ->
                if (risk.score >= RISK_THRESHOLD) warn(number, risk)
            },
            respond = { allow(callDetails) },
        )
    }

    private fun allow(callDetails: Call.Details) {
        respondToCall(callDetails, CallResponse.Builder().build())
    }

    private data class Risk(val score: Double, val reports: Int)

    private fun fetchRisk(number: String, cancellation: Cancellation): Risk? {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val baseUrl = prefs.getString(KEY_API_BASE, null) ?: return null
        val token = prefs.getString(KEY_TOKEN, null) ?: return null

        val encoded = URLEncoder.encode(number, "UTF-8")
        val body = ReputationHttp.get(
            URL("$baseUrl/numbers/$encoded/risk"),
            token,
            cancellation,
        ) ?: return null

        val payload = JSONObject(body)
        if (!payload.optBoolean("known", false)) return null
        return Risk(
            score = payload.optDouble("risk_score", 0.0),
            reports = payload.optInt("reports_count", 0),
        )
    }

    @SuppressLint("MissingPermission")
    private fun warn(number: String, risk: Risk) {
        val manager = getSystemService(NotificationManager::class.java) ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "SaqBol",
                    NotificationManager.IMPORTANCE_HIGH,
                )
            )
        }

        val percent = (risk.score * 100).toInt()
        val locale = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_LOCALE, null)
        val title: String
        val text: String
        when (locale) {
            "kk" -> {
                title = "⚠️ Күдікті қоңырау: $number"
                text = "Қауіп $percent% — шағымдар: ${risk.reports}"
            }
            "en" -> {
                title = "⚠️ Suspicious call: $number"
                text = "Risk $percent% — reports: ${risk.reports}"
            }
            else -> {
                title = "⚠️ Подозрительный звонок: $number"
                text = "Риск $percent% — жалоб: ${risk.reports}"
            }
        }
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle(title)
            .setContentText(text)
            .setAutoCancel(true)
            .build()

        manager.notify(number.hashCode(), notification)
    }

    override fun onDestroy() {
        gate.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "CallGuardService"

        /** Below this the number is not suspicious enough to interrupt the user. */
        private const val RISK_THRESHOLD = 0.6

        const val PREFS = "saqbol_guard"
        const val KEY_TOKEN = "access_token"
        const val KEY_API_BASE = "api_base_url"
        const val KEY_LOCALE = "locale"
        private const val CHANNEL_ID = "saqbol_calls"
    }
}
