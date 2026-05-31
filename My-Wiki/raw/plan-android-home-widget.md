# Plan: Android Home Widget — SakuRapi

> **Status:** Draft v2.1 (Revised + Cold Start Fix)
> **Dibuat:** 2026-04-15
> **Direvisi:** 2026-04-15
> **Package:** `home_widget: ^0.9.1` (rilis 13 Apr 2026)
> **Approach:** XML RemoteViews (battle-tested) — bukan Glance

---

## 1. Ringkasan

Membangun **1 Android Home Widget** untuk SakuRapi yang terdiri dari:

| Bagian | Deskripsi |
|--------|-----------|
| **Wallet Display + Arrows** | Layout statis menampilkan 1 wallet aktif + tombol panah `<` `>` untuk navigasi (bukan swipe) |
| **Balance Privacy Toggle** | Icon mata untuk show/hide saldo — default: tersembunyi (`Rp •••••••`) |
| **Quick Actions** | 4 tombol: Manual, Voice, OCR, Text — masing-masing deep link ke app |
| **Configuration Activity** | Popup saat widget ditambahkan untuk memilih wallet + handle empty state |

### ⚠️ Revisi v2 — 4 Koreksi Krusial

| # | Masalah | Solusi |
|---|---------|--------|
| **R1** | `AdapterViewFlipper`/`StackView` tidak support horizontal swipe mulus | Ganti ke layout statis + arrow buttons `<` `>` via `PendingIntent` |
| **R2** | `Future.delayed` di deep link handler = race condition | State-based routing: `pendingWidgetActionProvider` (Riverpod) |
| **R3** | Saldo terbuka di home screen = celah privasi | Eye toggle, default hidden, state di SharedPreferences |
| **R4** | Config Activity crash jika SharedPreferences kosong | Empty state: "Buka app dulu" + tombol launch app |

> **Phase 2.5 — Cold Start Trap (tambahan dari audit):**
> `ref.listen` hanya fire pada **perubahan** state. Pada cold start, `initiallyLaunchedFromHomeWidget()` mengisi provider **sebelum** DashboardPage mount → listener tidak fire → user stuck.
> **Fix:** Dual-path di Dashboard: `ref.listen` (warm start) + `_coldStartHandled` flag + `addPostFrameCallback` initial check (cold start).

---

## 2. Analisis Arsitektur Saat Ini

### 2.1. Wallet Data Flow

```
WalletRemoteDataSource (Supabase) 
  → WalletRepository (orchestrator) 
    → WalletLocalDataSource (Hive cache, key: 'cached_wallets')
      → WalletController (StateNotifier)
        → UI (Dashboard, WalletPage)
```

**WalletModel fields yang relevan untuk widget:**
- `id` (String) — UUID
- `name` (String) — Nama wallet
- `balance` (double) — Saldo (read-only, via DB trigger)
- `icon` (String) — FontAwesome icon name
- `color` (String) — Hex color
- `excludeFromTotal` (bool)
- `sortOrder` (int)

**Hive cache:** `WalletLocalDataSource` menyimpan JSON string di encrypted Hive box dengan key `cached_wallets`.

### 2.2. Quick Actions Pattern (Dashboard)

File: `lib/features/dashboard/view/widgets/dashboard_quick_actions.dart`

4 aksi saat ini:
1. **Manual** → `context.push(AppRouter.transactionForm)`
2. **Voice** → `VoiceInputSheet.show()` → set `pendingVoicePrefillProvider` → push form
3. **OCR** → `OcrResultSheet.show()` → set `pendingOcrPrefillProvider` → push form
4. **Text** → `TextInputSheet.show()` → set `pendingVoicePrefillProvider` → push form

### 2.3. Router (GoRouter)

- File: `lib/core/router/app_router.dart`
- **Belum ada deep link / URI scheme handler**
- Key routes: `AppRouter.dashboard`, `AppRouter.transactionForm`, `AppRouter.wallet`
- Transaction form menerima `existingTransaction` via `state.extra`

### 2.4. Android Native

- Package: `app.sakurapi.com`
- Flavors: `dev` (suffix `.dev`) dan `prod`
- `MainActivity` extends `FlutterActivity` (singleTop launchMode)
- Build: Kotlin DSL (`build.gradle.kts`), Java 17, desugaring enabled
- Belum ada widget, receiver, atau intent filter khusus

### 2.5. Entry Points (main.dart)

```
bootstrap() → HiveService.instance() → Supabase.initialize() → SentryFlutter.init() → runApp(ProviderScope(child: SakuRapiApp()))
```

`SakuRapiApp` menggunakan `MaterialApp.router` dengan `routerProvider`.

---

## 3. Keputusan Teknis

### 3.1. Jetpack Glance vs XML RemoteViews

| Aspek | Jetpack Glance | XML RemoteViews |
|-------|----------------|-----------------|
| **Recommended by home_widget** | ✅ Ya (default docs) | Legacy support |
| **Horizontal navigation** | Tidak ada native horizontal pager | Static layout + arrow buttons (stabil) |
| **Configuration Activity** | Manual, perlu Compose Activity | Standard Android pattern |
| **Stabilitas** | Relatif baru, beberapa quirk | Battle-tested |

**Keputusan: Gunakan XML RemoteViews** untuk stabilitas maksimal.

**Alasan:**
1. ~~Carousel horizontal via `AdapterViewFlipper`~~ → **REVISI R1:** `RemoteViews` tidak support horizontal swipe mulus. Gunakan layout statis + tombol panah `<` `>`.
2. Glance belum memiliki native horizontal pager yang stabil untuk widget.
3. Configuration Activity lebih straightforward dengan XML approach.
4. `home_widget` 0.9.1 masih support XML via `HomeWidgetProvider`.
5. Prioritas user adalah **stabilitas** — XML RemoteViews sudah battle-tested.

### 3.2. Navigasi Wallet (REVISI R1)

**Pendekatan: Static Layout + Arrow Buttons**

Widget hanya menampilkan **1 wallet pada satu waktu**. User berpindah wallet via tombol panah.

```
┌──────────────────────────────────────────┐
│  [<]   BCA  ·  Rp •••••••   [👁]  [>]   │  ← Arrow nav + eye toggle
│──────────────────────────────────────────│
│  ✏️ Manual  🎤 Suara  📷 Struk  ⌨️ Teks │  ← 4 Quick Actions
└──────────────────────────────────────────┘
```

**State management (native side):**
- `widget_index_{appWidgetId}` → int, index wallet yang sedang ditampilkan (default: 0)
- Tombol `<` → `PendingIntent` broadcast: decrement index, wrap around
- Tombol `>` → `PendingIntent` broadcast: increment index, wrap around
- Provider `onReceive()` intercept custom action → update index → re-render widget

**Keuntungan vs flipper/swipe:**
- 100% reliable — `PendingIntent` + `BroadcastReceiver` adalah pola paling stabil di Android widgets
- Tidak bergantung pada gesture recognition yang unreliable di `RemoteViews`
- User punya kontrol eksplisit atas navigasi
- Implementasi lebih sederhana (tidak perlu `RemoteViewsService`)

### 3.3. Balance Privacy (REVISI R3)

**Default: saldo tersembunyi** → `Rp •••••••`

State management:
- Key: `widget_balance_visible_{appWidgetId}` → boolean (default: `false`)
- Icon mata: `PendingIntent` broadcast → toggle boolean → re-render widget
- Sinkronisasi dengan app: **TIDAK** — widget privacy state independen dari `DashboardController.isBalanceHidden`. Alasan: user mungkin ingin hide di home screen tapi show di dalam app.
- Di sisi native, cek flag → tampilkan `formatRupiah(amount)` atau `"Rp •••••••"`

### 3.4. Deep Link Strategy

**URI Scheme:** `sakurapi://`

| Action | URI |
|--------|-----|
| Manual Input | `sakurapi://action?type=manual&walletId={id}` |
| Voice Input | `sakurapi://action?type=speech&walletId={id}` |
| OCR Input | `sakurapi://action?type=ocr&walletId={id}` |
| Text Input | `sakurapi://action?type=text&walletId={id}` |

**`walletId`** = ID wallet yang **sedang ditampilkan** di widget (berdasarkan `widget_index_{appWidgetId}`). Opsional — jika tidak tersedia, gunakan wallet pertama dari konfigurasi.

### 3.5. Data Sync Strategy

```
Flutter App (wallet data berubah)
  → HomeWidgetSyncService.syncWalletData()
    → Filter wallet berdasarkan konfigurasi widget
    → Serialize ke JSON string
    → HomeWidget.saveWidgetData('wallet_data', jsonString)
    → HomeWidget.updateWidget(androidName: 'SakuRapiWidgetReceiver')
  → Android Widget onUpdate()
    → Baca SharedPreferences
    → Parse JSON → Update RemoteViews
```

### 3.6. Widget Configuration Persistence

Setiap widget instance memiliki `appWidgetId` unik dari Android.

```
Key: 'widget_config_{appWidgetId}'
Value: JSON array of selected wallet IDs → ["uuid1", "uuid2", "uuid3"]
```

Disimpan via `HomeWidget.saveWidgetData()` agar bisa diakses dari kedua sisi (Flutter & native).

---

## 4. Rencana File & Struktur

### 4.1. Sisi Flutter (Dart)

```
lib/
├── core/
│   └── services/
│       └── home_widget_service.dart          # [NEW] Utility class sinkronisasi data
├── features/
│   └── home_widget/                          # [NEW] Feature module
│       ├── home_widget_constants.dart         # [NEW] Konstanta (keys, widget name, URI scheme)
│       └── home_widget_deep_link_handler.dart # [NEW] Handler deep link + pendingWidgetActionProvider
```

**File yang di-modifikasi:**
```
lib/main.dart                                 # [MOD] Register deep link handler di bootstrap
lib/core/router/app_router.dart               # [MOD] (Opsional) redirect check untuk pending action
lib/features/wallet/controllers/wallet_controller.dart  # [MOD] Panggil sync setelah loadWallets
lib/features/dashboard/view/ui/dashboard_page.dart      # [MOD] Listen pendingWidgetActionProvider
```

### 4.2. Sisi Native Android (Kotlin + XML)

```
android/app/src/main/
├── kotlin/app/saku_rapi/com/
│   ├── MainActivity.kt                       # [EXISTING, minimal change]
│   ├── widget/                               # [NEW] Package untuk widget
│   │   ├── SakuRapiWidgetProvider.kt         # [NEW] AppWidgetProvider — onUpdate, onReceive (arrows, eye toggle)
│   │   ├── WidgetWallet.kt                   # [NEW] Data class for widget wallet
│   │   └── SakuRapiWidgetConfigActivity.kt   # [NEW] Configuration Activity (with empty state R4)
├── res/
│   ├── layout/
│   │   ├── widget_saku_rapi.xml              # [NEW] Layout utama: static wallet + arrows + eye + quick actions
│   │   └── activity_widget_config.xml        # [NEW] Layout Configuration Activity (with empty state)
│   ├── xml/
│   │   └── widget_saku_rapi_info.xml         # [NEW] AppWidgetProviderInfo metadata
│   ├── drawable/
│   │   ├── widget_background.xml             # [NEW] Rounded rect background
│   │   ├── widget_preview.png                # [NEW] Preview image untuk widget picker
│   │   ├── ic_arrow_left.xml                 # [NEW] Vector — arrow left (R1)
│   │   ├── ic_arrow_right.xml                # [NEW] Vector — arrow right (R1)
│   │   ├── ic_eye_on.xml                     # [NEW] Vector — eye visible (R3)
│   │   ├── ic_eye_off.xml                    # [NEW] Vector — eye hidden (R3)
│   │   ├── ic_empty_wallet.xml               # [NEW] Vector — empty state icon (R4)
│   │   ├── ic_widget_manual.xml              # [NEW] Vector icon — manual input
│   │   ├── ic_widget_voice.xml               # [NEW] Vector icon — voice input
│   │   ├── ic_widget_camera.xml              # [NEW] Vector icon — OCR/camera
│   │   └── ic_widget_text.xml               # [NEW] Vector icon — text input
│   └── values/
│       └── widget_colors.xml                 # [NEW] Widget-specific colors (match design system)
```

> **DIHAPUS dari v1 (R1):** `SakuRapiRemoteViewsFactory.kt`, `SakuRapiRemoteViewsService.kt`, `widget_wallet_item.xml`
> **Alasan:** Static layout + arrow buttons menghilangkan kebutuhan RemoteViewsService/Factory.

**AndroidManifest.xml** — perlu ditambahkan:
```xml
<!-- Widget Provider (handles arrow nav + eye toggle broadcasts) -->
<receiver android:name=".widget.SakuRapiWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        <action android:name="app.saku_rapi.ACTION_PREV" />
        <action android:name="app.saku_rapi.ACTION_NEXT" />
        <action android:name="app.saku_rapi.ACTION_TOGGLE_BALANCE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_saku_rapi_info" />
</receiver>

<!-- Configuration Activity (R4: includes empty state) -->
<activity android:name=".widget.SakuRapiWidgetConfigActivity"
    android:exported="true"
    android:theme="@style/Theme.AppCompat.DayNight.Dialog">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_CONFIGURE" />
    </intent-filter>
</activity>

<!-- Deep Link Intent Filter (di MainActivity) -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="sakurapi" />
</intent-filter>
```

### 4.3. Test Files

```
test/
├── features/
│   └── home_widget/
│       ├── home_widget_service_test.dart      # [NEW] Unit test sync data
│       ├── home_widget_deep_link_handler_test.dart  # [NEW] Unit test deep link parsing
│       └── home_widget_config_test.dart       # [NEW] Widget test config
```

---

## 5. Step-by-Step Implementasi

### Phase 1: Flutter — Package & Foundation

| # | Task | Detail |
|---|------|--------|
| 1.1 | Install `home_widget` | `fvm flutter pub add home_widget` (^0.9.1) |
| 1.2 | Buat `home_widget_constants.dart` | Definisikan semua konstanta: keys, widget name, URI scheme |
| 1.3 | Buat `home_widget_service.dart` | Utility class dengan method `syncWalletData(List<WalletModel> wallets)` |
| 1.4 | Integrasikan sync di `WalletController` | Panggil `HomeWidgetService.syncWalletData()` setelah `loadWallets()` berhasil |

**Detail `home_widget_service.dart`:**
```dart
class HomeWidgetService {
  /// Sync wallet data ke home widget (Android/iOS).
  /// Dipanggil setiap kali wallet data berubah (CRUD, adjustment, sync).
  static Future<void> syncWalletData(List<WalletModel> wallets) async {
    // 1. Serialize wallets ke JSON
    final walletsJson = wallets.map((w) => {
      'id': w.id,
      'name': w.name,
      'balance': w.balance,
      'icon': w.icon,
      'color': w.color,
      'excludeFromTotal': w.excludeFromTotal,
      'sortOrder': w.sortOrder,
    }).toList();
    
    // 2. Simpan via home_widget
    await HomeWidget.saveWidgetData<String>(
      HomeWidgetConstants.walletDataKey,
      jsonEncode(walletsJson),
    );
    
    // 3. Trigger update widget
    await HomeWidget.updateWidget(
      androidName: HomeWidgetConstants.androidWidgetName,
    );
  }
  
  /// Simpan konfigurasi wallet yang dipilih untuk widget tertentu.
  static Future<void> saveWidgetConfig(int appWidgetId, List<String> walletIds) async {
    await HomeWidget.saveWidgetData<String>(
      '${HomeWidgetConstants.configKeyPrefix}$appWidgetId',
      jsonEncode(walletIds),
    );
  }
  
  /// Ambil konfigurasi wallet yang dipilih.
  static Future<List<String>?> getWidgetConfig(int appWidgetId) async {
    final raw = await HomeWidget.getWidgetData<String>(
      '${HomeWidgetConstants.configKeyPrefix}$appWidgetId',
    );
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<String>();
  }
}
```

### Phase 2: Flutter — Deep Link Handler (REVISI R2)

| # | Task | Detail |
|---|------|--------|
| 2.1 | Buat `home_widget_deep_link_handler.dart` | Parse URI `sakurapi://action?type=X&walletId=Y` |
| 2.2 | Buat `pendingWidgetActionProvider` | Riverpod `StateProvider<Uri?>` untuk state-based routing |
| 2.3 | Modifikasi `app_router.dart` | Tambah redirect logic yang baca `pendingWidgetActionProvider` |
| 2.4 | Modifikasi `main.dart` / `bootstrap()` | Register `HomeWidget.widgetClicked` listener saat app init |
| 2.5 | Dashboard listener | Watch provider → execute navigation |

**REVISI R2: State-Based Routing (bukan `Future.delayed`)**

`Future.delayed` sebelum `context.push()` adalah bad practice → race conditions, timing-dependent bugs.

Pendekatan baru:
1. Widget URI masuk → disimpan ke `pendingWidgetActionProvider`
2. Dashboard page (atau GoRouter redirect) watches provider
3. Ketika provider berubah dari null → non-null, consume URI dan navigate

**Alur:**
```
Widget click → PendingIntent → sakurapi://action?type=X&walletId=Y
  → Flutter HomeWidget.widgetClicked stream
  → Set pendingWidgetActionProvider = Uri
  → GoRouter redirect / Dashboard listener
  → if (pendingAction != null) → consume & navigate
```

**Detail Provider & Handler:**
```dart
// lib/features/home_widget/home_widget_deep_link_handler.dart

/// Pending action dari home widget — diisi saat URI diterima,
/// dikonsumsi oleh dashboard listener untuk navigasi.
final pendingWidgetActionProvider = StateProvider<Uri?>((ref) => null);

class HomeWidgetDeepLinkHandler {
  /// Parse URI dan set ke provider. TIDAK langsung navigate.
  static void receiveUri(WidgetRef ref, Uri? uri) {
    if (uri == null || uri.scheme != 'sakurapi') return;
    ref.read(pendingWidgetActionProvider.notifier).state = uri;
  }

  /// Consume pending action dan lakukan navigasi.
  /// Dipanggil dari Dashboard listener setelah dashboard fully mounted.
  static void consumeAction(WidgetRef ref, BuildContext context) {
    final uri = ref.read(pendingWidgetActionProvider);
    if (uri == null) return;
    
    // Consume — set null agar tidak re-trigger
    ref.read(pendingWidgetActionProvider.notifier).state = null;
    
    final type = uri.queryParameters['type'];
    final walletId = uri.queryParameters['walletId'];
    
    switch (type) {
      case 'manual':
        // Push transaction form dengan initial wallet
        context.push(AppRouter.transactionForm, extra: {
          'walletId': walletId,
        });
        break;
      case 'speech':
        // Buka VoiceInputSheet
        _handleVoiceInput(context, ref, walletId);
        break;
      case 'ocr':
        // Buka OcrResultSheet
        _handleOcrInput(context, ref, walletId);
        break;
      case 'text':
        // Buka TextInputSheet
        _handleTextInput(context, ref, walletId);
        break;
    }
  }

  static Future<void> _handleVoiceInput(
    BuildContext context, WidgetRef ref, String? walletId,
  ) async {
    final result = await VoiceInputSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingVoicePrefillProvider.notifier).state = result;
      context.push(AppRouter.transactionForm, extra: {
        'walletId': walletId,
      });
    }
  }

  static Future<void> _handleOcrInput(
    BuildContext context, WidgetRef ref, String? walletId,
  ) async {
    final result = await OcrResultSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingOcrPrefillProvider.notifier).state = result;
      context.push(AppRouter.transactionForm, extra: {
        'walletId': walletId,
      });
    }
  }

  static Future<void> _handleTextInput(
    BuildContext context, WidgetRef ref, String? walletId,
  ) async {
    final result = await TextInputSheet.show(context: context);
    if (result != null && context.mounted) {
      ref.read(pendingVoicePrefillProvider.notifier).state = result;
      context.push(AppRouter.transactionForm, extra: {
        'walletId': walletId,
      });
    }
  }
}
```

**Dashboard listener (di `DashboardPage`):**

> ⚠️ **Cold Start Trap (Phase 2.5):**
> `ref.listen` hanya fire pada **perubahan** state. Pada cold start,
> `initiallyLaunchedFromHomeWidget()` sudah mengisi provider **sebelum**
> DashboardPage di-render. Artinya state sudah non-null saat listener
> terdaftar — tidak ada perubahan → listener tidak fire → user stuck.
>
> **Fix:** Selain `ref.listen`, jalankan juga **initial check** di
> `addPostFrameCallback` saat build pertama. Gunakan `_coldStartHandled`
> flag agar hanya dieksekusi sekali.

```dart
/// Gunakan StatefulHookConsumerWidget atau ConsumerStatefulWidget
/// agar punya initState/didChangeDependencies untuk cold start check.

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _coldStartHandled = false;

  @override
  Widget build(BuildContext context) {
    // 1. Listen untuk WARM START (app sudah jalan, widget di-tap)
    //    Ini menangkap perubahan state: null → URI
    ref.listen<Uri?>(pendingWidgetActionProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            HomeWidgetDeepLinkHandler.consumeAction(ref, context);
          }
        });
      }
    });

    // 2. Handle COLD START — state sudah terisi sebelum listener aktif
    //    Hanya dijalankan sekali pada build pertama.
    if (!_coldStartHandled) {
      _coldStartHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // consumeAction() sudah null-safe — jika tidak ada pending action,
          // langsung return tanpa efek samping.
          HomeWidgetDeepLinkHandler.consumeAction(ref, context);
        }
      });
    }

    // ... rest of dashboard build
  }
}
```

**Integrasi di `main.dart`:**
```dart
// Di bootstrap(), setelah app siap:
HomeWidget.setAppGroupId('group.app.sakurapi.com'); // iOS only, tapi good practice
HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);

// Di SakuRapiApp widget, setup listener (butuh ProviderScope ref):
void _initHomeWidgetListeners(WidgetRef ref) {
  // Handle launch dari widget (app was terminated)
  HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
    HomeWidgetDeepLinkHandler.receiveUri(ref, uri);
  });
  
  // Handle click saat app sudah berjalan (background → foreground)
  HomeWidget.widgetClicked.listen((uri) {
    HomeWidgetDeepLinkHandler.receiveUri(ref, uri);
  });
}
```

### Phase 3: Native Android — Widget Provider & Layout (REVISI R1 + R3)

| # | Task | Detail |
|---|------|--------|
| 3.1 | Buat `widget_saku_rapi_info.xml` | Widget metadata (size, preview, configure activity, resize mode) |
| 3.2 | Buat `widget_saku_rapi.xml` layout | Layout utama: Static wallet display + arrow buttons + eye toggle + 4 quick actions |
| 3.3 | Buat icon drawables | Arrow left/right, eye/eye-slash, 4 quick action icons |
| 3.4 | Buat `widget_colors.xml` | Warna widget sesuai design system |
| 3.5 | Buat `SakuRapiWidgetProvider.kt` | `AppWidgetProvider` — arrow nav, privacy toggle, onUpdate, onReceive |
| 3.6 | Register di `AndroidManifest.xml` | Receiver dan intent filter |

> **PENTING (R1):** TIDAK ada `RemoteViewsService` / `RemoteViewsFactory` — layout fully static, navigasi via arrow buttons.

**Detail `widget_saku_rapi_info.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="130dp"
    android:targetCellWidth="4"
    android:targetCellHeight="2"
    android:updatePeriodMillis="3600000"
    android:initialLayout="@layout/widget_saku_rapi"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:configure="app.sakurapi.com.widget.SakuRapiWidgetConfigActivity"
    android:previewImage="@drawable/widget_preview"
    android:description="@string/widget_description" />
```

**Detail Layout `widget_saku_rapi.xml` (REVISI R1 + R3):**
```xml
<!-- Root: LinearLayout vertical, rounded corners background -->
<LinearLayout 
    android:orientation="vertical"
    android:background="@drawable/widget_background"
    android:padding="12dp">
  
  <!-- Top Row: Arrow Nav + Wallet Display + Eye Toggle -->
  <LinearLayout 
      android:orientation="horizontal"
      android:gravity="center_vertical">
    
    <!-- Arrow Left -->
    <ImageButton
        android:id="@+id/btn_prev"
        android:src="@drawable/ic_arrow_left"
        android:background="?android:attr/selectableItemBackgroundBorderless"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:contentDescription="Previous wallet" />
    
    <!-- Wallet Info (Center, weight=1) -->
    <LinearLayout
        android:orientation="vertical"
        android:layout_weight="1"
        android:gravity="center">
      
      <TextView
          android:id="@+id/tv_wallet_name"
          android:textSize="12sp"
          android:textColor="@color/widget_text_secondary"
          android:text="BCA"
          android:maxLines="1"
          android:ellipsize="end" />
      
      <TextView
          android:id="@+id/tv_wallet_balance"
          android:textSize="18sp"
          android:textStyle="bold"
          android:textColor="@color/widget_text_primary"
          android:text="Rp •••••••"
          android:maxLines="1" />
      
      <!-- Wallet page indicator: "2 / 5" -->
      <TextView
          android:id="@+id/tv_wallet_indicator"
          android:textSize="10sp"
          android:textColor="@color/widget_text_tertiary"
          android:text="1 / 3" />
    
    </LinearLayout>
    
    <!-- Eye Toggle (R3) -->
    <ImageButton
        android:id="@+id/btn_toggle_balance"
        android:src="@drawable/ic_eye_off"
        android:background="?android:attr/selectableItemBackgroundBorderless"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:contentDescription="Toggle balance visibility" />
    
    <!-- Arrow Right -->
    <ImageButton
        android:id="@+id/btn_next"
        android:src="@drawable/ic_arrow_right"
        android:background="?android:attr/selectableItemBackgroundBorderless"
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:contentDescription="Next wallet" />
    
  </LinearLayout>
  
  <!-- Divider -->
  <View
      android:layout_width="match_parent"
      android:layout_height="1dp"
      android:layout_marginVertical="8dp"
      android:background="@color/widget_border" />
  
  <!-- Bottom: 4 Quick Action Buttons (equal weight) -->
  <LinearLayout 
      android:orientation="horizontal"
      android:gravity="center">
    <ImageButton android:id="@+id/btn_manual"  android:src="@drawable/ic_widget_manual" />
    <ImageButton android:id="@+id/btn_voice"   android:src="@drawable/ic_widget_voice" />
    <ImageButton android:id="@+id/btn_camera"  android:src="@drawable/ic_widget_camera" />
    <ImageButton android:id="@+id/btn_text"    android:src="@drawable/ic_widget_text" />
  </LinearLayout>
  
</LinearLayout>
```

**Detail `SakuRapiWidgetProvider.kt` (REVISI R1 + R3):**
```kotlin
class SakuRapiWidgetProvider : HomeWidgetProvider() {
    
    companion object {
        const val ACTION_PREV = "app.saku_rapi.ACTION_PREV"
        const val ACTION_NEXT = "app.saku_rapi.ACTION_NEXT"
        const val ACTION_TOGGLE_BALANCE = "app.saku_rapi.ACTION_TOGGLE_BALANCE"
        const val EXTRA_WIDGET_ID = "extra_widget_id"
    }
    
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, 
                          appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { appWidgetId ->
            updateWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        val appWidgetId = intent.getIntExtra(EXTRA_WIDGET_ID, 
            AppWidgetManager.INVALID_APPWIDGET_ID)
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
        
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        
        when (intent.action) {
            ACTION_PREV, ACTION_NEXT -> {
                // R1: Navigasi arrow — update index
                val wallets = getConfiguredWallets(prefs, appWidgetId)
                if (wallets.isEmpty()) return
                
                val indexKey = "widget_index_$appWidgetId"
                var currentIndex = prefs.getInt(indexKey, 0)
                
                currentIndex = if (intent.action == ACTION_NEXT) {
                    (currentIndex + 1) % wallets.size  // wrap forward
                } else {
                    (currentIndex - 1 + wallets.size) % wallets.size  // wrap backward
                }
                
                prefs.edit().putInt(indexKey, currentIndex).apply()
                
                // Re-render widget
                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateWidget(context, appWidgetManager, appWidgetId, prefs)
            }
            
            ACTION_TOGGLE_BALANCE -> {
                // R3: Toggle saldo visibility
                val visKey = "widget_balance_visible_$appWidgetId"
                val isVisible = prefs.getBoolean(visKey, false) // default: hidden
                prefs.edit().putBoolean(visKey, !isVisible).apply()
                
                // Re-render widget
                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateWidget(context, appWidgetManager, appWidgetId, prefs)
            }
        }
    }
    
    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager,
                             appWidgetId: Int, prefs: SharedPreferences) {
        val views = RemoteViews(context.packageName, R.layout.widget_saku_rapi)
        
        // 1. Ambil wallet data & config
        val allWallets = parseWalletData(prefs)
        val configuredIds = getConfiguredWalletIds(prefs, appWidgetId)
        val wallets = allWallets.filter { it.id in configuredIds }
        
        if (wallets.isEmpty()) {
            views.setTextViewText(R.id.tv_wallet_name, "Belum ada dompet")
            views.setTextViewText(R.id.tv_wallet_balance, "—")
            views.setTextViewText(R.id.tv_wallet_indicator, "")
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }
        
        // 2. R1: Ambil current index (wrap-safe)
        val indexKey = "widget_index_$appWidgetId"
        val currentIndex = prefs.getInt(indexKey, 0).coerceIn(0, wallets.size - 1)
        val currentWallet = wallets[currentIndex]
        
        // 3. R3: Balance privacy
        val visKey = "widget_balance_visible_$appWidgetId"
        val isBalanceVisible = prefs.getBoolean(visKey, false) // default: hidden!
        
        views.setTextViewText(R.id.tv_wallet_name, currentWallet.name)
        views.setTextViewText(R.id.tv_wallet_balance,
            if (isBalanceVisible) formatRupiah(currentWallet.balance)
            else "Rp •••••••"
        )
        views.setTextViewText(R.id.tv_wallet_indicator, 
            "${currentIndex + 1} / ${wallets.size}")
        
        // Eye icon: show different icon based on state
        views.setImageViewResource(R.id.btn_toggle_balance,
            if (isBalanceVisible) R.drawable.ic_eye_on else R.drawable.ic_eye_off
        )
        
        // 4. Setup PendingIntents — arrows
        views.setOnClickPendingIntent(R.id.btn_prev,
            createActionIntent(context, appWidgetId, ACTION_PREV))
        views.setOnClickPendingIntent(R.id.btn_next,
            createActionIntent(context, appWidgetId, ACTION_NEXT))
        
        // 5. Setup PendingIntent — eye toggle
        views.setOnClickPendingIntent(R.id.btn_toggle_balance,
            createActionIntent(context, appWidgetId, ACTION_TOGGLE_BALANCE))
        
        // 6. Quick Actions — deep link with CURRENT wallet ID
        setupQuickAction(context, views, R.id.btn_manual, "manual", currentWallet.id)
        setupQuickAction(context, views, R.id.btn_voice, "speech", currentWallet.id)
        setupQuickAction(context, views, R.id.btn_camera, "ocr", currentWallet.id)
        setupQuickAction(context, views, R.id.btn_text, "text", currentWallet.id)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun createActionIntent(context: Context, appWidgetId: Int, action: String): PendingIntent {
        val intent = Intent(context, SakuRapiWidgetProvider::class.java).apply {
            this.action = action
            putExtra(EXTRA_WIDGET_ID, appWidgetId)
        }
        return PendingIntent.getBroadcast(
            context, 
            "$action$appWidgetId".hashCode(),  // unique request code
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
    
    private fun setupQuickAction(context: Context, views: RemoteViews, 
                                  viewId: Int, type: String, walletId: String) {
        val uri = Uri.parse("sakurapi://action?type=$type&walletId=$walletId")
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setClassName(context.packageName, "app.sakurapi.com.MainActivity")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, "$type$walletId".hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pendingIntent)
    }
    
    // Helper: parse wallet_data JSON from SharedPreferences
    private fun parseWalletData(prefs: SharedPreferences): List<WidgetWallet> { /* ... */ }
    private fun getConfiguredWalletIds(prefs: SharedPreferences, appWidgetId: Int): Set<String> { /* ... */ }
    private fun getConfiguredWallets(prefs: SharedPreferences, appWidgetId: Int): List<WidgetWallet> { /* ... */ }
    private fun formatRupiah(amount: Double): String { /* ... */ }
}

// Simple data class for widget use
data class WidgetWallet(val id: String, val name: String, val balance: Double)
```

### Phase 4: Native Android — Configuration Activity (REVISI R4)

| # | Task | Detail |
|---|------|--------|
| 4.1 | Buat `activity_widget_config.xml` | Layout: RecyclerView + checkbox per wallet + empty state view |
| 4.2 | Buat `SakuRapiWidgetConfigActivity.kt` | Activity — baca wallet data, handle empty state, simpan seleksi |
| 4.3 | Handle RESULT_OK / RESULT_CANCELED | Confirm → simpan → trigger update → finish. Cancel → finish tanpa widget |

**Detail Layout `activity_widget_config.xml` (REVISI R4):**
```xml
<!-- Root -->
<LinearLayout
    android:orientation="vertical"
    android:padding="24dp">
  
  <!-- Title -->
  <TextView
      android:text="Pilih Dompet"
      android:textSize="20sp"
      android:textStyle="bold" />
  
  <!-- Normal State: Wallet List -->
  <RecyclerView
      android:id="@+id/rv_wallets"
      android:visibility="gone" />
  
  <!-- Empty State (R4) -->
  <LinearLayout
      android:id="@+id/empty_state_container"
      android:orientation="vertical"
      android:gravity="center"
      android:visibility="visible">
    
    <ImageView
        android:src="@drawable/ic_empty_wallet"
        android:layout_width="80dp"
        android:layout_height="80dp" />
    
    <TextView
        android:id="@+id/tv_empty_message"
        android:text="Silakan buka aplikasi Saku Rapi terlebih dahulu untuk memuat data dompet."
        android:textSize="14sp"
        android:gravity="center"
        android:layout_marginTop="16dp" />
    
    <Button
        android:id="@+id/btn_open_app"
        android:text="Buka Saku Rapi"
        android:layout_marginTop="12dp" />
  
  </LinearLayout>
  
  <!-- Save Button (only visible when wallets exist) -->
  <Button
      android:id="@+id/btn_save"
      android:text="Simpan"
      android:visibility="gone"
      android:layout_marginTop="16dp" />
  
</LinearLayout>
```

**Detail `SakuRapiWidgetConfigActivity.kt` (REVISI R4):**
```kotlin
class SakuRapiWidgetConfigActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val selectedWalletIds = mutableListOf<String>()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set result CANCELED dulu — kalau user back tanpa confirm
        setResult(RESULT_CANCELED)
        
        // Ambil appWidgetId
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        
        setContentView(R.layout.activity_widget_config)
        
        // Baca wallet data dari SharedPreferences (disimpan oleh home_widget)
        val prefs = getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
        val walletJson = prefs.getString("wallet_data", null)
        
        // === R4: Empty State Check ===
        if (walletJson.isNullOrEmpty()) {
            showEmptyState()
            return
        }
        
        val wallets = try {
            parseWalletList(walletJson)
        } catch (e: Exception) {
            showEmptyState()
            return
        }
        
        if (wallets.isEmpty()) {
            showEmptyState()
            return
        }
        
        // Normal flow: tampilkan wallet list
        showWalletList(wallets)
    }
    
    // R4: Tampilkan empty state
    private fun showEmptyState() {
        findViewById<View>(R.id.rv_wallets).visibility = View.GONE
        findViewById<View>(R.id.btn_save).visibility = View.GONE
        findViewById<View>(R.id.empty_state_container).visibility = View.VISIBLE
        
        // Button untuk buka app
        findViewById<Button>(R.id.btn_open_app).setOnClickListener {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                startActivity(launchIntent)
            }
            // Finish config activity — user harus add widget lagi setelah buka app
            finish()
        }
    }
    
    // Normal: tampilkan wallet list dengan checkbox
    private fun showWalletList(wallets: List<WidgetWallet>) {
        findViewById<View>(R.id.empty_state_container).visibility = View.GONE
        findViewById<View>(R.id.rv_wallets).visibility = View.VISIBLE
        findViewById<View>(R.id.btn_save).visibility = View.VISIBLE
        
        // Setup RecyclerView/ListView dengan wallet items + checkbox
        // ... adapter setup ...
        
        // Button "Simpan" → simpan config dan trigger update
        findViewById<Button>(R.id.btn_save).setOnClickListener {
            if (selectedWalletIds.isEmpty()) {
                // Tampilkan toast: "Pilih minimal 1 dompet"
                return@setOnClickListener
            }
            saveConfigAndFinish()
        }
    }
    
    private fun saveConfigAndFinish() {
        // Simpan selected wallet IDs ke SharedPreferences
        val prefs = getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
        val selectedIds = JSONArray(selectedWalletIds)
        prefs.edit().putString("widget_config_$appWidgetId", selectedIds.toString()).apply()
        
        // Reset index ke 0 untuk widget baru
        prefs.edit().putInt("widget_index_$appWidgetId", 0).apply()
        
        // Trigger widget update
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val provider = ComponentName(this, SakuRapiWidgetProvider::class.java)
        val ids = appWidgetManager.getAppWidgetIds(provider)
        
        val updateIntent = Intent(this, SakuRapiWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        sendBroadcast(updateIntent)
        
        // Return OK
        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
    
    private fun parseWalletList(json: String): List<WidgetWallet> { /* ... */ }
}
```

### Phase 5: Integrasi & Polish

| # | Task | Detail |
|---|------|--------|
| 5.1 | Tambah deep link intent filter di `AndroidManifest.xml` | Scheme `sakurapi://` di `MainActivity` |
| 5.2 | Handle URI di Flutter app startup | `HomeWidget.initiallyLaunchedFromHomeWidget()` + stream |
| 5.3 | Modifikasi `TransactionFormPage` | Accept initial walletId dari deep link (via provider atau query param) |
| 5.4 | Sinkronisasi otomatis saat app dibuka | `WalletController.loadWallets()` → trigger `HomeWidgetService.syncWalletData()` |
| 5.5 | Handle edge cases | No wallets, user not logged in, empty config |

### Phase 6: Testing

| # | Task | Detail |
|---|------|--------|
| 6.1 | Unit test `HomeWidgetService` | Test serialization, config save/load, sync trigger |
| 6.2 | Unit test `HomeWidgetDeepLinkHandler` | Test URI parsing untuk semua 4 tipe + edge cases |
| 6.3 | Widget test routing | Test bahwa deep link handler navigates ke halaman yang benar |
| 6.4 | Manual testing | Test widget di emulator Android 12+ (API 31+) |

---

## 6. Data Flow Diagrams

### 6.1. Sync Flow (Flutter → Widget)

```
┌────────────────────────┐
│   WalletController     │
│   loadWallets() OK     │
│   createWallet() OK    │
│   updateWallet() OK    │
│   deleteWallet() OK    │
│   adjustBalance() OK   │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│  HomeWidgetService     │
│  .syncWalletData()     │
│                        │
│  1. Serialize wallets  │
│     → JSON string      │
│  2. saveWidgetData()   │
│     → SharedPreferences│
│  3. updateWidget()     │
│     → Broadcast        │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│  Android Native        │
│  SakuRapiWidgetProvider│
│  .onUpdate()           │
│                        │
│  1. Read SharedPrefs   │
│  2. Parse wallet JSON  │
│  3. Filter by config   │
│  4. Build RemoteViews  │
│  5. Show wallet[index]  │
│  6. Handle arrow nav    │
│  7. Handle eye toggle   │
└────────────────────────┘
```

### 6.2. Deep Link Flow — REVISI R2 (State-Based)

```
┌─────────────────────────┐
│  Home Widget             │
│  User taps Quick Action  │
└──────────┬──────────────┘
           │ PendingIntent
           ▼
┌─────────────────────────┐
│  Android OS              │
│  Intent: ACTION_VIEW     │
│  URI: sakurapi://action  │
│       ?type=manual       │
│       &walletId=abc123   │
└──────────┬──────────────┘
           │ Launch/Resume
           ▼
┌─────────────────────────┐
│  MainActivity (Flutter)  │
│  singleTop launchMode    │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  HomeWidget.widgetClicked│
│  or initiallyLaunched    │
│  stream                  │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────────────┐
│  pendingWidgetActionProvider    │
│  StateProvider<Uri?>            │
│  state = URI                    │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  DashboardPage                      │
│                                     │
│  PATH A: Warm Start (app running)   │
│  → ref.listen fires on change       │
│  → addPostFrameCallback             │
│  → consumeAction()                  │
│                                     │
│  PATH B: Cold Start (app killed)    │  ⚠️ Phase 2.5 fix
│  → state already set before mount   │
│  → ref.listen does NOT fire         │
│  → _coldStartHandled flag + initial │
│    addPostFrameCallback reads       │
│    existing state → consumeAction() │
│                                     │
│  consumeAction():                   │
│  3. Based on type:              │
│     manual → push form(walletId)│
│     speech → show VoiceSheet    │
│     ocr → show OcrSheet         │
│     text → show TextSheet       │
└─────────────────────────────────┘
```

### 6.3. Configuration Flow (REVISI R4)

```
┌────────────────────────┐
│  User adds widget       │
│  to home screen         │
└──────────┬─────────────┘
           │ Android triggers
           ▼
┌────────────────────────┐
│  SakuRapiWidgetConfig  │
│  Activity              │
│                        │
│  1. Read wallet_data   │
│     from SharedPrefs   │
│                        │
│  ┌─ IF EMPTY (R4) ──┐ │
│  │ Show empty state  │ │
│  │ "Buka app dulu"   │ │
│  │ [Buka Saku Rapi]  │ │
│  │ → launch app      │ │
│  │ → finish activity │ │
│  └───────────────────┘ │
│                        │
│  ┌─ IF HAS DATA ────┐ │
│  │ Show wallet list  │ │
│  │ with checkboxes   │ │
│  │ User selects      │ │
│  │ Save config       │ │
│  │ Set index = 0     │ │
│  │ Trigger update    │ │
│  │ RESULT_OK         │ │
│  └───────────────────┘ │
└────────────────────────┘
```

### 6.4. Arrow Navigation Flow (R1)

```
User taps [>] on widget
  → PendingIntent broadcast: ACTION_NEXT + appWidgetId
  → SakuRapiWidgetProvider.onReceive()
  → Read widget_index_{id} from SharedPrefs (e.g., 0)
  → Increment: (0 + 1) % wallets.size = 1
  → Save new index to SharedPrefs
  → Re-render widget with wallet[1]
  → Quick Action PendingIntents updated with wallet[1].id

User taps [<] on widget
  → Same but decrement: (0 - 1 + size) % size = last
```

### 6.5. Balance Privacy Flow (R3)

```
User taps [👁] on widget (default: hidden)
  → PendingIntent broadcast: ACTION_TOGGLE_BALANCE + appWidgetId
  → SakuRapiWidgetProvider.onReceive()
  → Read widget_balance_visible_{id} (default: false)
  → Toggle: false → true
  → Save to SharedPrefs
  → Re-render: "Rp •••••••" → "Rp 1.500.000"
  → Eye icon: ic_eye_off → ic_eye_on
```

---

## 7. Catatan Penting & Edge Cases

### 7.1. SharedPreferences Name

`home_widget` package di Android menggunakan `SharedPreferences` dengan nama **`HomeWidgetPreferences`** secara default. Pastikan:
- Flutter side: gunakan `HomeWidget.saveWidgetData()` (otomatis pakai nama yang benar)
- Native side: `getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)`

### 7.2. Product Flavors

Widget perlu di-register di manifest yang dibagikan kedua flavor (`src/main/`). Application ID berbeda per flavor:
- Dev: `app.sakurapi.com.dev`
- Prod: `app.sakurapi.com`

`qualifiedAndroidName` di `HomeWidget.updateWidget()` harus menyesuaikan. Atau gunakan `androidName` saja (class name tanpa package) karena home_widget akan resolve otomatis.

### 7.3. User Not Logged In

Jika widget ditap tapi user belum login → app akan membuka splash → login flow. Setelah login, deep link action bisa di-queue dan di-execute setelah auth berhasil. Perlu dipikirkan:
- Simpan pending deep link URI
- Setelah auth success → check pending URI → execute

### 7.4. Empty Wallet Data

Jika belum ada data wallet (user baru atau cache kosong):
- Widget menampilkan placeholder "Belum ada wallet"
- Quick actions tetap berfungsi (buka app ke dashboard)

### 7.5. Localization

Widget text (nama label quick action) sebaiknya di-hardcode di XML strings resource karena Android widget tidak bisa akses Flutter l10n. Gunakan `res/values/strings.xml` dan `res/values-id/strings.xml`.

### 7.6. Currency Format

Di sisi native, saldo harus diformat ke Rupiah. Buat helper Kotlin sederhana:
```kotlin
fun formatRupiah(amount: Double): String {
    val format = NumberFormat.getCurrencyInstance(Locale("id", "ID"))
    format.maximumFractionDigits = 0
    return format.format(amount)
}
```

### 7.7. Widget Update Frequency

- `updatePeriodMillis` di widget info XML: set 3600000 (1 jam) sebagai fallback
- Update utama via `HomeWidget.updateWidget()` dari Flutter (real-time saat data berubah)
- Pertimbangkan `WorkManager` untuk periodic sync jika app tidak aktif

### 7.8. ProGuard / R8

Pastikan widget-related classes tidak di-obfuscate. Tambahkan rules di `proguard-rules.pro`:
```
-keep class app.sakurapi.com.widget.** { *; }
```

---

## 8. Dependencies yang Ditambahkan

### Flutter (pubspec.yaml)
```yaml
dependencies:
  home_widget: ^0.9.1
```

### Android (build.gradle.kts)
Tidak perlu dependency tambahan — `home_widget` plugin sudah handle native dependencies. Untuk Configuration Activity, kita pakai standard Android SDK (Activity, RecyclerView dari AndroidX yang sudah ada).

---

## 9. Todo List (Execution Order) — REVISED v2

| ID | Task | Depends On | Status |
|----|------|-----------|--------|
| `hw-install` | Install `home_widget` ^0.9.1 | — | pending |
| `hw-constants` | Buat `home_widget_constants.dart` | hw-install | pending |
| `hw-service` | Buat `HomeWidgetService` (sync utility) | hw-constants | pending |
| `hw-deeplink-handler` | Buat `HomeWidgetDeepLinkHandler` + `pendingWidgetActionProvider` | hw-constants | pending |
| `hw-integrate-controller` | Integrasikan sync di WalletController | hw-service | pending |
| `hw-integrate-dashboard` | **[R2]** Tambah listener `pendingWidgetActionProvider` di Dashboard | hw-deeplink-handler | pending |
| `hw-integrate-main` | Register handler di bootstrap/main | hw-deeplink-handler | pending |
| `hw-android-xml-info` | Buat `widget_saku_rapi_info.xml` | hw-install | pending |
| `hw-android-layout` | **[R1+R3]** Buat layout XML (static wallet + arrows + eye toggle + quick actions) | hw-android-xml-info | pending |
| `hw-android-icons` | Buat vector drawable icons (quick actions + arrows + eye + empty state) | — | pending |
| `hw-android-colors` | Buat `widget_colors.xml` (match design system) | — | pending |
| `hw-android-provider` | **[R1+R3]** Buat `SakuRapiWidgetProvider.kt` (arrows, eye toggle, quick actions) | hw-android-layout | pending |
| `hw-android-config` | **[R4]** Buat `SakuRapiWidgetConfigActivity.kt` (with empty state) | hw-android-layout | pending |
| `hw-android-manifest` | Update `AndroidManifest.xml` (receiver + custom actions, config, deep link) | hw-android-provider, hw-android-config | pending |
| `hw-android-proguard` | Update `proguard-rules.pro` | hw-android-provider | pending |
| `hw-test-service` | Unit test HomeWidgetService | hw-service | pending |
| `hw-test-deeplink` | Unit test DeepLinkHandler + provider logic | hw-deeplink-handler | pending |
| `hw-test-routing` | Widget test routing integration | hw-integrate-dashboard | pending |
| `hw-manual-test` | Manual testing di emulator API 31+ | ALL | pending |

> **DIHAPUS dari v1:** `hw-android-service` (RemoteViewsService/Factory) — tidak lagi diperlukan (R1)
> **DITAMBAH:** `hw-integrate-dashboard` (listener di Dashboard untuk state-based routing, R2)
> **DIUBAH:** `hw-integrate-router` → `hw-integrate-dashboard` (routing sekarang di Dashboard listener, bukan GoRouter redirect)

---

## 10. Risiko & Mitigasi — REVISED v2

| Risiko | Impact | Mitigasi |
|--------|--------|----------|
| ~~`AdapterViewFlipper` tidak support swipe gesture~~ | ~~Medium~~ | **R1: RESOLVED** — Diganti static layout + arrow buttons |
| ~~`Future.delayed` race condition di deep link~~ | ~~Medium~~ | **R2: RESOLVED** — State-based routing via `pendingWidgetActionProvider` |
| ~~Saldo terbuka di home screen~~ | ~~Medium~~ | **R3: RESOLVED** — Eye toggle, default hidden |
| ~~Config Activity crash jika data kosong~~ | ~~Medium~~ | **R4: RESOLVED** — Empty state dengan "Buka app dulu" + tombol |
| SharedPreferences race condition (Flutter vs Native) | Low | `home_widget` handle ini internally, tapi hindari concurrent writes |
| Deep link lost jika app di-kill | Medium | `HomeWidget.initiallyLaunchedFromHomeWidget()` catch cold start |
| Widget tidak update setelah app killed | Low | `updatePeriodMillis` sebagai fallback periodic update |
| Proguard menghapus widget classes | High | Tambahkan keep rules di `proguard-rules.pro` |
| Arrow nav PendingIntent request codes collide | Low | Unique hashCode dari `"$action$appWidgetId"` — sangat unlikely collision |
| Multiple widget instances share index/visibility state | Low | State di-key per `appWidgetId` (`widget_index_{id}`, `widget_balance_visible_{id}`) |
| **Cold Start: `ref.listen` tidak fire jika state sudah terisi sebelum Dashboard mount** | **High** | **Phase 2.5 fix:** Dual-path — `ref.listen` untuk warm start + `_coldStartHandled` flag + `addPostFrameCallback` initial check untuk cold start |

---

## 11. Referensi

- [home_widget 0.9.1 docs](https://docs.page/abausg/home_widget)
- [home_widget Android XML setup](https://docs.page/abausg/home_widget/android-xml/overview)
- [Android AppWidgetProvider docs](https://developer.android.com/develop/ui/views/appwidgets)
- [Android Widget Configuration](https://developer.android.com/develop/ui/views/appwidgets/configuration)
- [RemoteViews PendingIntent docs](https://developer.android.com/reference/android/widget/RemoteViews)
- [Riverpod StateProvider](https://riverpod.dev/docs/providers/state_provider)



