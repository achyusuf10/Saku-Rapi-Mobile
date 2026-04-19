package app.saku_rapi.com.widget

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.CheckBox
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
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
class SakuRapiWidgetConfigActivity : AppCompatActivity() {

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

        val rvWallets = findViewById<RecyclerView>(R.id.rv_wallets)
        val emptyContainer = findViewById<View>(R.id.empty_state_container)
        val btnOpenApp = findViewById<Button>(R.id.btn_open_app)
        val btnSave = findViewById<Button>(R.id.btn_save)
        val bottomBar = findViewById<View>(R.id.bottom_bar)

        // Load wallet data dari SharedPreferences (dikirim oleh Flutter)
        val prefs = HomeWidgetPlugin.getData(this)
        val rawJson = prefs.getString(SakuRapiWidgetProvider.KEY_WALLET_DATA, null)
        val wallets = parseWallets(rawJson)
        Log.d(TAG, "Loaded ${wallets.size} wallets (rawJson=${rawJson?.take(100) ?: "null"})")

        if (wallets.isEmpty()) {
            // ── R4: Empty State ──
            Log.d(TAG, "No wallets found, showing empty state")
            emptyContainer.visibility = View.VISIBLE
            rvWallets.visibility = View.GONE
            bottomBar.visibility = View.GONE

            btnOpenApp.setOnClickListener {
                packageManager.getLaunchIntentForPackage(packageName)?.let { startActivity(it) }
                finish()
            }
        } else {
            // ── Normal State: Wallet Selection ──
            emptyContainer.visibility = View.GONE
            rvWallets.visibility = View.VISIBLE
            bottomBar.visibility = View.VISIBLE

            // Pre-select semua wallet secara default
            val selectedIds = wallets.map { it.id }.toMutableSet()
            val adapter = WalletConfigAdapter(wallets, selectedIds)

            rvWallets.layoutManager = LinearLayoutManager(this)
            rvWallets.adapter = adapter

            btnSave.setOnClickListener {
                if (selectedIds.isEmpty()) {
                    Toast.makeText(this, getString(R.string.widget_config_select_min), Toast.LENGTH_SHORT).show()
                    return@setOnClickListener
                }

                Log.d(TAG, "Saving config: ${selectedIds.size} wallets selected: $selectedIds")

                // Simpan konfigurasi wallet terpilih
                val configKey = "${SakuRapiWidgetProvider.KEY_CONFIG_PREFIX}$appWidgetId"
                prefs.edit()
                    .putString(configKey, JSONArray(selectedIds.toList()).toString())
                    .apply()

                // Update widget
                val appWidgetManager = AppWidgetManager.getInstance(this)
                SakuRapiWidgetProvider().onUpdate(this, appWidgetManager, intArrayOf(appWidgetId))

                // Return success
                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                setResult(RESULT_OK, resultValue)
                finish()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // RecyclerView Adapter
    // ─────────────────────────────────────────────────────────────

    private inner class WalletConfigAdapter(
        private val wallets: List<WalletItem>,
        private val selectedIds: MutableSet<String>,
    ) : RecyclerView.Adapter<WalletConfigAdapter.ViewHolder>() {

        inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val card: View = view.findViewById(R.id.card_wallet_item)
            val checkbox: CheckBox = view.findViewById(R.id.cb_wallet)
            val name: TextView = view.findViewById(R.id.tv_wallet_name)
            val balance: TextView = view.findViewById(R.id.tv_wallet_balance)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_wallet_config, parent, false)
            return ViewHolder(view)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val wallet = wallets[position]
            val isSelected = selectedIds.contains(wallet.id)

            holder.name.text = wallet.name
            holder.balance.text = formatBalance(wallet.balance)
            holder.checkbox.isChecked = isSelected
            holder.card.setBackgroundResource(
                if (isSelected) R.drawable.bg_config_item_selected
                else R.drawable.bg_config_item_unselected
            )

            holder.itemView.setOnClickListener {
                if (selectedIds.contains(wallet.id)) {
                    selectedIds.remove(wallet.id)
                } else {
                    selectedIds.add(wallet.id)
                }
                notifyItemChanged(position)
            }
        }

        override fun getItemCount(): Int = wallets.size

        private fun formatBalance(amount: Double): String {
            val formatted = String.format("%,.0f", amount).replace(",", ".")
            return "Rp $formatted"
        }
    }

    // ─────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────

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
                        balance = obj.getDouble("balance"),
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
