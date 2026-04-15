package app.saku_rapi.com.widget

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.Toast
import app.saku_rapi.com.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Configuration Activity for Saku Rapi Home Widget.
 *
 * Ditampilkan saat user menambahkan widget ke home screen.
 * User memilih wallet mana saja yang ingin ditampilkan di carousel.
 *
 * Edge case R4: Jika belum ada wallet data (user belum pernah buka app),
 * tampilkan empty state dengan instruksi untuk membuka app.
 */
class SakuRapiWidgetConfigActivity : Activity() {

    companion object {
        private const val TAG = "SakuRapiWidgetConfig"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    private data class WalletItem(val id: String, val name: String, val balance: Double)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Default: cancelled jika user menekan back
        setResult(RESULT_CANCELED)

        // Ambil appWidgetId dari intent
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            Log.w(TAG, "INVALID_APPWIDGET_ID, finishing")
            finish()
            return
        }

        Log.d(TAG, "Config activity opened for widgetId=$appWidgetId")
        setContentView(R.layout.activity_widget_config)

        val listView = findViewById<ListView>(R.id.lv_wallets)
        val emptyContainer = findViewById<View>(R.id.empty_state_container)
        val btnOpenApp = findViewById<Button>(R.id.btn_open_app)
        val btnSave = findViewById<Button>(R.id.btn_save)

        // Load wallet data dari SharedPreferences (dikirim oleh Flutter)
        val prefs = HomeWidgetPlugin.getData(this)
        val rawJson = prefs.getString(SakuRapiWidgetProvider.KEY_WALLET_DATA, null)
        val wallets = parseWallets(rawJson)
        Log.d(TAG, "Loaded ${wallets.size} wallets from SharedPreferences (rawJson=${rawJson?.take(100) ?: "null"})")

        if (wallets.isEmpty()) {
            // ── R4: Empty State ──
            Log.d(TAG, "No wallets found, showing empty state")
            emptyContainer.visibility = View.VISIBLE
            listView.visibility = View.GONE
            btnSave.visibility = View.GONE

            btnOpenApp.setOnClickListener {
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                if (launchIntent != null) {
                    startActivity(launchIntent)
                }
                finish()
            }
        } else {
            // ── Normal State: Wallet Selection ──
            emptyContainer.visibility = View.GONE
            listView.visibility = View.VISIBLE
            btnSave.visibility = View.VISIBLE

            listView.choiceMode = ListView.CHOICE_MODE_MULTIPLE
            val adapter = ArrayAdapter(
                this,
                android.R.layout.simple_list_item_multiple_choice,
                wallets.map { "${it.name}" }
            )
            listView.adapter = adapter

            // Pre-select semua wallet secara default
            for (i in wallets.indices) {
                listView.setItemChecked(i, true)
            }

            btnSave.setOnClickListener {
                val selectedIds = mutableListOf<String>()
                for (i in wallets.indices) {
                    if (listView.isItemChecked(i)) {
                        selectedIds.add(wallets[i].id)
                    }
                }

                if (selectedIds.isEmpty()) {
                    Toast.makeText(
                        this,
                        getString(R.string.widget_config_select_min),
                        Toast.LENGTH_SHORT
                    ).show()
                    return@setOnClickListener
                }

                Log.d(TAG, "Saving config: ${selectedIds.size} wallets selected: $selectedIds")

                // Simpan konfigurasi wallet terpilih
                val configKey = "${SakuRapiWidgetProvider.KEY_CONFIG_PREFIX}$appWidgetId"
                prefs.edit()
                    .putString(configKey, JSONArray(selectedIds).toString())
                    .apply()

                // Update widget
                val appWidgetManager = AppWidgetManager.getInstance(this)
                SakuRapiWidgetProvider().onUpdate(
                    this, appWidgetManager, intArrayOf(appWidgetId)
                )

                // Return success
                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                setResult(RESULT_OK, resultValue)
                finish()
            }
        }
    }

    private fun parseWallets(json: String?): List<WalletItem> {
        if (json.isNullOrBlank()) return emptyList()
        return try {
            val arr = JSONArray(json)
            val list = mutableListOf<WalletItem>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                list.add(
                    WalletItem(
                        id = obj.getString("id"),
                        name = obj.getString("name"),
                        balance = obj.getDouble("balance")
                    )
                )
            }
            list
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse wallet JSON", e)
            emptyList()
        }
    }
}
