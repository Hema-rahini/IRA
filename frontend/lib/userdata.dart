import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

class HiveBox {
  static late Box<bool> sessionBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    sessionBox = await Hive.openBox<bool>('sessionBox');
  }
}
