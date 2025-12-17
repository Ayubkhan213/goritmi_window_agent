// // ignore_for_file: use_build_context_synchronously, avoid_print

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:tenx_global_agent/core/constants/app_constant.dart';
// import 'package:tenx_global_agent/core/constants/utils.dart';
// import 'package:tenx_global_agent/models/business_info_model.dart';
// import 'package:tenx_global_agent/models/order_response_model.dart'
//     show OrderItem, OrderResponse;
// import 'package:tenx_global_agent/printing_agent/provider/login_provider.dart';
// import 'package:tenx_global_agent/printing_agent/provider/printing_agent_provider.dart';
// import 'package:tenx_global_agent/printing_agent/screen/login_screen.dart';
// import 'package:tenx_global_agent/services/recept_preview.dart';
// import 'package:tenx_global_agent/services/recept_printer.dart';

// Future<List<String>> getAllLocalIps() async {
//   List<String> ips = [];
//   try {
//     for (var interface in await NetworkInterface.list()) {
//       for (var addr in interface.addresses) {
//         if (addr.type == InternetAddressType.IPv4 &&
//             !addr.address.startsWith('127')) {
//           ips.add("${interface.name}: ${addr.address}");
//         }
//       }
//     }
//   } catch (e) {
//     print("Error getting local IPs: $e");
//   }
//   return ips;
// }

// Future<String> getLocalIp() async {
//   try {
//     // Prioritize WiFi and Ethernet interfaces
//     final interfaces = await NetworkInterface.list();

//     // First, try to find WiFi or Ethernet
//     for (var interface in interfaces) {
//       final name = interface.name.toLowerCase();
//       if (name.contains('wlan') ||
//           name.contains('wi-fi') ||
//           name.contains('wifi') ||
//           name.contains('en0') ||
//           name.contains('eth')) {
//         for (var addr in interface.addresses) {
//           if (addr.type == InternetAddressType.IPv4 &&
//               !addr.address.startsWith('127') &&
//               !addr.address.startsWith('169.254')) {
//             print("✅ Primary Network IP: ${addr.address} (${interface.name})");
//             return addr.address;
//           }
//         }
//       }
//     }

//     // Fallback: any non-localhost IPv4
//     for (var interface in interfaces) {
//       for (var addr in interface.addresses) {
//         if (addr.type == InternetAddressType.IPv4 &&
//             !addr.address.startsWith('127') &&
//             !addr.address.startsWith('169.254')) {
//           print("⚠️  Using IP: ${addr.address} (${interface.name})");
//           return addr.address;
//         }
//       }
//     }
//   } catch (e) {
//     print("Error getting local IP: $e");
//   }
//   return "0.0.0.0";
// }

// void startLocalServer(BuildContext context) async {
//   try {
//     // Bind to all network interfaces (0.0.0.0) to accept external connections
//     final server = await HttpServer.bind(
//       InternetAddress.anyIPv4,
//       8085,
//       shared: false, // Changed to false for better compatibility
//     );

//     // Set backlog for incoming connections
//     server.autoCompress = true;

//     final localIp = await getLocalIp();
//     final allIps = await getAllLocalIps();

//     print("════════════════════════════════════════");
//     print("🚀 SERVER STARTED SUCCESSFULLY");
//     print("════════════════════════════════════════");
//     print("📍 Local Access:     http://localhost:8085");
//     print("📍 Primary IP:       http://$localIp:8085");
//     print("════════════════════════════════════════");
//     print("🌐 ALL AVAILABLE NETWORK INTERFACES:");
//     for (var ip in allIps) {
//       print("   $ip");
//     }
//     print("════════════════════════════════════════");
//     print("📋 Available Endpoints:");
//     print("   POST http://$localIp:8085/print");
//     print("   GET  http://$localIp:8085/status");
//     print("════════════════════════════════════════");
//     print("⚠️  TROUBLESHOOTING:");
//     print("   1. Use Desktop Agent in Postman (not Cloud)");
//     print("   2. Make sure firewall allows port 8085");
//     print("   3. Both devices on same WiFi network");
//     print("   4. Try pinging: ping $localIp");
//     print("════════════════════════════════════════\n");

//     await for (HttpRequest request in server) {
//       // Enhanced CORS headers for web access
//       request.response.headers.add('Access-Control-Allow-Origin', '*');
//       request.response.headers.add(
//         'Access-Control-Allow-Methods',
//         'GET, POST, PUT, DELETE, OPTIONS',
//       );
//       request.response.headers.add(
//         'Access-Control-Allow-Headers',
//         'Origin, Content-Type, Accept, Authorization, X-Requested-With',
//       );
//       request.response.headers.add('Access-Control-Max-Age', '86400');
//       request.response.headers.add('Content-Type', 'application/json');

//       // Log incoming requests with more details
//       print(
//         "📥 ${request.method} ${request.uri.path} from ${request.connectionInfo?.remoteAddress.address}",
//       );
//       print("   Headers: ${request.headers.value('content-type')}");
//       print("   Origin: ${request.headers.value('origin') ?? 'N/A'}");

//       // Handle CORS preflight requests
//       if (request.method == 'OPTIONS') {
//         print(" CORS preflight passed - waiting for actual request...");
//         request.response
//           ..statusCode = 204
//           ..close();
//         continue;
//       }

//       if (request.method == 'POST' && request.uri.path == '/print') {
//         try {
//           print("📨 Reading request body...");
//           String body = await utf8.decoder.bind(request).join();
//           // print(
//           //   "📦 Body received: ${body.substring(0, body.length > 200 ? 200 : body.length)}...",
//           // );

//           var data = jsonDecode(body);
//           print('==================================');
//           print(data);
//           print('==================================');
//           var res = OrderResponse.fromJson(data);
//           // print('----------------');
//           // Utils.resApiResponse = res;
//           // print(res);
//           // print('----------------------');
//           // print("📄 Print request received: $data");

//           // Validate required fields
//           if (res.order == null) {
//             _sendErrorResponse(
//               request,
//               400,
//               'VALIDATION_ERROR',
//               'Missing required field: order_id',
//             );
//             continue;
//           }

//           String orderId = res.order!.userId.toString();
//           String printType = res.type.toString().toUpperCase();
//           String orderType = data['order_type'] ?? '';
//           List<OrderItem> items = [];

//           if (res.order!.items != null && res.order!.items is List) {
//             items = res.order!.items!;
//           }

//           final provider = Provider.of<PrintingAgentProvider>(
//             context,
//             listen: false,
//           );

//           // ========================================
//           // STEP 1: LOAD PRINTERS BEFORE PRINTING
//           // ========================================
//           // print("🖨️  Loading available printers...");
//           // await provider.loadPrinters();

//           List<String> successMessages = [];
//           List<String> errorMessages = [];
//           bool anyPrintSuccess = false;
//           print('------------------ Printer type ----------------');
//           print(printType);
//           // ========================================
//           // STEP 2: HANDLE KOT PRINTING
//           // ========================================
//           if (printType == 'KOT' || printType == 'BOTH') {
//             // Validate KOT printer
//             // final validKotPrinter = await provider.validatePrinter(
//             //   provider.kotPrinter,
//             // );

//             // if (validKotPrinter == null) {
//             if (provider.kotPrinter == null) {
//               errorMessages.add(
//                 'KOT printer not configured. Please select a KOT printer in settings.',
//               );
//             } else {
//               try {
//                 print('------------------ KOT Printer -------------------');
//                 await ReceiptPrinter.printKOT(
//                   context: context,
//                   orderId: orderId,
//                   orderType: orderType,
//                   items: items,
//                 );
//                 successMessages.add('KOT printed successfully on');
//                 anyPrintSuccess = true;
//                 print("✅ KOT printed successfully");
//               } catch (e) {
//                 errorMessages.add('KOT printing failed: ${e.toString()}');
//                 print("❌ KOT printing failed: $e");
//               }
//               errorMessages.add(
//                 'KOT printer "${provider.kotPrinter!.name}" is not connected. Please check the printer connection.',
//               );
//             }
//           }
//           // else {
//           //   try {
//           //     print('------------------ KOT Printer -------------------');
//           //     await ReceiptDialogPreviewer.showKOTPreview(
//           //       context: context,
//           //       orderId: orderId,
//           //       orderType: orderType,
//           //       items: items,
//           //     );
//           //     successMessages.add('KOT printed successfully on');
//           //     anyPrintSuccess = true;
//           //     print("✅ KOT printed successfully");
//           //   } catch (e) {
//           //     errorMessages.add('KOT printing failed: ${e.toString()}');
//           //     print("❌ KOT printing failed: $e");
//           //   }
//           //   // }
//           // }

//           // ========================================
//           // STEP 3: HANDLE CUSTOMER RECEIPT PRINTING
//           // ========================================
//           if (printType == 'CUSTOMER' || printType == 'BOTH') {
//             // Validate Customer printer
//             // final validCustomerPrinter = await provider.validatePrinter(
//             //   provider.customerPrinter,
//             // );

//             // if (validCustomerPrinter == null) {
//             //   if (provider.customerPrinter == null) {
//             //     errorMessages.add(
//             //       'Customer printer not configured. Please select a customer printer in settings.',
//             //     );
//             //   } else {
//             //     errorMessages.add(
//             //       'Customer printer "${provider.customerPrinter!.name}" is not connected. Please check the printer connection.',
//             //     );
//             //   }
//             // } else {
//             try {
//               print('----------------- Customer Reept ----------------');
//               await ReceiptPrinter.printReceipt(
//                 context: context,
//                 orderResponse: res,
//               );
//               successMessages.add(
//                 'Customer receipt printed successfully on ""',
//               );
//               anyPrintSuccess = true;
//               print("✅ Customer receipt printed successfully");
//             } catch (e) {
//               errorMessages.add(
//                 'Customer receipt printing failed: ${e.toString()}',
//               );
//               print("❌ Customer receipt printing failed: $e");
//             }
//           }
//           // }

//           // ========================================
//           // STEP 4: SEND RESPONSE
//           // ========================================
//           if (anyPrintSuccess) {
//             // Partial or full success
//             if (errorMessages.isEmpty) {
//               _sendSuccessResponse(
//                 request,
//                 200,
//                 'SUCCESS',
//                 'All print jobs completed successfully',
//                 successMessages: successMessages,
//               );
//             } else {
//               _sendPartialSuccessResponse(
//                 request,
//                 207, // Multi-Status
//                 'PARTIAL_SUCCESS',
//                 'Some print jobs completed, but others failed',
//                 successMessages: successMessages,
//                 errorMessages: errorMessages,
//               );
//             }
//           } else {
//             // Complete failure
//             _sendErrorResponse(
//               request,
//               503, // Service Unavailable
//               'PRINTER_ERROR',
//               'No print jobs could be completed',
//               errors: errorMessages,
//             );
//           }
//         } catch (e, stackTrace) {
//           print("❌ Server error: $e");
//           print("Stack trace: $stackTrace");
//           _sendErrorResponse(
//             request,
//             500,
//             'SERVER_ERROR',
//             'An unexpected error occurred while processing the print request',
//             errors: [e.toString()],
//           );
//         }
//       } else if (request.method == 'GET' && request.uri.path == '/status') {
//         // Health check endpoint
//         final provider = Provider.of<PrintingAgentProvider>(
//           context,
//           listen: false,
//         );

//         await provider.loadPrinters();

//         print("✅ Status check completed");

//         request.response
//           ..statusCode = 200
//           ..write(
//             jsonEncode({
//               'status': 'online',
//               'server_ip': await getLocalIp(),
//               'timestamp': DateTime.now().toIso8601String(),
//               'printers': {
//                 'customer': provider.customerPrinter != null
//                     ? {
//                         'name': provider.customerPrinter!.name,
//                         'connected': provider.availablePrinters.any(
//                           (p) => p.url == provider.customerPrinter!.url,
//                         ),
//                       }
//                     : null,
//                 'kot': provider.kotPrinter != null
//                     ? {
//                         'name': provider.kotPrinter!.name,
//                         'connected': provider.availablePrinters.any(
//                           (p) => p.url == provider.kotPrinter!.url,
//                         ),
//                       }
//                     : null,
//               },
//               'available_printers_count': provider.availablePrinters.length,
//             }),
//           )
//           ..close();
//       } else {
//         _sendErrorResponse(
//           request,
//           404,
//           'NOT_FOUND',
//           'Endpoint not found. Available endpoints: POST /print, GET /status',
//         );
//       }
//     }
//   } catch (e, stackTrace) {
//     print("❌ Failed to start server: $e");
//     print("Stack trace: $stackTrace");
//   }
// }

// // ========================================
// // RESPONSE HELPER FUNCTIONS
// // ========================================

// void _sendSuccessResponse(
//   HttpRequest request,
//   int statusCode,
//   String status,
//   String message, {
//   List<String>? successMessages,
// }) {
//   request.response
//     ..statusCode = statusCode
//     ..write(
//       jsonEncode({
//         'status': status,
//         'message': message,
//         'timestamp': DateTime.now().toIso8601String(),
//         if (successMessages != null && successMessages.isNotEmpty)
//           'details': successMessages,
//       }),
//     )
//     ..close();
// }

// void _sendPartialSuccessResponse(
//   HttpRequest request,
//   int statusCode,
//   String status,
//   String message, {
//   List<String>? successMessages,
//   List<String>? errorMessages,
// }) {
//   request.response
//     ..statusCode = statusCode
//     ..write(
//       jsonEncode({
//         'status': status,
//         'message': message,
//         'timestamp': DateTime.now().toIso8601String(),
//         if (successMessages != null && successMessages.isNotEmpty)
//           'successful': successMessages,
//         if (errorMessages != null && errorMessages.isNotEmpty)
//           'errors': errorMessages,
//       }),
//     )
//     ..close();
// }

// void _sendErrorResponse(
//   HttpRequest request,
//   int statusCode,
//   String errorCode,
//   String message, {
//   List<String>? errors,
// }) {
//   request.response
//     ..statusCode = statusCode
//     ..write(
//       jsonEncode({
//         'status': 'ERROR',
//         'error_code': errorCode,
//         'message': message,
//         'timestamp': DateTime.now().toIso8601String(),
//         if (errors != null && errors.isNotEmpty) 'errors': errors,
//       }),
//     )
//     ..close();
// }

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final ip = await getLocalIp();
//   AppConstants.ip = ip;
//   print("MY IP: $ip");

//   // Initialize Hive
//   final directory = await getApplicationDocumentsDirectory();
//   Hive.init(directory.path);
//   // Register all Hive adapters
//   Hive.registerAdapter(BusinessInfoModelAdapter());
//   Hive.registerAdapter(UserAdapter());
//   Hive.registerAdapter(BusinessAdapter());
//   // Open with type
//   await Hive.openBox<BusinessInfoModel>('businessInfo');
//   await Hive.openBox('printerBox');

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => LoginProvider()),
//         ChangeNotifierProvider(create: (_) => PrintingAgentProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );

//   // Start server after app is ready
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     final context = MyApp.navigatorKey.currentContext;
//     if (context != null) {
//       startLocalServer(context);
//     }
//   });
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   static final navigatorKey = GlobalKey<NavigatorState>();

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       debugShowCheckedModeBanner: false,
//       home: LoginScreen(),
//     );
//   }
// }
