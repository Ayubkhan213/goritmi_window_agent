// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart' as intl;
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:tenx_global_agent/core/constants/utils.dart';
// import 'package:tenx_global_agent/core/services/hive_services/business_info_service.dart';
// import 'package:tenx_global_agent/models/order_response_model.dart';
// import 'package:image/image.dart' as img;

// class ReceiptDialogPreviewer {
//   /// Show KOT Slip in dialog
//   static Future<void> showKOTPreview({
//     required BuildContext context,
//     String orderId = '',
//     String orderType = '',
//     List<OrderItem>? items,
//   }) async {
//     final pdf = await _generateKotPDF(
//       orderId: orderId,
//       orderType: orderType,
//       items: items,
//     );
//     _showPdfDialog(context, pdf);
//   }

//   /// Show Customer Receipt in dialog
//   static Future<void> showReceiptPreview({
//     required BuildContext context,
//     required String orderId,
//     String orderType = '',
//     List<OrderItem>? items,
//     String customerName = 'Walk-in Customer',
//     String? customerAddress,
//     String? customerPhone,
//     double taxAmount = 0.0,
//     double deliveryCharge = 0.0,
//     double discount = 0.0,

//     Uint8List? logoBytes,
//   }) async {
//     final pdf = await _generateReceiptPDF(
//       orderId: orderId,
//       // orderType: orderType,
//       items: items,
//       customerName: customerName,
//       customerAddress: customerAddress,
//       customerPhone: customerPhone,
//       taxAmount: taxAmount,
//       deliveryCharge: deliveryCharge,
//       discount: discount,

//       // logoBytes: logoBytes,
//     );
//     _showPdfDialog(context, pdf);
//   }

//   /// =========================
//   /// Private: Show PDF in Dialog
//   /// =========================
//   static void _showPdfDialog(BuildContext context, pw.Document pdf) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         contentPadding: EdgeInsets.zero,
//         content: SizedBox(
//           width: MediaQuery.of(context).size.width * 0.45,
//           height: MediaQuery.of(context).size.height * 0.9,
//           child: PdfPreview(
//             // canPrint: false, // Disable printing
//             // canShare: false, // Disable sharing
//             build: (format) async => pdf.save(),
//             // allowZoom: true,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   /// =========================
//   /// Private: Generate KOT PDF
//   /// =========================
//   static Future<pw.Document> _generateKotPDF({
//     String orderId = '',
//     String orderType = '',
//     List<OrderItem>? items,
//   }) async {
//     final pdf = pw.Document();
//     final regularFont = await pw.Font.courier();
//     final boldFont = await pw.Font.courierBold();
//     final safeItems = items ?? [];

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.roll80,
//         build: (context) {
//           return pw.Padding(
//             padding: const pw.EdgeInsets.symmetric(horizontal: 8),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Center(
//                   child: pw.Text(
//                     'KITCHEN ORDER TICKET',
//                     style: pw.TextStyle(font: boldFont, fontSize: 14),
//                   ),
//                 ),
//                 pw.Center(
//                   child: pw.Text(
//                     'Order ID: #$orderId',
//                     style: pw.TextStyle(font: regularFont, fontSize: 10),
//                   ),
//                 ),
//                 pw.Center(
//                   child: pw.Text(
//                     'Date: ${intl.DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
//                     style: pw.TextStyle(font: regularFont, fontSize: 10),
//                   ),
//                 ),
//                 pw.Divider(),
//                 pw.Text(
//                   'Order Type: $orderType',
//                   style: pw.TextStyle(font: regularFont, fontSize: 10),
//                 ),
//                 pw.SizedBox(height: 5),
//                 pw.Text(
//                   'Items:',
//                   style: pw.TextStyle(font: boldFont, fontSize: 10),
//                 ),
//                 ...safeItems.map((item) => _itemRow(item, regularFont)),
//                 pw.Divider(),
//                 pw.Center(
//                   child: pw.Text(
//                     'Thank you!',
//                     style: pw.TextStyle(font: regularFont, fontSize: 8),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );

//     return pdf;
//   }

//   /// Convert image bytes to black & white (for thermal printer)
//   static Uint8List convertToBW(Uint8List inputBytes) {
//     final original = img.decodeImage(inputBytes);
//     if (original == null) return inputBytes;

//     // Convert to grayscale
//     final bw = img.grayscale(original);

//     // Optional: apply brightness/contrast adjustments if needed
//     // img.adjustColor(bw, brightness: 0.0, contrast: 1.0);

//     return Uint8List.fromList(img.encodePng(bw));
//   }

//   static Future<pw.ImageProvider?> getBWLogo(String? url) async {
//     if (url == null || url.isEmpty) return null;

//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final bytes = response.bodyBytes;
//         final bwBytes = convertToBW(bytes); // convert to black & white
//         return pw.MemoryImage(bwBytes);
//       }
//     } catch (e) {
//       print('Failed to load logo: $e');
//     }

//     return null;
//   }

//   /// =========================
//   /// Private: Generate Customer Receipt PDF
//   /// =========================
//   static Future<pw.Document> _generateReceiptPDF({
//     required String orderId,
//     // String orderType = '',
//     List<OrderItem>? items,
//     String customerName = 'Walk-in Customer',
//     String? customerAddress,
//     String? customerPhone,
//     double taxAmount = 0.0,
//     double deliveryCharge = 0.0,
//     double discount = 0.0,

//     // Uint8List? logoBytes,
//   }) async {
//     // Check if business info exists in Hive
//     final businessInfo = await BusinessInfoBoxService.getBusinessInfo();

//     final pdf = pw.Document();
//     final logo = await getBWLogo(businessInfo?.business.logoUrl);

//     final regularFont = await pw.Font.helvetica();
//     final boldFont = await pw.Font.helveticaBold();
//     final safeItems = Utils.resApiResponse?.order?.items;
//     // items ?? [];

//     double subtotal = (safeItems ?? []).fold(
//       0,
//       (prev, item) => prev + ((item.quantity ?? 0) * (item.price ?? 0)),
//     );
//     double totalPrice = subtotal + deliveryCharge + taxAmount - discount;

//     final times = await pw.Font.times();
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.roll80.copyWith(
//           marginTop: 0,
//           marginBottom: 5,
//           marginLeft: 8,
//           marginRight: 12,
//         ),
//         theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
//         build: (context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // if (businessInfo?.business.logoUrl != null)
//               //   pw.Center(child: pw.Image(logo!, width: 40, height: 40)),
//               // pw.SizedBox(height: 5),
//               pw.Center(
//                 child: pw.Text(
//                   Utils.resApiResponse?.order?.orderType ?? 'Eat In',
//                   style: pw.TextStyle(
//                     fontSize: 18,
//                     font: regularFont,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 5),
//               pw.Center(
//                 child: pw.Text(
//                   businessInfo?.business.businessName ?? 'Business Name',
//                   style: pw.TextStyle(
//                     fontSize: 12,
//                     font: regularFont,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 5),
//               pw.Center(
//                 child: pw.Text(
//                   'Order ID: #$orderId',
//                   style: pw.TextStyle(fontSize: 9, font: regularFont),
//                 ),
//               ),
//               pw.Center(
//                 child: pw.Text(
//                   'Date: ${intl.DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
//                   style: pw.TextStyle(fontSize: 9, font: times),
//                 ),
//               ),
//               pw.SizedBox(height: 5),
//               dottedBorder(),

//               _labelValue(
//                 'Payment Type',
//                 Utils.resApiResponse?.order?.paymentMethod ?? 'Cash',
//                 regularFont,
//               ),
//               _labelValue(
//                 'Order Type',
//                 Utils.resApiResponse?.order?.orderType ?? 'Eatin',
//                 regularFont,
//               ),
//               _labelValue('Customer Name', customerName, regularFont),
//               if (customerAddress != null)
//                 _labelValue('Address', customerAddress, regularFont),
//               if (customerPhone != null)
//                 _labelValue('Contact Number', customerPhone, regularFont),
//               dottedBorder(),
//               pw.Row(
//                 children: [
//                   pw.Expanded(
//                     child: pw.Text(
//                       'Item',
//                       style: pw.TextStyle(font: boldFont, fontSize: 9.0),
//                     ),
//                   ),
//                   pw.SizedBox(width: 40),
//                   pw.Text(
//                     'Qty',
//                     style: pw.TextStyle(fontSize: 9.0, font: boldFont),
//                   ),
//                   pw.SizedBox(width: 40),
//                   pw.Text(
//                     'Price',
//                     style: pw.TextStyle(fontSize: 9.0, font: boldFont),
//                   ),
//                 ],
//               ),
//               ...(safeItems ?? [])
//                   .map(
//                     (item) => pw.Row(
//                       children: [
//                         pw.Expanded(
//                           child: pw.Text(
//                             item.title ?? '',
//                             style: pw.TextStyle(fontSize: 9.0),
//                           ),
//                         ),
//                         pw.SizedBox(width: 40),
//                         pw.Text(
//                           'x${item.quantity ?? 0}',
//                           style: pw.TextStyle(fontSize: 9.0),
//                         ),
//                         pw.SizedBox(width: 40),
//                         pw.Text(
//                           '£${item.price!.toStringAsFixed(2)}',
//                           style: pw.TextStyle(fontSize: 9.0),
//                         ),
//                       ],
//                     ),
//                   )
//                   .toList(),
//               dottedBorder(),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   _labelValue(
//                     'Subtotal',
//                     '£${Utils.resApiResponse?.order?.subTotal?.toStringAsFixed(2)}',
//                     regularFont,
//                   ),

//                   if ((Utils.resApiResponse?.order?.approvedDiscounts ?? 0.0) >
//                       0.0)
//                     _labelValue(
//                       'Discount',
//                       '£${(Utils.resApiResponse?.order?.approvedDiscounts ?? 0.0).toStringAsFixed(2)}',
//                       regularFont,
//                     ),
//                   if ((Utils.resApiResponse?.order?.salesDiscount ?? 0.0) > 0.0)
//                     _labelValue(
//                       'sale',
//                       '-£${Utils.resApiResponse?.order?.salesDiscount!.toStringAsFixed(2)}',
//                       regularFont,
//                     ),
//                   if ((Utils.resApiResponse?.order?.promoDiscount ?? 0.0) > 0.0)
//                     _labelValue(
//                       'Promo Discount',
//                       '-£${Utils.resApiResponse?.order?.promoDiscount!.toStringAsFixed(2)}',
//                       regularFont,
//                     ),

//                   if (Utils.resApiResponse?.type == 'Delivery')
//                     _labelValue(
//                       'Delivery Charges',
//                       '${Utils.resApiResponse?.order?.deliveryCharges?.toStringAsFixed(0)}%',
//                       regularFont,
//                     ),
//                   _labelValue(
//                     'Total Price',
//                     '£${Utils.resApiResponse?.order?.totalAmount?.toStringAsFixed(2)}',
//                     regularFont,
//                   ),
//                   dottedBorder(),
//                   _labelFooter(
//                     'Email: ${businessInfo?.user.email ?? ''}',
//                     regularFont,
//                   ),
//                   _labelFooter(
//                     'Location: ${businessInfo?.business.address ?? ''}',
//                     regularFont,
//                   ),
//                   pw.Center(
//                     child: pw.Text(
//                       'Thank you for your order!',
//                       style: pw.TextStyle(font: regularFont, fontSize: 8),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     return pdf;
//   }

//   static pw.Widget _itemRow(OrderItem item, pw.Font font) {
//     final name = item.title ?? '';
//     final qty = item.quantity ?? 0;
//     final price = item.price ?? 0;
//     final total = (qty * price).toStringAsFixed(2);

//     return pw.Row(
//       children: [
//         pw.Expanded(
//           flex: 3,
//           child: pw.Text(name, style: pw.TextStyle(font: font, fontSize: 9)),
//         ),
//         pw.Expanded(
//           flex: 1,
//           child: pw.Text(
//             qty.toString(),
//             style: pw.TextStyle(font: font, fontSize: 9),
//             textAlign: pw.TextAlign.center,
//           ),
//         ),
//         pw.Expanded(
//           flex: 1,
//           child: pw.Text(
//             price.toStringAsFixed(2),
//             style: pw.TextStyle(font: font, fontSize: 9),
//             textAlign: pw.TextAlign.right,
//           ),
//         ),
//         pw.Expanded(
//           flex: 1,
//           child: pw.Text(
//             total,
//             style: pw.TextStyle(font: font, fontSize: 9),
//             textAlign: pw.TextAlign.right,
//           ),
//         ),
//       ],
//     );
//   }

//   ///======================================================
//   /// UI Helpers
//   ///======================================================
//   static pw.Widget dottedBorder() {
//     return pw.Container(
//       margin: const pw.EdgeInsets.symmetric(vertical: 2),
//       height: 1.1,
//       decoration: pw.BoxDecoration(
//         border: pw.Border(
//           bottom: pw.BorderSide(
//             color: PdfColors.black,
//             width: 1,
//             style: pw.BorderStyle.dashed, // dotted / dashed
//           ),
//         ),
//       ),
//     );
//   }

//   static pw.Widget _labelValue(String label, String value, pw.Font font) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 2),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(label, style: pw.TextStyle(fontSize: 9, font: font)),
//           pw.Text(value, style: pw.TextStyle(fontSize: 9, font: font)),
//         ],
//       ),
//     );
//   }

//   static pw.Widget _labelFooter(String text, pw.Font font) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.only(bottom: 2),
//       child: pw.Center(
//         child: pw.Text(
//           text,
//           style: pw.TextStyle(fontSize: 8, font: font),
//           textAlign: pw.TextAlign.center,
//         ),
//       ),
//     );
//   }

//   static pw.Widget _noteFooter(String label, String value) {
//     return pw.Row(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//         pw.SizedBox(width: 4),
//         pw.Expanded(
//           child: pw.Text(value, softWrap: true, textAlign: pw.TextAlign.left),
//         ),
//       ],
//     );
//   }

//   static void _showMessage(BuildContext context, String msg, Color color) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
//     } else {
//       debugPrint('⚠️ Snackbar skipped: context not mounted. Message: $msg');
//     }
//   }
// }
