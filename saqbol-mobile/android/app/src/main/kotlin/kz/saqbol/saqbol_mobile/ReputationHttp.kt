package kz.saqbol.saqbol_mobile

import java.net.HttpURLConnection
import java.net.URL

/**
 * The HTTP part of the reputation lookup. It has no Android dependencies, so
 * the tests run this exact code against a local server.
 */
internal object ReputationHttp {

    /**
     * These only limit a single wait for the network. A body that keeps
     * trickling in never trips the read timeout, so the whole lookup is
     * bounded by the [ScreeningGate] deadline instead.
     */
    const val CONNECT_TIMEOUT_MILLIS = 1500
    const val READ_TIMEOUT_MILLIS = 2000

    /**
     * Returns the body of a 200 response to `GET url`, or null for any other
     * status or once [cancellation] fires. Network errors are thrown.
     */
    fun get(url: URL, token: String, cancellation: Cancellation): String? {
        val connection = url.openConnection() as HttpURLConnection
        connection.apply {
            requestMethod = "GET"
            setRequestProperty("Authorization", "Bearer $token")
            connectTimeout = CONNECT_TIMEOUT_MILLIS
            readTimeout = READ_TIMEOUT_MILLIS
        }
        // Closing the socket is what stops a read that is blocked waiting for
        // the next piece of the body.
        cancellation.onCancel { connection.disconnect() }

        try {
            if (cancellation.isCancelled) return null
            if (connection.responseCode != HttpURLConnection.HTTP_OK) return null

            val body = StringBuilder()
            val buffer = CharArray(1024)
            connection.inputStream.bufferedReader().use { reader ->
                while (!cancellation.isCancelled) {
                    val count = reader.read(buffer)
                    if (count < 0) return body.toString()
                    body.append(buffer, 0, count)
                }
            }
            return null
        } finally {
            connection.disconnect()
        }
    }
}
