package kz.saqbol.saqbol_mobile

import android.app.role.RoleManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // CallGuardService runs outside the Flutter engine and cannot
                    // reach flutter_secure_storage, so the credentials it needs
                    // are mirrored into SharedPreferences from the Dart side.
                    "syncCredentials" -> {
                        getSharedPreferences(CallGuardService.PREFS, Context.MODE_PRIVATE)
                            .edit()
                            .putString(CallGuardService.KEY_TOKEN, call.argument<String>("token"))
                            .putString(CallGuardService.KEY_API_BASE, call.argument<String>("apiBaseUrl"))
                            .apply()
                        result.success(true)
                    }

                    "isCallScreeningEnabled" -> result.success(isCallScreeningRoleHeld())

                    "requestCallScreeningRole" -> result.success(requestCallScreeningRole())

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Call screening requires the user to hand this app the system call-screening
     * role. Only one app per device can hold it, and it is granted through a
     * system dialog rather than a runtime permission prompt.
     */
    private fun requestCallScreeningRole(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false

        val roleManager = getSystemService(RoleManager::class.java) ?: return false
        if (!roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) return false
        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) return true

        startActivityForResult(
            roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING),
            REQUEST_CALL_SCREENING_ROLE,
        )
        return true
    }

    private fun isCallScreeningRoleHeld(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val roleManager = getSystemService(RoleManager::class.java) ?: return false
        return roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    companion object {
        private const val CHANNEL = "kz.saqbol/guard"
        private const val REQUEST_CALL_SCREENING_ROLE = 1001
    }
}
