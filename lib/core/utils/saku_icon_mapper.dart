import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Data model untuk satu section (grup) ikon.
class IconSection {
  const IconSection({required this.id, required this.iconNames});

  /// ID section — digunakan untuk mapping ke l10n key.
  final String id;

  /// Daftar nama ikon dalam section ini.
  final List<String> iconNames;
}

/// Utility mapping nama ikon string (dari database) ke [IconData].
///
/// Menyediakan:
/// - `getIcon(name)` → IconData
/// - `availableIcons` → semua ikon
/// - `sections` → ikon dikelompokkan per kategori
/// - `search(query)` → pencarian bilingual (ID + EN)
class SakuIconMapper {
  SakuIconMapper._();

  // ─────────────── Icon Map ───────────────

  static final Map<String, IconData> _iconMap = {
    // Keuangan
    'wallet': FontAwesomeIcons.wallet,
    'moneyBill': FontAwesomeIcons.moneyBill,
    'moneyBillTransfer': FontAwesomeIcons.moneyBillTransfer,
    'creditCard': FontAwesomeIcons.creditCard,
    'coins': FontAwesomeIcons.coins,
    'piggyBank': FontAwesomeIcons.piggyBank,
    'chartLine': FontAwesomeIcons.chartLine,
    'fileInvoiceDollar': FontAwesomeIcons.fileInvoiceDollar,
    'receipt': FontAwesomeIcons.receipt,
    'percent': FontAwesomeIcons.percent,
    'scaleBalanced': FontAwesomeIcons.scaleBalanced,
    'rightLeft': FontAwesomeIcons.rightLeft,

    // Belanja & Gaya Hidup
    'cartShopping': FontAwesomeIcons.cartShopping,
    'bagShopping': FontAwesomeIcons.bagShopping,
    'store': FontAwesomeIcons.store,
    'tag': FontAwesomeIcons.tag,
    'shirt': FontAwesomeIcons.shirt,
    'shoePrints': FontAwesomeIcons.shoePrints,
    'gem': FontAwesomeIcons.gem,

    // Makanan & Minuman
    'utensils': FontAwesomeIcons.utensils,
    'mugHot': FontAwesomeIcons.mugHot,
    'cookieBite': FontAwesomeIcons.cookieBite,
    'wineGlass': FontAwesomeIcons.wineGlass,
    'champagneGlasses': FontAwesomeIcons.champagneGlasses,

    // Rumah Tangga
    'house': FontAwesomeIcons.house,
    'building': FontAwesomeIcons.building,
    'couch': FontAwesomeIcons.couch,
    'lightbulb': FontAwesomeIcons.lightbulb,
    'key': FontAwesomeIcons.key,
    'lock': FontAwesomeIcons.lock,
    'wrench': FontAwesomeIcons.wrench,
    'broom': FontAwesomeIcons.broom,

    // Transportasi
    'car': FontAwesomeIcons.car,
    'motorcycle': FontAwesomeIcons.motorcycle,
    'bus': FontAwesomeIcons.bus,
    'train': FontAwesomeIcons.train,
    'plane': FontAwesomeIcons.plane,
    'planeUp': FontAwesomeIcons.planeUp,
    'gasPump': FontAwesomeIcons.gasPump,
    'road': FontAwesomeIcons.road,
    'squareParking': FontAwesomeIcons.squareParking,
    'truckFast': FontAwesomeIcons.truckFast,

    // Kesehatan & Kebugaran
    'heartPulse': FontAwesomeIcons.heartPulse,
    'stethoscope': FontAwesomeIcons.stethoscope,
    'capsules': FontAwesomeIcons.capsules,
    'hospital': FontAwesomeIcons.hospital,
    'tooth': FontAwesomeIcons.tooth,
    'dumbbell': FontAwesomeIcons.dumbbell,
    'spa': FontAwesomeIcons.spa,
    'brain': FontAwesomeIcons.brain,

    // Tagihan & Utilitas
    'bolt': FontAwesomeIcons.bolt,
    'wifi': FontAwesomeIcons.wifi,
    'shieldHalved': FontAwesomeIcons.shieldHalved,
    'plug': FontAwesomeIcons.plug,

    // Teknologi
    'laptop': FontAwesomeIcons.laptop,
    'laptopCode': FontAwesomeIcons.laptopCode,
    'mobile': FontAwesomeIcons.mobile,
    'tv': FontAwesomeIcons.tv,
    'server': FontAwesomeIcons.server,
    'headphones': FontAwesomeIcons.headphones,
    'camera': FontAwesomeIcons.camera,
    'video': FontAwesomeIcons.video,
    'microphone': FontAwesomeIcons.microphone,
    'code': FontAwesomeIcons.code,
    'gamepad': FontAwesomeIcons.gamepad,

    // Pendidikan & Karier
    'graduationCap': FontAwesomeIcons.graduationCap,
    'briefcase': FontAwesomeIcons.briefcase,
    'book': FontAwesomeIcons.book,
    'hammer': FontAwesomeIcons.hammer,

    // Hiburan
    'music': FontAwesomeIcons.music,
    'guitar': FontAwesomeIcons.guitar,
    'film': FontAwesomeIcons.film,
    'masksTheater': FontAwesomeIcons.masksTheater,
    'puzzlePiece': FontAwesomeIcons.puzzlePiece,
    'trophy': FontAwesomeIcons.trophy,
    'star': FontAwesomeIcons.star,
    'palette': FontAwesomeIcons.palette,
    'paintbrush': FontAwesomeIcons.paintbrush,

    // Alam & Hewan
    'tree': FontAwesomeIcons.tree,
    'sun': FontAwesomeIcons.sun,
    'snowflake': FontAwesomeIcons.snowflake,
    'umbrella': FontAwesomeIcons.umbrella,
    'cloud': FontAwesomeIcons.cloud,
    'fire': FontAwesomeIcons.fire,
    'dog': FontAwesomeIcons.dog,
    'cat': FontAwesomeIcons.cat,
    'paw': FontAwesomeIcons.paw,

    // Sosial & Keluarga
    'peopleGroup': FontAwesomeIcons.peopleGroup,
    'heart': FontAwesomeIcons.heart,
    'handHoldingHeart': FontAwesomeIcons.handHoldingHeart,
    'circleUser': FontAwesomeIcons.circleUser,
    'gift': FontAwesomeIcons.gift,
    'phone': FontAwesomeIcons.phone,
    'envelope': FontAwesomeIcons.envelope,

    // Lainnya
    'ellipsis': FontAwesomeIcons.ellipsis,
    'triangleExclamation': FontAwesomeIcons.triangleExclamation,
    'circleQuestion': FontAwesomeIcons.circleQuestion,
    'circlePlus': FontAwesomeIcons.circlePlus,
    'rocket': FontAwesomeIcons.rocket,
    'locationDot': FontAwesomeIcons.locationDot,
    'compass': FontAwesomeIcons.compass,
    'globe': FontAwesomeIcons.globe,
    'clock': FontAwesomeIcons.clock,
    'scissors': FontAwesomeIcons.scissors,
  };

  // ─────────────── Sections ───────────────

  /// Daftar section untuk grouped display di picker.
  /// [IconSection.id] digunakan untuk mapping l10n key.
  static final List<IconSection> sections = [
    const IconSection(
      id: 'finance',
      iconNames: [
        'wallet',
        'moneyBill',
        'moneyBillTransfer',
        'creditCard',
        'coins',
        'piggyBank',
        'chartLine',
        'fileInvoiceDollar',
        'receipt',
        'percent',
        'scaleBalanced',
        'rightLeft',
      ],
    ),
    const IconSection(
      id: 'shopping',
      iconNames: [
        'cartShopping',
        'bagShopping',
        'store',
        'tag',
        'shirt',
        'shoePrints',
        'gem',
      ],
    ),
    const IconSection(
      id: 'foodDrink',
      iconNames: [
        'utensils',
        'mugHot',
        'cookieBite',
        'wineGlass',
        'champagneGlasses',
      ],
    ),
    const IconSection(
      id: 'household',
      iconNames: [
        'house',
        'building',
        'couch',
        'lightbulb',
        'key',
        'lock',
        'wrench',
        'broom',
      ],
    ),
    const IconSection(
      id: 'transport',
      iconNames: [
        'car',
        'motorcycle',
        'bus',
        'train',
        'plane',
        'planeUp',
        'gasPump',
        'road',
        'squareParking',
        'truckFast',
      ],
    ),
    const IconSection(
      id: 'health',
      iconNames: [
        'heartPulse',
        'stethoscope',
        'capsules',
        'hospital',
        'tooth',
        'dumbbell',
        'spa',
        'brain',
      ],
    ),
    const IconSection(
      id: 'bills',
      iconNames: ['bolt', 'wifi', 'shieldHalved', 'plug'],
    ),
    const IconSection(
      id: 'tech',
      iconNames: [
        'laptop',
        'laptopCode',
        'mobile',
        'tv',
        'server',
        'headphones',
        'camera',
        'video',
        'microphone',
        'code',
        'gamepad',
      ],
    ),
    const IconSection(
      id: 'education',
      iconNames: ['graduationCap', 'briefcase', 'book', 'hammer'],
    ),
    const IconSection(
      id: 'entertainment',
      iconNames: [
        'music',
        'guitar',
        'film',
        'masksTheater',
        'puzzlePiece',
        'trophy',
        'star',
        'palette',
        'paintbrush',
      ],
    ),
    const IconSection(
      id: 'nature',
      iconNames: [
        'tree',
        'sun',
        'snowflake',
        'umbrella',
        'cloud',
        'fire',
        'dog',
        'cat',
        'paw',
      ],
    ),
    const IconSection(
      id: 'social',
      iconNames: [
        'peopleGroup',
        'heart',
        'handHoldingHeart',
        'circleUser',
        'gift',
        'phone',
        'envelope',
      ],
    ),
    const IconSection(
      id: 'other',
      iconNames: [
        'ellipsis',
        'triangleExclamation',
        'circleQuestion',
        'circlePlus',
        'rocket',
        'locationDot',
        'compass',
        'globe',
        'clock',
        'scissors',
      ],
    ),
  ];

  // ─────────────── Bilingual Search Terms ───────────────

  /// Kamus pencarian bilingual (ID + EN) per ikon.
  static final Map<String, List<String>> _searchTerms = {
    // Keuangan
    'wallet': ['wallet', 'dompet', 'purse'],
    'moneyBill': ['money', 'bill', 'uang', 'cash', 'tunai'],
    'moneyBillTransfer': ['transfer', 'kirim', 'send', 'pindah'],
    'creditCard': ['credit', 'card', 'kartu', 'debit'],
    'coins': ['coins', 'koin', 'receh', 'uang'],
    'piggyBank': ['piggy', 'bank', 'celengan', 'tabungan', 'saving'],
    'chartLine': ['chart', 'grafik', 'investasi', 'investment', 'saham'],
    'fileInvoiceDollar': ['invoice', 'faktur', 'tagihan'],
    'receipt': ['receipt', 'struk', 'kuitansi', 'bon', 'nota'],
    'percent': ['percent', 'cashback', 'reward', 'diskon', 'promo', 'persen'],
    'scaleBalanced': ['balance', 'saldo', 'neraca', 'timbangan'],
    'rightLeft': ['transfer', 'exchange', 'tukar', 'pindah'],

    // Belanja & Gaya Hidup
    'cartShopping': ['cart', 'shopping', 'belanja', 'keranjang'],
    'bagShopping': ['bag', 'shopping', 'tas', 'belanja'],
    'store': ['store', 'shop', 'toko'],
    'tag': ['tag', 'label', 'harga', 'price'],
    'shirt': ['shirt', 'clothes', 'baju', 'pakaian', 'fashion'],
    'shoePrints': ['shoe', 'sepatu', 'footwear', 'sandal', 'tas'],
    'gem': ['gem', 'diamond', 'permata', 'berlian', 'perhiasan'],

    // Makanan & Minuman
    'utensils': ['utensils', 'food', 'makanan', 'makan', 'restoran'],
    'mugHot': ['mug', 'coffee', 'kopi', 'minuman', 'cafe', 'drink'],
    'cookieBite': ['cookie', 'snack', 'jajan', 'camilan', 'kue', 'biscuit'],
    'wineGlass': ['wine', 'glass', 'minuman', 'drink'],
    'champagneGlasses': ['champagne', 'party', 'pesta', 'perayaan'],

    // Rumah Tangga
    'house': ['house', 'home', 'rumah', 'sewa'],
    'building': ['building', 'gedung', 'kpr', 'properti', 'apartemen'],
    'couch': ['couch', 'sofa', 'furniture', 'perabot', 'kursi'],
    'lightbulb': ['light', 'lampu', 'listrik', 'ide'],
    'key': ['key', 'kunci'],
    'lock': ['lock', 'gembok', 'kunci', 'keamanan'],
    'wrench': ['wrench', 'tool', 'alat', 'perbaikan', 'repair', 'servis'],
    'broom': [
      'broom',
      'sapu',
      'kebersihan',
      'bersih',
      'cleaning',
      'mop',
      'alat kebersihan',
    ],

    // Transportasi
    'car': ['car', 'mobil', 'kendaraan', 'vehicle'],
    'motorcycle': ['motorcycle', 'motor', 'sepeda'],
    'bus': ['bus', 'bis', 'angkutan', 'transport'],
    'train': ['train', 'kereta', 'krl', 'mrt'],
    'plane': ['plane', 'pesawat', 'terbang', 'flight', 'travel'],
    'planeUp': [
      'plane',
      'pesawat',
      'terbang',
      'flight',
      'liburan',
      'wisata',
      'travel',
    ],
    'gasPump': ['gas', 'fuel', 'bensin', 'bbm', 'solar'],
    'road': ['road', 'toll', 'jalan', 'tol'],
    'squareParking': ['parking', 'parkir'],
    'truckFast': ['truck', 'delivery', 'truk', 'kirim', 'ekspedisi'],

    // Kesehatan & Kebugaran
    'heartPulse': ['heart', 'health', 'kesehatan', 'jantung', 'medis'],
    'stethoscope': ['stethoscope', 'doctor', 'dokter', 'medis'],
    'capsules': ['capsule', 'medicine', 'obat', 'farmasi', 'pil'],
    'hospital': ['hospital', 'rumah sakit', 'rs', 'klinik'],
    'tooth': ['tooth', 'dental', 'gigi', 'dentist'],
    'dumbbell': ['dumbbell', 'gym', 'fitness', 'olahraga', 'sport'],
    'spa': ['spa', 'relax', 'pijat', 'wellness', 'kecantikan'],
    'brain': [
      'brain',
      'mental',
      'otak',
      'psikolog',
      'terapi',
      'therapy',
      'kesehatan mental',
    ],

    // Tagihan & Utilitas
    'bolt': ['bolt', 'electricity', 'listrik', 'pln', 'petir'],
    'wifi': ['wifi', 'internet', 'jaringan', 'network'],
    'shieldHalved': ['shield', 'insurance', 'asuransi', 'proteksi'],
    'plug': ['plug', 'electric', 'colokan', 'listrik', 'charger'],

    // Teknologi
    'laptop': ['laptop', 'computer', 'komputer', 'pc'],
    'laptopCode': ['laptop', 'code', 'coding', 'developer', 'freelance'],
    'mobile': ['mobile', 'phone', 'handphone', 'hp', 'ponsel'],
    'tv': ['tv', 'television', 'televisi', 'streaming', 'nonton'],
    'server': ['server', 'hosting', 'data'],
    'headphones': ['headphones', 'earphone', 'headset', 'audio'],
    'camera': ['camera', 'kamera', 'foto', 'photography'],
    'video': ['video', 'rekaman', 'recording', 'youtube'],
    'microphone': ['microphone', 'mic', 'mikrofon', 'podcast'],
    'code': ['code', 'coding', 'programming', 'kode'],
    'gamepad': ['game', 'gaming', 'play', 'permainan', 'konsol'],

    // Pendidikan & Karier
    'graduationCap': [
      'graduation',
      'education',
      'pendidikan',
      'sekolah',
      'kuliah',
      'wisuda',
    ],
    'briefcase': ['briefcase', 'work', 'office', 'kerja', 'kantor', 'bisnis'],
    'book': ['book', 'buku', 'reading', 'baca', 'belajar'],
    'hammer': ['hammer', 'construction', 'palu', 'bangun', 'renovasi'],

    // Hiburan
    'music': ['music', 'musik', 'lagu', 'song'],
    'guitar': ['guitar', 'gitar', 'musik', 'instrument'],
    'film': ['film', 'movie', 'bioskop', 'cinema', 'nonton'],
    'masksTheater': [
      'theater',
      'teater',
      'hiburan',
      'entertainment',
      'drama',
      'konser',
    ],
    'puzzlePiece': ['puzzle', 'game', 'hobi', 'hobby', 'koleksi'],
    'trophy': ['trophy', 'award', 'piala', 'penghargaan', 'juara'],
    'star': ['star', 'favorite', 'bintang', 'favorit'],
    'palette': ['palette', 'art', 'seni', 'design', 'desain', 'warna'],
    'paintbrush': ['paintbrush', 'paint', 'kuas', 'lukis', 'seni'],

    // Alam & Hewan
    'tree': ['tree', 'nature', 'pohon', 'alam', 'taman'],
    'sun': ['sun', 'matahari', 'cuaca', 'weather', 'panas'],
    'snowflake': ['snowflake', 'snow', 'salju', 'dingin', 'ac'],
    'umbrella': ['umbrella', 'rain', 'payung', 'hujan'],
    'cloud': ['cloud', 'awan', 'cuaca', 'storage'],
    'fire': ['fire', 'api', 'panas', 'darurat'],
    'dog': ['dog', 'pet', 'anjing', 'hewan'],
    'cat': ['cat', 'pet', 'kucing', 'hewan'],
    'paw': ['paw', 'pet', 'animal', 'jejak', 'hewan'],

    // Sosial & Keluarga
    'peopleGroup': ['people', 'group', 'orang', 'kelompok', 'komunitas'],
    'heart': ['heart', 'love', 'hati', 'cinta', 'donasi'],
    'handHoldingHeart': ['donate', 'charity', 'donasi', 'amal', 'sedekah'],
    'circleUser': ['user', 'profile', 'pengguna', 'profil', 'pribadi'],
    'gift': ['gift', 'present', 'hadiah', 'kado', 'bonus'],
    'phone': ['phone', 'call', 'telepon', 'panggilan', 'pulsa'],
    'envelope': ['envelope', 'email', 'mail', 'surat', 'pesan'],

    // Lainnya
    'ellipsis': ['more', 'other', 'lainnya', 'lain', 'dll'],
    'triangleExclamation': ['warning', 'alert', 'peringatan', 'darurat'],
    'circleQuestion': ['question', 'help', 'pertanyaan', 'bantuan'],
    'circlePlus': ['add', 'plus', 'tambah', 'baru'],
    'rocket': ['rocket', 'startup', 'roket', 'luncur'],
    'locationDot': ['location', 'map', 'lokasi', 'peta', 'tempat'],
    'compass': ['compass', 'navigate', 'kompas', 'navigasi', 'arah'],
    'globe': ['globe', 'world', 'international', 'dunia', 'global'],
    'clock': ['clock', 'time', 'jam', 'waktu', 'jadwal'],
    'scissors': ['scissors', 'cut', 'gunting', 'potong', 'salon'],
  };

  // ─────────────── Public API ───────────────

  /// Mendapatkan [IconData] dari nama string.
  /// Default ke [FontAwesomeIcons.tag] jika tidak ditemukan.
  static IconData getIcon(String name) {
    return _iconMap[name] ?? FontAwesomeIcons.tag;
  }

  /// Semua ikon yang tersedia.
  static Map<String, IconData> get availableIcons => Map.unmodifiable(_iconMap);

  /// Daftar nama ikon yang tersedia.
  static List<String> get availableIconNames => _iconMap.keys.toList();

  /// Pencarian ikon bilingual (ID + EN).
  ///
  /// Mencocokkan terhadap nama key ikon dan kamus bilingual.
  /// Mengembalikan semua ikon jika [query] kosong.
  static List<String> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _iconMap.keys.toList();

    return _iconMap.keys.where((name) {
      // Match terhadap key name (camelCase → lowercase)
      if (name.toLowerCase().contains(q)) return true;
      // Match terhadap kamus bilingual
      final terms = _searchTerms[name];
      if (terms != null) {
        return terms.any((t) => t.contains(q));
      }
      return false;
    }).toList();
  }
}
