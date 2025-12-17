import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart' as pf;
import 'package:provider/provider.dart';
import 'package:tenx_global_agent/core/services/hive_services/business_info_service.dart';
import 'package:tenx_global_agent/models/order_response_model.dart';
import '../printing_agent/provider/printing_agent_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ReceiptPrinter {
  ///======================================================
  /// Print KOT Receipt
  ///======================================================
  static Future<void> printKOT({
    required BuildContext context,
    required OrderResponse orderResponse,
  }) async {
    try {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🖨️  Starting KOT Print");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final provider = Provider.of<PrintingAgentProvider>(
        context,
        listen: false,
      );

      // Check if KOT printer is selected
      if (provider.kotPrinter == null) {
        throw Exception(
          'No KOT printer selected. Please select a printer in settings.',
        );
      }

      debugPrint("🎯 Selected KOT Printer:");
      debugPrint("   Name: ${provider.kotPrinter!.name}");
      debugPrint("   URL: ${provider.kotPrinter!.url}");

      // Get OS printers
      final osPrinters = await pf.Printing.listPrinters();
      debugPrint("📋 Found ${osPrinters.length} OS printers");

      if (osPrinters.isEmpty) {
        throw Exception('No printers found in system');
      }

      // Find matching printer
      pf.Printer? targetPrinter = _findMatchingPrinter(
        osPrinters,
        provider.kotPrinter!,
        'KOT',
      );

      if (targetPrinter == null) {
        throw Exception(
          'KOT printer "${provider.kotPrinter!.name}" not found. '
          'Please refresh printers in settings.',
        );
      }

      debugPrint("✅ Target printer found: ${targetPrinter.name}");

      // Generate PDF
      debugPrint("📄 Generating KOT PDF...");
      final pdf = await _generateKotPDF(orderResponse: orderResponse);

      // Print
      debugPrint("🖨️  Sending to printer...");
      await pf.Printing.directPrintPdf(
        printer: targetPrinter,
        onLayout: (_) async => pdf.save(),
        name: 'KOT_orderId',
        format: PdfPageFormat.roll80,
      );

      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("✅ KOT printed successfully!");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      if (context.mounted) {
        _showMessage(context, 'KOT printed successfully!', Colors.green);
      }
    } catch (e) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ KOT printing failed: $e");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      if (context.mounted) {
        _showMessage(context, 'KOT printing failed: $e', Colors.red);
      }
      rethrow;
    }
  }

  ///======================================================
  /// Print Customer Receipt
  ///======================================================
  static Future<void> printReceipt({
    required BuildContext context,
    required OrderResponse orderResponse,
  }) async {
    try {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("🖨️  Starting Customer Receipt Print");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      final provider = Provider.of<PrintingAgentProvider>(
        context,
        listen: false,
      );

      // Check if customer printer is selected
      if (provider.customerPrinter == null) {
        throw Exception(
          'No customer printer selected. Please select a printer in settings.',
        );
      }

      debugPrint("🎯 Selected Customer Printer:");
      debugPrint("   Name: ${provider.customerPrinter!.name}");
      debugPrint("   URL: ${provider.customerPrinter!.url}");

      // Get OS printers
      final osPrinters = await pf.Printing.listPrinters();
      debugPrint("📋 Found ${osPrinters.length} OS printers");

      // Debug: Print all available printers
      for (var printer in osPrinters) {
        debugPrint("   📄 ${printer.name} - ${printer.url}");
      }

      if (osPrinters.isEmpty) {
        throw Exception('No printers found in system');
      }

      // Find matching printer
      pf.Printer? targetPrinter = _findMatchingPrinter(
        osPrinters,
        provider.customerPrinter!,
        'Customer',
      );

      if (targetPrinter == null) {
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        debugPrint("❌ PRINTER NOT FOUND");
        debugPrint("Saved: ${provider.customerPrinter!.name}");
        debugPrint("Available printers:");
        for (var p in osPrinters) {
          debugPrint("  - ${p.name} (${p.url})");
        }
        debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

        throw Exception(
          'Customer printer "${provider.customerPrinter!.name}" not found. '
          'Please refresh printers in settings.',
        );
      }

      debugPrint("✅ Target printer matched: ${targetPrinter.name}");

      // Generate PDF
      debugPrint("📄 Generating receipt PDF...");
      final pdf = await _generateReceiptPDF(orderResponse: orderResponse);

      // Print
      debugPrint("🖨️  Sending to printer: ${targetPrinter.name}");
      await pf.Printing.directPrintPdf(
        printer: targetPrinter,
        onLayout: (_) async => pdf.save(),
        name: 'Receipt_${orderResponse.order?.id}',
        format: PdfPageFormat.roll80,
      );

      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("✅ Receipt printed successfully!");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      if (context.mounted) {
        _showMessage(context, 'Receipt printed successfully!', Colors.green);
      }
    } catch (e) {
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      debugPrint("❌ Customer receipt printing failed: $e");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      if (context.mounted) {
        _showMessage(context, 'Receipt printing failed: $e', Colors.red);
      }
      rethrow;
    }
  }

  ///======================================================
  /// Helper: Find Matching Printer
  /// IMPROVED: Better detection for Windows 10 LAN printers
  ///======================================================
  static pf.Printer? _findMatchingPrinter(
    List<pf.Printer> osPrinters,
    dynamic customPrinter,
    String printerType,
  ) {
    final String savedName = customPrinter.name ?? '';
    final String savedUrl = customPrinter.url ?? '';

    debugPrint("🔍 Matching $printerType printer:");
    debugPrint("   Looking for: $savedName");
    debugPrint("   URL: $savedUrl");

    // Determine if this is a network printer by checking if URL contains an IP
    final bool isNetworkPrinter = _isIpAddress(savedUrl);

    if (isNetworkPrinter) {
      debugPrint("   🌐 Detected as NETWORK/LAN printer");
    } else {
      debugPrint("   🔌 Detected as USB/LOCAL printer");
    }

    // Method 1: Exact name match (works for USB printers)
    try {
      final nameMatch = osPrinters.firstWhere(
        (p) => p.name.trim().toLowerCase() == savedName.trim().toLowerCase(),
      );
      debugPrint("✅ Found exact name match: ${nameMatch.name}");
      return nameMatch;
    } catch (e) {
      debugPrint("⚠️  No exact name match");
    }

    // Method 2: For NETWORK printers - Special handling
    if (isNetworkPrinter) {
      debugPrint("🔍 Trying network printer detection strategies...");

      // Extract IP from saved URL
      final savedIp = _extractIpFromUrl(savedUrl);
      if (savedIp != null) {
        debugPrint("   IP to match: $savedIp");

        // Strategy A: Look for any thermal/receipt printer keywords
        final thermalKeywords = [
          'xprinter',
          'xp-',
          'thermal',
          'pos',
          'receipt',
          'blackcopper',
          '80mm',
          'zj-',
          'rp-',
        ];

        try {
          final thermalPrinter = osPrinters.firstWhere((p) {
            final name = p.name.toLowerCase();
            final url = p.url.toLowerCase();

            // Check if it's a thermal printer type
            final isThermalType = thermalKeywords.any(
              (kw) => name.contains(kw),
            );

            // Check if URL contains the IP
            final hasMatchingIp = url.contains(savedIp);

            debugPrint(
              "   Checking: ${p.name} | thermal=$isThermalType | ip=$hasMatchingIp",
            );

            return isThermalType || hasMatchingIp;
          });

          debugPrint("✅ Found network thermal printer: ${thermalPrinter.name}");
          return thermalPrinter;
        } catch (e) {
          debugPrint("⚠️  No thermal printer found with IP");
        }

        // Strategy B: Match by IP pattern in saved name
        // "Thermal Printer (.200)" -> extract ".200" -> match "192.168.123.200"
        final ipSuffixMatch = RegExp(r'\(\.(\d+)\)').firstMatch(savedName);
        if (ipSuffixMatch != null) {
          final suffix = ipSuffixMatch.group(1);
          debugPrint("   Extracted IP suffix from saved name: .$suffix");

          // Try to find printer with matching IP ending
          try {
            final ipMatch = osPrinters.firstWhere((p) {
              final name = p.name.toLowerCase();
              final isThermal = thermalKeywords.any((kw) => name.contains(kw));

              // If thermal printer exists and saved name has this IP suffix,
              // assume it's the same printer
              return isThermal && savedIp.endsWith('.$suffix');
            });

            debugPrint("✅ Found by IP suffix matching: ${ipMatch.name}");
            return ipMatch;
          } catch (e) {
            debugPrint("⚠️  No IP suffix match");
          }
        }

        // Strategy C: If only ONE thermal printer exists, use it
        // (Common scenario: user has one thermal printer installed)
        final allThermalPrinters = osPrinters.where((p) {
          final name = p.name.toLowerCase();
          return thermalKeywords.any((kw) => name.contains(kw));
        }).toList();

        if (allThermalPrinters.length == 1) {
          debugPrint(
            "✅ Found single thermal printer, using it: ${allThermalPrinters[0].name}",
          );
          return allThermalPrinters[0];
        } else if (allThermalPrinters.length > 1) {
          debugPrint(
            "⚠️  Multiple thermal printers found (${allThermalPrinters.length}), cannot auto-select",
          );
        }
      }
    }

    // Method 3: Partial name match (for similar printer names)
    if (savedName.isNotEmpty) {
      final keywords = savedName
          .toLowerCase()
          .split(RegExp(r'[\s\-_()]'))
          .where((w) => w.length > 2)
          .toList();

      if (keywords.isNotEmpty) {
        try {
          final partialMatch = osPrinters.firstWhere((p) {
            final osName = p.name.toLowerCase();

            // Check if any significant keyword matches
            return keywords.any((keyword) => osName.contains(keyword));
          });

          debugPrint("✅ Found partial match: ${partialMatch.name}");
          return partialMatch;
        } catch (e) {
          debugPrint("⚠️  No partial match found");
        }
      }
    }

    // Method 4: Try URL match (for USB printers)
    if (savedUrl.isNotEmpty && !isNetworkPrinter) {
      try {
        final urlMatch = osPrinters.firstWhere(
          (p) =>
              p.name.toLowerCase() == savedUrl.toLowerCase() ||
              p.url.toLowerCase() == savedUrl.toLowerCase(),
        );
        debugPrint("✅ Found URL match: ${urlMatch.name}");
        return urlMatch;
      } catch (e) {
        debugPrint("⚠️  No URL match found");
      }
    }

    debugPrint("❌ No matching printer found");
    return null;
  }

  /// Check if a string is an IP address
  static bool _isIpAddress(String url) {
    final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    return ipPattern.hasMatch(url);
  }

  /// Extract IP address from URL string
  static String? _extractIpFromUrl(String url) {
    final ipMatch = RegExp(
      r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})',
    ).firstMatch(url);
    return ipMatch?.group(1);
  }

  ///======================================================
  /// Generate KOT PDF
  ///======================================================
  static Future<pw.Document> _generateKotPDF({
    required OrderResponse orderResponse,
  }) async {
    final businessInfo = await BusinessInfoBoxService.getBusinessInfo();
    final order = orderResponse.order;
    final pdf = pw.Document();
    final logo = await getBWLogo(businessInfo?.business.logoUrl);
    final regularFont = await pw.Font.helvetica();
    final boldFont = await pw.Font.helveticaBold();
    final times = await pw.Font.times();
    final safeItems = orderResponse.order?.items ?? [];

    double subtotal = (safeItems).fold(
      0,
      (prev, item) => prev + ((item.quantity ?? 0) * (item.price ?? 0)),
    );
    double totalPrice =
        subtotal +
        (order?.deliveryCharges ?? 0.0) +
        (order?.tax ?? 0.0) -
        (order?.salesDiscount ?? 0.0) -
        (order?.approvedDiscounts ?? 0.0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginTop: 0,
          marginBottom: 5,
          marginLeft: 8,
          marginRight: 20,
        ),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              /// 🔹 KOT Title
              pw.Center(
                child: pw.Text(
                  'KITCHEN ORDER TICKET',
                  style: pw.TextStyle(fontSize: 16, font: boldFont),
                ),
              ),

              pw.SizedBox(height: 5),

              /// 🔹 Order Type
              pw.Center(
                child: pw.Text(
                  order?.orderType ?? 'Eat In',
                  style: pw.TextStyle(fontSize: 14, font: boldFont),
                ),
              ),

              pw.SizedBox(height: 5),

              /// 🔹 Order ID
              pw.Center(
                child: pw.Text(
                  'Order ID: #${order?.id ?? 123}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),

              /// 🔹 Date & Time
              pw.Center(
                child: pw.Text(
                  'Date: ${intl.DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),

              pw.SizedBox(height: 5),
              dottedBorder(),

              /// 🔹 Items Header
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(fontSize: 10, font: boldFont),
                      ),
                    ),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(fontSize: 10, font: boldFont),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 3),

              /// 🔹 Items List (NO PRICE)
              ...safeItems.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 4, top: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item.title ?? '',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Text(
                        'x${item.quantity ?? 0}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 5),
              dottedBorder(),

              /// 🔹 Footer
              pw.Center(
                child: pw.Text(
                  'Please prepare this order',
                  style: pw.TextStyle(fontSize: 9, font: regularFont),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Convert image bytes to black & white (for thermal printer)
  static Uint8List convertToBW(Uint8List inputBytes) {
    final original = img.decodeImage(inputBytes);
    if (original == null) return inputBytes;

    final bw = img.grayscale(original);
    return Uint8List.fromList(img.encodePng(bw));
  }

  static Future<pw.ImageProvider?> getBWLogo(String? url) async {
    if (url == null || url.isEmpty) return null;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final bwBytes = convertToBW(bytes);
        return pw.MemoryImage(bwBytes);
      }
    } catch (e) {
      debugPrint('Failed to load logo: $e');
    }

    return null;
  }

  ///======================================================
  /// Generate Customer Receipt PDF
  ///======================================================
  static Future<pw.Document> _generateReceiptPDF({
    required OrderResponse orderResponse,
  }) async {
    final businessInfo = await BusinessInfoBoxService.getBusinessInfo();
    final order = orderResponse.order;
    final pdf = pw.Document();
    final logo = await getBWLogo(businessInfo?.business.logoUrl);
    final regularFont = await pw.Font.helvetica();
    final boldFont = await pw.Font.helveticaBold();
    final times = await pw.Font.times();
    final safeItems = orderResponse.order?.items ?? [];

    double subtotal = (safeItems).fold(
      0,
      (prev, item) => prev + ((item.quantity ?? 0) * (item.price ?? 0)),
    );
    double totalPrice =
        subtotal +
        (order?.deliveryCharges ?? 0.0) +
        (order?.tax ?? 0.0) -
        (order?.salesDiscount ?? 0.0) -
        (order?.approvedDiscounts ?? 0.0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginTop: 0,
          marginBottom: 5,
          marginLeft: 8,
          marginRight: 20,
        ),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  order?.orderType ?? 'Eatin',
                  style: pw.TextStyle(
                    fontSize: 18,
                    font: regularFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  businessInfo?.business.businessName ?? 'Business Name',
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: regularFont,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Date: ${intl.DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 9, font: times),
                ),
              ),
              pw.SizedBox(height: 5),
              dottedBorder(),
              _labelValue(
                'Payment Type',
                order?.paymentMethod ?? 'Cash',
                regularFont,
              ),
              _labelValue(
                'Order Type',
                order?.orderType ?? 'Eatin',
                regularFont,
              ),
              _labelValue(
                'Customer Name',
                order?.customerName ?? 'Eat in',
                regularFont,
              ),
              if (order?.phoneNumber != null && order?.phoneNumber != '')
                _labelValue(
                  'Contact Number',
                  order?.phoneNumber ?? '',
                  regularFont,
                ),
              dottedBorder(),
              pw.Padding(
                padding: pw.EdgeInsets.only(right: 4.0),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(font: boldFont, fontSize: 9.0),
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Text(
                      'Qty',
                      style: pw.TextStyle(fontSize: 9.0, font: boldFont),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Text(
                      'Price',
                      style: pw.TextStyle(fontSize: 9.0, font: boldFont),
                    ),
                  ],
                ),
              ),
              ...safeItems
                  .map(
                    (item) => pw.Column(
                      children: [
                        pw.SizedBox(height: 5),
                        pw.Padding(
                          padding: pw.EdgeInsets.only(right: 4.0),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  item.title ?? '',
                                  style: pw.TextStyle(fontSize: 9.0),
                                ),
                              ),
                              pw.SizedBox(width: 40),
                              pw.Text(
                                'x${item.quantity ?? 0}',
                                style: pw.TextStyle(fontSize: 9.0),
                              ),
                              pw.SizedBox(width: 40),
                              pw.Text(
                                '£${item.price!.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 9.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
              dottedBorder(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 5),
                  _labelValue(
                    'Subtotal',
                    '£${order?.subTotal?.toStringAsFixed(2)}',
                    regularFont,
                  ),
                  if ((order?.approvedDiscounts ?? 0.0) > 0.0)
                    _labelValue(
                      'Discount',
                      '£${(order?.approvedDiscounts ?? 0.0).toStringAsFixed(2)}',
                      regularFont,
                    ),
                  if ((order?.salesDiscount ?? 0.0) > 0.0)
                    _labelValue(
                      'sale',
                      '-£${order?.salesDiscount!.toStringAsFixed(2)}',
                      regularFont,
                    ),
                  if ((order?.promoDiscount ?? 0.0) > 0.0)
                    _labelValue(
                      'Promo Discount',
                      '-£${order?.promoDiscount!.toStringAsFixed(2)}',
                      regularFont,
                    ),
                  if (orderResponse.type == 'Delivery')
                    _labelValue(
                      'Delivery Charges',
                      '${order?.deliveryCharges?.toStringAsFixed(0)}%',
                      regularFont,
                    ),
                  _labelValue(
                    'Total Price',
                    '£${order?.totalAmount?.toStringAsFixed(2)}',
                    regularFont,
                  ),
                  dottedBorder(),
                  pw.SizedBox(height: 5),
                  _labelFooter(
                    'Email: ${businessInfo?.user.email ?? ''}',
                    regularFont,
                  ),
                  _labelFooter(
                    'Location: ${businessInfo?.business.address ?? ''}',
                    regularFont,
                  ),
                  pw.Center(
                    child: pw.Text(
                      'Thank you for your order!',
                      style: pw.TextStyle(font: regularFont, fontSize: 8),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  ///======================================================
  /// UI Helpers
  ///======================================================
  static pw.Widget dottedBorder() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 2),
      height: 1.1,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.black,
            width: 1,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
    );
  }

  static pw.Widget _itemRow(OrderItem item, pw.Font font) {
    final name = item.title ?? '';
    final qty = item.quantity ?? 0;
    final price = item.price ?? 0;
    final total = (qty * price).toStringAsFixed(2);

    return pw.Padding(
      padding: pw.EdgeInsets.only(right: 4.0),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(name, style: pw.TextStyle(font: font, fontSize: 9)),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              qty.toString(),
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              price.toStringAsFixed(2),
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(
              total,
              style: pw.TextStyle(font: font, fontSize: 9),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _labelValue(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2, right: 4.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, font: font)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, font: font)),
        ],
      ),
    );
  }

  static pw.Widget _labelFooter(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, font: font),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String msg, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    } else {
      debugPrint('⚠️ Snackbar skipped: context not mounted. Message: $msg');
    }
  }
}
