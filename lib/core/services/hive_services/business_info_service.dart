import 'package:hive/hive.dart';
import 'package:tenx_global_agent/models/business_info_model.dart';

class BusinessInfoBoxService {
  static const String _boxName = 'businessInfo';

  /// Open box (optional, if you need to ensure it's open)
  static Future<Box<BusinessInfoModel>> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<BusinessInfoModel>(_boxName);
    }
    return Hive.box<BusinessInfoModel>(_boxName);
  }

  /// Add or update data
  static Future<void> saveBusinessInfo(BusinessInfoModel data) async {
    final box = await _openBox();
    await box.put('businessInfo', data); // using a fixed key
  }

  /// Get data
  static Future<BusinessInfoModel?> getBusinessInfo() async {
    final box = await _openBox();
    return box.get('businessInfo');
  }

  /// Delete data
  static Future<void> deleteBusinessInfo() async {
    final box = await _openBox();
    await box.delete('businessInfo');
  }

  /// Clear all box (optional)
  static Future<void> clearBox() async {
    final box = await _openBox();
    await box.clear();
  }
}
