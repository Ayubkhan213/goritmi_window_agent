// import 'package:hive/hive.dart';
// import 'package:tenx_global_agent/models/printer_model.dart';
// import 'package:tenx_global_agent/models/printing_model.dart';

// class PrinterBoxService {
//   static const String _boxName = 'printerBoxs';
//   static const String _customerKey = 'customer_printer';
//   static const String _kotKey = 'kot_printer';

//   /// Open box
//   static Future<Box<Printer>> _openBox() async {
//     if (!Hive.isBoxOpen(_boxName)) {
//       return await Hive.openBox<Printer>(_boxName);
//     }
//     return Hive.box<Printer>(_boxName);
//   }

//   /// Save Customer Printer
//   static Future<void> saveCustomerPrinter(Printer printer) async {
//     final box = await _openBox();
//     await box.put(_customerKey, printer);
//   }

//   /// Get Customer Printer
//   static Future<Printer?> getCustomerPrinter() async {
//     final box = await _openBox();
//     return box.get(_customerKey);
//   }

//   /// Save KOT Printer
//   static Future<void> saveKOTPrinter(Printer printer) async {
//     final box = await _openBox();
//     await box.put(_kotKey, printer);
//   }

//   /// Get KOT Printer
//   static Future<Printer?> getKOTPrinter() async {
//     final box = await _openBox();
//     return box.get(_kotKey);
//   }

//   /// Delete Customer Printer
//   static Future<void> deleteCustomerPrinter() async {
//     final box = await _openBox();
//     await box.delete(_customerKey);
//   }

//   /// Delete KOT Printer
//   static Future<void> deleteKOTPrinter() async {
//     final box = await _openBox();
//     await box.delete(_kotKey);
//   }

//   /// Clear all printers
//   static Future<void> clearBox() async {
//     final box = await _openBox();
//     await box.clear();
//   }
// }
