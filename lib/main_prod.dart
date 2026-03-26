import 'package:app_saku_rapi/core/config/app_flavor.dart';
import 'package:app_saku_rapi/main.dart';

void main() async {
  AppFlavorConfig.init(AppFlavor.prod);
  await bootstrap();
}
