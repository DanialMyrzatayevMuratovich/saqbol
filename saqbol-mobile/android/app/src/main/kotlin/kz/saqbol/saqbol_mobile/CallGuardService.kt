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
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.Executors

/**
 * Screens every incoming call and warns when the caller's number has a bad
 * reputation on the backend.
 *
 * The call is always allowed through: reputation is probabilistic, and silently
 * dropping a legitimate call is worse than a warning the user can ignore.
 */
@RequiresApi(Build.VERSION_CODES.N)
class CallGuardService : CallScreeningService() {

    private val executor = Executors.newSingleThreadExecutor()

    override fun onScreenCall(callDetails: Call.Details) {
        // Never hold up the call: allow it immediately, then warn out of band if
        // the lookup comes back bad. Android only grants a few seconds here.
        respondToCall(callDetails, CallResponse.Builder().build())

        val number = callDetails.handle?.schemeSpecificPart ?: return
        if (number.isBlank()) return

        executor.execute {
            try {
                val risk = fetchRisk(number) ?: return@execute
                if (risk.score >= RISK_THRESHOLD) {
                    warn(number, risk)
                }
            } catch (error: Exception) {
                // Offline or backend down — screening is best-effort.
                Log.w(TAG, "reputation lookup failed", error)
            }
        }
    }

    private data class Risk(val score: Double, val reports: Int)

    private fun fetchRisk(number: String): Risk? {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val baseUrl = prefs.getString(KEY_API_BASE, null) ?: return null
        val token = prefs.getString(KEY_TOKEN, null) ?: return null

        val encoded = URLEncoder.encode(number, "UTF-8")
        val connection = URL("$baseUrl/numbers/$encoded/risk").openConnection()
                as HttpURLConnection
        connection.apply {
            requestMethod = "GET"
            setRequestProperty("Authorization", "Bearer $token")
            connectTimeout = 4000
            readTimeout = 4000
        }

        try {
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null
            val payload = JSONObject(connection.inputStream.bufferedReader().readText())
            if (!payload.optBoolean("known", false)) return null
            return Risk(
                score = payload.optDouble("risk_score", 0.0),
                reports = payload.optInt("reports_count", 0),
            )
        } finally {
            connection.disconnect()
        }
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
        val notification = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle("⚠️ Подозрительный звонок: $number")
            .setContentText("Риск $percent% — жалоб: ${risk.reports}")
            .setAutoCancel(true)
            .build()

        manager.notify(number.hashCode(), notification)
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "CallGuardService"

        /** Below this the number is not suspicious enough to interrupt the user. */
        private const val RISK_THRESHOLD = 0.6

        const val PREFS = "saqbol_guard"
        const val KEY_TOKEN = "access_token"
        const val KEY_API_BASE = "api_base_url"
        private const val CHANNEL_ID = "saqbol_calls"
    }
}
