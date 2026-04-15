package app.saku_rapi.com.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import app.saku_rapi.com.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale

/**
 * AppWidgetProvider untuk Saku Rapi home widget.
 *
 * Menampilkan carousel wallet (dengan tombol prev/next),
 * toggle visibilitas saldo (eye icon),
 * dan 4 quick action buttons (manual, voice, ocr, text).
 */
class SakuRapiWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "SakuRapiWidget"

        // Actions for PendingIntent
        const val ACTION_PREV = "app.saku_rapi.com.widget.ACTION_PREV"
        const val ACTION_NEXT = "app.saku_rapi.com.widget.ACTION_NEXT"
        const val ACTION_TOGGLE_BALANCE = "app.saku_rapi.com.widget.ACTION_TOGGLE_BALANCE"

        // SharedPreferences keys — harus sama dengan HomeWidgetConstants di Dart
        const val KEY_WALLET_DATA = "wallet_data"
        const val KEY_CONFIG_PREFIX = "widget_config_"
        const val KEY_INDEX_PREFIX = "widget_index_"
        const val KEY_BALANCE_VISIBLE_PREFIX = "widget_balance_visible_"

        // Deep link URI scheme
        const val URI_SCHEME = "sakurapi"
        const val URI_HOST = "action"

        private val rupiahFormat = DecimalFormat("#,###", DecimalFormatSymbols(Locale("id", "ID")))
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for widgetIds: ${appWidgetIds.joinToString()}")
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating widget $appWidgetId", e)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive action=${intent.action}")

        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            Log.w(TAG, "onReceive: INVALID_APPWIDGET_ID, ignoring")
            return
        }

        val prefs = HomeWidgetPlugin.getData(context)

        when (intent.action) {
            ACTION_PREV -> {
                val wallets = getConfiguredWallets(prefs, appWidgetId)
                if (wallets.isNotEmpty()) {
                    val current = prefs.getInt("${KEY_INDEX_PREFIX}$appWidgetId", 0)
                    val newIndex = if (current > 0) current - 1 else wallets.size - 1
                    Log.d(TAG, "ACTION_PREV: $current -> $newIndex (total=${wallets.size})")
                    prefs.edit().putInt("${KEY_INDEX_PREFIX}$appWidgetId", newIndex).apply()
                    val mgr = AppWidgetManager.getInstance(context)
                    updateAppWidget(context, mgr, appWidgetId)
                }
            }
            ACTION_NEXT -> {
                val wallets = getConfiguredWallets(prefs, appWidgetId)
                if (wallets.isNotEmpty()) {
                    val current = prefs.getInt("${KEY_INDEX_PREFIX}$appWidgetId", 0)
                    val newIndex = if (current < wallets.size - 1) current + 1 else 0
                    Log.d(TAG, "ACTION_NEXT: $current -> $newIndex (total=${wallets.size})")
                    prefs.edit().putInt("${KEY_INDEX_PREFIX}$appWidgetId", newIndex).apply()
                    val mgr = AppWidgetManager.getInstance(context)
                    updateAppWidget(context, mgr, appWidgetId)
                }
            }
            ACTION_TOGGLE_BALANCE -> {
                val key = "${KEY_BALANCE_VISIBLE_PREFIX}$appWidgetId"
                val visible = prefs.getBoolean(key, false)
                Log.d(TAG, "ACTION_TOGGLE_BALANCE: visible=$visible -> ${!visible}")
                prefs.edit().putBoolean(key, !visible).apply()
                val mgr = AppWidgetManager.getInstance(context)
                updateAppWidget(context, mgr, appWidgetId)
            }
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = HomeWidgetPlugin.getData(context)
        val editor = prefs.edit()
        for (id in appWidgetIds) {
            editor.remove("${KEY_CONFIG_PREFIX}$id")
            editor.remove("${KEY_INDEX_PREFIX}$id")
            editor.remove("${KEY_BALANCE_VISIBLE_PREFIX}$id")
        }
        editor.apply()
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "updateAppWidget id=$appWidgetId")
        try {
            val prefs = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_saku_rapi)

            // --- Data ---
            val wallets = getConfiguredWallets(prefs, appWidgetId)
            val currentIndex = prefs.getInt("${KEY_INDEX_PREFIX}$appWidgetId", 0)
                .coerceIn(0, (wallets.size - 1).coerceAtLeast(0))
            val isBalanceVisible = prefs.getBoolean(
                "${KEY_BALANCE_VISIBLE_PREFIX}$appWidgetId", false
            )

            Log.d(TAG, "wallets=${wallets.size}, index=$currentIndex, balanceVisible=$isBalanceVisible")

            // --- Wallet display ---
            if (wallets.isNotEmpty()) {
                val wallet = wallets[currentIndex]
                views.setTextViewText(R.id.tv_wallet_name, wallet.name)
                views.setTextViewText(
                    R.id.tv_wallet_balance,
                    if (isBalanceVisible) "Rp ${rupiahFormat.format(wallet.balance.toLong())}"
                    else "Rp •••••••"
                )
                views.setTextViewText(
                    R.id.tv_wallet_indicator,
                    "${currentIndex + 1} / ${wallets.size}"
                )
            } else {
                views.setTextViewText(R.id.tv_wallet_name, context.getString(R.string.widget_empty_wallets))
                views.setTextViewText(R.id.tv_wallet_balance, context.getString(R.string.widget_no_balance))
                views.setTextViewText(R.id.tv_wallet_indicator, "")
            }

            // --- Eye icon ---
            views.setImageViewResource(
                R.id.btn_toggle_balance,
                if (isBalanceVisible) R.drawable.ic_eye_on else R.drawable.ic_eye_off
            )

            // --- PendingIntents: Arrow navigation ---
            views.setOnClickPendingIntent(
                R.id.btn_prev,
                createSelfIntent(context, appWidgetId, ACTION_PREV)
            )
            views.setOnClickPendingIntent(
                R.id.btn_next,
                createSelfIntent(context, appWidgetId, ACTION_NEXT)
            )
            views.setOnClickPendingIntent(
                R.id.btn_toggle_balance,
                createSelfIntent(context, appWidgetId, ACTION_TOGGLE_BALANCE)
            )

            // --- PendingIntents: Quick actions ---
            val currentWalletId = if (wallets.isNotEmpty()) wallets[currentIndex].id else ""
            views.setOnClickPendingIntent(
                R.id.btn_manual,
                createDeepLinkIntent(context, "manual", currentWalletId)
            )
            views.setOnClickPendingIntent(
                R.id.btn_voice,
                createDeepLinkIntent(context, "speech", currentWalletId)
            )
            views.setOnClickPendingIntent(
                R.id.btn_camera,
                createDeepLinkIntent(context, "ocr", currentWalletId)
            )
            views.setOnClickPendingIntent(
                R.id.btn_text,
                createDeepLinkIntent(context, "text", currentWalletId)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId updated successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update widget $appWidgetId", e)
        }
    }

    /**
     * Buat PendingIntent yang broadcast kembali ke provider ini sendiri.
     */
    private fun createSelfIntent(
        context: Context,
        appWidgetId: Int,
        action: String
    ): PendingIntent {
        val intent = Intent(context, SakuRapiWidgetProvider::class.java).apply {
            this.action = action
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        return PendingIntent.getBroadcast(
            context,
            appWidgetId * 10 + action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * Buat PendingIntent deep link ke Flutter app via URI scheme.
     */
    private fun createDeepLinkIntent(
        context: Context,
        type: String,
        walletId: String
    ): PendingIntent {
        val uri = Uri.parse("$URI_SCHEME://$URI_HOST?type=$type&walletId=$walletId")
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage(context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            type.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * Parse wallet data JSON dan filter berdasarkan widget config.
     */
    private fun getConfiguredWallets(
        prefs: SharedPreferences,
        appWidgetId: Int
    ): List<WalletData> {
        val rawJson = prefs.getString(KEY_WALLET_DATA, null) ?: return emptyList()
        val configJson = prefs.getString("${KEY_CONFIG_PREFIX}$appWidgetId", null)

        return try {
            val allWallets = parseWallets(rawJson)
            if (configJson != null) {
                val selectedIds = parseStringList(configJson)
                allWallets.filter { it.id in selectedIds }
            } else {
                allWallets
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun parseWallets(json: String): List<WalletData> {
        val arr = JSONArray(json)
        val list = mutableListOf<WalletData>()
        for (i in 0 until arr.length()) {
            val obj = arr.getJSONObject(i)
            list.add(
                WalletData(
                    id = obj.getString("id"),
                    name = obj.getString("name"),
                    balance = obj.getDouble("balance")
                )
            )
        }
        return list
    }

    private fun parseStringList(json: String): Set<String> {
        val arr = JSONArray(json)
        val set = mutableSetOf<String>()
        for (i in 0 until arr.length()) {
            set.add(arr.getString(i))
        }
        return set
    }

    /** Lightweight wallet data class for widget display. */
    data class WalletData(val id: String, val name: String, val balance: Double)
}
