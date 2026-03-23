import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Utility untuk mapping nama icon string (dari database) ke [IconData].
///
/// Kategori menyimpan icon sebagai string (misal 'house', 'car')
/// di database. Class ini menyediakan dua arah mapping:
/// - `getIcon(name)` → IconData
/// - `availableIcons` → daftar icon yang bisa dipilih user
class CategoryIconMapper {
  CategoryIconMapper._();

  /// Map nama icon ke [IconData] dari FontAwesome.
  static final Map<String, IconData> _iconMap = {
    // Rumah Tangga
    'house': FontAwesomeIcons.house,
    'cartShopping': FontAwesomeIcons.cartShopping,
    'couch': FontAwesomeIcons.couch,
    'utensils': FontAwesomeIcons.utensils,

    // Kesehatan
    'heartPulse': FontAwesomeIcons.heartPulse,
    'dumbbell': FontAwesomeIcons.dumbbell,
    'capsules': FontAwesomeIcons.capsules,
    'stethoscope': FontAwesomeIcons.stethoscope,

    // Transportasi
    'car': FontAwesomeIcons.car,
    'gasPump': FontAwesomeIcons.gasPump,
    'motorcycle': FontAwesomeIcons.motorcycle,
    'wrench': FontAwesomeIcons.wrench,

    // Tagihan
    'fileInvoiceDollar': FontAwesomeIcons.fileInvoiceDollar,
    'bolt': FontAwesomeIcons.bolt,
    'wifi': FontAwesomeIcons.wifi,
    'shieldHalved': FontAwesomeIcons.shieldHalved,

    // Teknologi & Edukasi
    'laptop': FontAwesomeIcons.laptop,
    'tv': FontAwesomeIcons.tv,
    'graduationCap': FontAwesomeIcons.graduationCap,
    'server': FontAwesomeIcons.server,

    // Keluarga & Sosial
    'peopleGroup': FontAwesomeIcons.peopleGroup,
    'heart': FontAwesomeIcons.heart,
    'handHoldingHeart': FontAwesomeIcons.handHoldingHeart,
    'champagneGlasses': FontAwesomeIcons.champagneGlasses,

    // Lain-lain
    'ellipsis': FontAwesomeIcons.ellipsis,
    'receipt': FontAwesomeIcons.receipt,
    'triangleExclamation': FontAwesomeIcons.triangleExclamation,

    // Income
    'briefcase': FontAwesomeIcons.briefcase,
    'moneyBill': FontAwesomeIcons.moneyBill,
    'gift': FontAwesomeIcons.gift,
    'circlePlus': FontAwesomeIcons.circlePlus,
    'laptopCode': FontAwesomeIcons.laptopCode,
    'chartLine': FontAwesomeIcons.chartLine,
    'moneyBillTransfer': FontAwesomeIcons.moneyBillTransfer,

    // System
    'scaleBalanced': FontAwesomeIcons.scaleBalanced,
    'rightLeft': FontAwesomeIcons.rightLeft,

    // Extra icons yang bisa dipilih user
    'bagShopping': FontAwesomeIcons.bagShopping,
    'book': FontAwesomeIcons.book,
    'bus': FontAwesomeIcons.bus,
    'camera': FontAwesomeIcons.camera,
    'circleUser': FontAwesomeIcons.circleUser,
    'clock': FontAwesomeIcons.clock,
    'cloud': FontAwesomeIcons.cloud,
    'code': FontAwesomeIcons.code,
    'coins': FontAwesomeIcons.coins,
    'compass': FontAwesomeIcons.compass,
    'creditCard': FontAwesomeIcons.creditCard,
    'dog': FontAwesomeIcons.dog,
    'cat': FontAwesomeIcons.cat,
    'envelope': FontAwesomeIcons.envelope,
    'film': FontAwesomeIcons.film,
    'fire': FontAwesomeIcons.fire,
    'gamepad': FontAwesomeIcons.gamepad,
    'gem': FontAwesomeIcons.gem,
    'globe': FontAwesomeIcons.globe,
    'guitar': FontAwesomeIcons.guitar,
    'hammer': FontAwesomeIcons.hammer,
    'headphones': FontAwesomeIcons.headphones,
    'hospital': FontAwesomeIcons.hospital,
    'key': FontAwesomeIcons.key,
    'lightbulb': FontAwesomeIcons.lightbulb,
    'locationDot': FontAwesomeIcons.locationDot,
    'lock': FontAwesomeIcons.lock,
    'microphone': FontAwesomeIcons.microphone,
    'mobile': FontAwesomeIcons.mobile,
    'music': FontAwesomeIcons.music,
    'paintbrush': FontAwesomeIcons.paintbrush,
    'palette': FontAwesomeIcons.palette,
    'paw': FontAwesomeIcons.paw,
    'phone': FontAwesomeIcons.phone,
    'piggyBank': FontAwesomeIcons.piggyBank,
    'plane': FontAwesomeIcons.plane,
    'plug': FontAwesomeIcons.plug,
    'rocket': FontAwesomeIcons.rocket,
    'scissors': FontAwesomeIcons.scissors,
    'shirt': FontAwesomeIcons.shirt,
    'snowflake': FontAwesomeIcons.snowflake,
    'spa': FontAwesomeIcons.spa,
    'star': FontAwesomeIcons.star,
    'store': FontAwesomeIcons.store,
    'sun': FontAwesomeIcons.sun,
    'tag': FontAwesomeIcons.tag,
    'tooth': FontAwesomeIcons.tooth,
    'train': FontAwesomeIcons.train,
    'tree': FontAwesomeIcons.tree,
    'trophy': FontAwesomeIcons.trophy,
    'truckFast': FontAwesomeIcons.truckFast,
    'umbrella': FontAwesomeIcons.umbrella,
    'video': FontAwesomeIcons.video,
    'wallet': FontAwesomeIcons.wallet,
    'wineGlass': FontAwesomeIcons.wineGlass,
  };

  /// Mendapatkan [IconData] dari nama string.
  ///
  /// Jika nama tidak ditemukan, gunakan icon default [FontAwesomeIcons.tag].
  static IconData getIcon(String name) {
    return _iconMap[name] ?? FontAwesomeIcons.tag;
  }

  /// Daftar semua icon yang tersedia untuk dipilih user.
  static Map<String, IconData> get availableIcons => Map.unmodifiable(_iconMap);

  /// Daftar nama icon yang tersedia.
  static List<String> get availableIconNames => _iconMap.keys.toList();
}
