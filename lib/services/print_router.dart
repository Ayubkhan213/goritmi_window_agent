import 'package:flutter/material.dart';
import 'package:tenx_global_agent/models/order_response_model.dart';
import 'package:provider/provider.dart';
import 'package:tenx_global_agent/services/recept_printer.dart';
import 'package:tenx_global_agent/services/recept_printer_cable.dart';
import '../printing_agent/provider/printing_agent_provider.dart';

/// Printer Type Router
/// Automatically detects printer connection type and routes to appropriate class
class PrinterRouter {
  /// Print KOT - Auto-detect printer type
  static Future<void> printKOT({
    required BuildContext context,
    required String orderId,
    String orderType = '',
    List<OrderItem>? items,
  }) async {
    final provider = Provider.of<PrintingAgentProvider>(context, listen: false);

    if (provider.kotPrinter == null) {
      throw Exception("KOT printer is not configured");
    }

    // Detect printer type
    final printerType = _detectPrinterType(provider.kotPrinter!.url);

    debugPrint('🔍 KOT Printer Type Detected: $printerType');
    debugPrint('   Printer: ${provider.kotPrinter!.name}');
    debugPrint('   URL: ${provider.kotPrinter!.url}');

    if (printerType == PrinterConnectionType.lan) {
      // Use LAN/Network printer class
      debugPrint('📡 Routing to ReceiptPrinter (LAN)');
      await ReceiptPrinter.printKOT(
        context: context,
        orderId: orderId,
        orderType: orderType,
        items: items,
      );
    } else {
      // Use Cable/USB printer class
      debugPrint('🔌 Routing to ReceiptPrintercable (USB/Cable)');

      // Convert to OrderResponse format for cable printer
      final orderResponse = _createOrderResponse(
        orderId: orderId,
        orderType: orderType,
        items: items,
      );

      await ReceiptPrintercable.printKOT(
        context: context,
        orderResponse: orderResponse,
      );
    }
  }

  /// Print Customer Receipt - Auto-detect printer type
  static Future<void> printReceipt({
    required BuildContext context,
    required OrderResponse orderResponse,
  }) async {
    final provider = Provider.of<PrintingAgentProvider>(context, listen: false);

    if (provider.customerPrinter == null) {
      throw Exception("Customer printer is not configured");
    }

    // Detect printer type
    final printerType = _detectPrinterType(provider.customerPrinter!.url);

    debugPrint('🔍 Customer Printer Type Detected: $printerType');
    debugPrint('   Printer: ${provider.customerPrinter!.name}');
    debugPrint('   URL: ${provider.customerPrinter!.url}');

    if (printerType == PrinterConnectionType.lan) {
      // Use LAN/Network printer class
      debugPrint('📡 Routing to ReceiptPrinter (LAN)');
      await ReceiptPrinter.printReceipt(
        context: context,
        orderResponse: orderResponse,
      );
    } else {
      // Use Cable/USB printer class
      debugPrint('🔌 Routing to ReceiptPrintercable (USB/Cable)');
      await ReceiptPrintercable.printReceipt(
        context: context,
        orderResponse: orderResponse,
      );
    }
  }

  /// ========================================
  /// PRINTER TYPE DETECTION LOGIC
  /// ========================================
  static PrinterConnectionType _detectPrinterType(String url) {
    final cleanUrl = url.trim().toLowerCase();

    // Method 1: Check for IP address pattern (LAN printer)
    final ipPattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}');
    if (ipPattern.hasMatch(cleanUrl)) {
      return PrinterConnectionType.lan;
    }

    // Method 2: Check for port number (LAN printer)
    if (cleanUrl.contains(':')) {
      final parts = cleanUrl.split(':');
      if (parts.length == 2) {
        final port = int.tryParse(parts[1]);
        if (port != null && port > 0) {
          // Has valid port number = LAN printer
          return PrinterConnectionType.lan;
        }
      }
    }

    // Method 3: Check for localhost/127.0.0.1
    if (cleanUrl.contains('localhost') || cleanUrl.contains('127.0.0.1')) {
      return PrinterConnectionType.lan;
    }

    // Method 4: Check URL protocol
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return PrinterConnectionType.lan;
    }

    // Method 5: Check for network keywords
    final networkKeywords = [
      'network',
      'lan',
      'ethernet',
      'wifi',
      'wireless',
      'tcp',
      'ip',
    ];

    if (networkKeywords.any((keyword) => cleanUrl.contains(keyword))) {
      return PrinterConnectionType.lan;
    }

    // Method 6: Check for USB/Cable keywords
    final cableKeywords = [
      'usb',
      'cable',
      'local',
      'direct',
      'serial',
      'com',
      'lpt',
    ];

    if (cableKeywords.any((keyword) => cleanUrl.contains(keyword))) {
      return PrinterConnectionType.cable;
    }

    // Default: If URL looks like a printer name without IP/port = Cable printer
    if (!cleanUrl.contains('.') && !cleanUrl.contains(':')) {
      return PrinterConnectionType.cable;
    }

    // Fallback: Default to Cable if uncertain
    return PrinterConnectionType.cable;
  }

  /// Helper: Create OrderResponse from KOT data
  static OrderResponse _createOrderResponse({
    required String orderId,
    String orderType = '',
    List<OrderItem>? items,
  }) {
    return OrderResponse(
      order: OrderData(
        id: int.tryParse(orderId) ?? 0,
        orderType: orderType.isNotEmpty ? orderType : 'Eat In',
        items: items ?? [],
        customerName: 'Eat in',
        paymentMethod: 'Cash',
        subTotal: 0,
        totalAmount: 0,
      ),
      type: orderType.toUpperCase(),
    );
  }
}

/// Enum for printer connection types
enum PrinterConnectionType {
  lan, // Network/LAN printer (uses IP:port)
  cable, // USB/Cable printer (uses printer name)
}
