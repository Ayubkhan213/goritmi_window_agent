import 'dart:convert';
import 'dart:io';

import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:tenx_global_agent/models/printer_model.dart';

// lib/models/print_job.dart
class PrintJob {
  final String ip;
  final int port;
  final String text;

  PrintJob({required this.ip, required this.port, required this.text});
}

class PrintingAgentProvider extends ChangeNotifier {
  final List<PrintJob> _queue = [];

  // Priority IPs for LAN printers - only these will be shown
  // Only the last octet is checked (e.g., 192.168.1.200 -> 200)
  static const List<int> priorityIPs = [200, 100, 192, 201, 254, 1, 150, 50];

  void enqueuePrintJob(PrintJob job) {
    _queue.add(job);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty) return;
    final job = _queue.removeAt(0);

    try {
      final printer = NetworkPrinter(
        PaperSize.mm80,
        await CapabilityProfile.load(name: 'default'),
      );
      final result = await printer.connect(job.ip, port: job.port);
      if (result == PosPrintResult.success) {
        printer.text(
          job.text,
          styles: PosStyles(align: PosAlign.center, bold: true),
        );
        printer.cut();
        printer.disconnect();
      }
    } catch (e) {
      print("❌ Failed to print: $e");
    }
  }

  // State - NO HIVE, only in-memory
  bool isLoading = false;
  List<Printer> availablePrinters = []; // Discovered printers
  Printer? customerPrinter; // Selected customer printer
  Printer? kotPrinter; // Selected KOT printer

  // Load available printers (discovery only)
  Future<void> loadPrinters() async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint("🔍 Loading connected printers (WiFi + Cable)...");

      // Get network info for LAN printer detection
      final networkInfo = NetworkInfo();
      String? wifiIP;
      String? subnet;

      try {
        wifiIP = await networkInfo.getWifiIP();
        if (wifiIP != null && wifiIP.isNotEmpty) {
          // Extract subnet from IP (e.g., 192.168.1.100 -> 192.168.1)
          final parts = wifiIP.split('.');
          if (parts.length == 4) {
            subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
            debugPrint("📡 WiFi IP: $wifiIP");
            debugPrint("📡 Subnet: $subnet");
          }
        }
      } catch (e) {
        debugPrint("⚠️ Could not get WiFi info: $e");
      }

      // Fetch printers from Windows
      final List<dynamic> terminalPrinters = await getConnectedPrinters();
      debugPrint("✅ Found ${terminalPrinters.length} printers from Windows");

      // If we have network info, scan for LAN printers
      List<Printer> networkPrinters = [];
      if (subnet != null) {
        debugPrint("🔍 Scanning network for LAN printers on $subnet.x...");
        networkPrinters = await _scanForNetworkPrinters(subnet);
        debugPrint(
          "✅ Found ${networkPrinters.length} LAN printers via network scan",
        );
      }

      // Filter Windows printers
      debugPrint("🔍 Starting Dart-side filtering...");
      final List<Printer> livePrinters = terminalPrinters
          .where((t) {
            final connectionType = t['ConnectionType'] ?? '';
            final ipAddress = t['IPAddress']?.toString() ?? '';
            final printerName = t['Name'] ?? '';
            final portName = t['PortName'] ?? '';
            final isConnected = t['IsConnected'] ?? false;

            debugPrint("🔍 Checking: $printerName");
            debugPrint("   ConnectionType: $connectionType");
            debugPrint("   IPAddress: $ipAddress");
            debugPrint("   PortName: $portName");
            debugPrint("   IsConnected: $isConnected");

            // Only show printers that are actually connected/online
            if (!isConnected) {
              debugPrint("   ❌ Skipping - Printer is not connected/online");
              return false;
            }

            // If it's a Network/WiFi printer, apply priority IP checks
            if (connectionType == 'Network/WiFi') {
              debugPrint("   📡 Detected as Network/WiFi printer");

              // Reject invalid IPs or "unknown"
              if (ipAddress.isEmpty ||
                  ipAddress == '0.0.0.0' ||
                  ipAddress == 'unknown') {
                debugPrint(
                  "   ❌ Skipping - Invalid IP address ($ipAddress). Printer may be offline.",
                );
                return false;
              }

              // Extract last octet from IP (e.g., 192.168.1.200 -> 200)
              final lastOctet = _extractLastOctet(ipAddress);
              debugPrint("   Last octet: $lastOctet");
              debugPrint("   Priority IPs: $priorityIPs");

              if (lastOctet == null || !priorityIPs.contains(lastOctet)) {
                debugPrint(
                  "   ❌ Skipping - IP $ipAddress (last octet: $lastOctet) not in priority list",
                );
                return false;
              }

              debugPrint(
                "   ✅ Including - IP $ipAddress (last octet: $lastOctet) is in priority list",
              );
              return true;
            }

            // For cable printers (USB/LPT/COM), always include if connected
            debugPrint("   🔌 Including - Cable printer ($connectionType)");
            return true;
          })
          .map(
            (t) => Printer(
              name: t['Name'] ?? '',
              url: t['IPAddress'] ?? t['Name'] ?? '',
              location: t['PortName'] ?? '',
              model: t['DriverName'] ?? '',
              isDefault: t['Default'] == true,
              isAvailable: (t['PrinterStatus'] ?? 0) == 0,
            ),
          )
          .toList();

      // Combine Windows printers and network-scanned printers
      // Remove duplicates based on IP/name
      final allPrinters = <Printer>[...livePrinters];
      for (final networkPrinter in networkPrinters) {
        final isDuplicate = allPrinters.any(
          (p) => p.url == networkPrinter.url || p.name == networkPrinter.name,
        );
        if (!isDuplicate) {
          allPrinters.add(networkPrinter);
        }
      }

      // Update available printers list
      availablePrinters = allPrinters;

      // Clear selections if previously selected printers are no longer available
      if (customerPrinter != null) {
        final stillExists = availablePrinters.any(
          (p) =>
              p.url == customerPrinter!.url && p.name == customerPrinter!.name,
        );
        if (!stillExists) {
          debugPrint(
            "⚠️ Previously selected customer printer no longer available",
          );
          customerPrinter = null;
        }
      }

      if (kotPrinter != null) {
        final stillExists = availablePrinters.any(
          (p) => p.url == kotPrinter!.url && p.name == kotPrinter!.name,
        );
        if (!stillExists) {
          debugPrint("⚠️ Previously selected KOT printer no longer available");
          kotPrinter = null;
        }
      }

      debugPrint("✅ Printer loading complete");
      debugPrint("   - Available printers: ${availablePrinters.length}");
      debugPrint("   - Customer: ${customerPrinter?.name ?? 'Not selected'}");
      debugPrint("   - KOT: ${kotPrinter?.name ?? 'Not selected'}");
    } catch (e) {
      debugPrint("❌ Error loading printers: $e");
      availablePrinters = [];
      customerPrinter = null;
      kotPrinter = null;
    }

    isLoading = false;
    notifyListeners();
  }

  // Select customer printer from available printers
  void selectCustomerPrinter(Printer? printer) {
    customerPrinter = printer;
    debugPrint(
      printer == null
          ? "🗑️ Customer printer selection cleared"
          : "✅ Customer printer selected: ${printer.name} (${printer.url})",
    );
    notifyListeners();
  }

  // Select KOT printer from available printers
  void selectKOTPrinter(Printer? printer) {
    kotPrinter = printer;
    debugPrint(
      printer == null
          ? "🗑️ KOT printer selection cleared"
          : "✅ KOT printer selected: ${printer.name} (${printer.url})",
    );
    notifyListeners();
  }

  /// Get ONLY physically connected printers (WiFi/LAN + Cable)
  /// Excludes printers that are installed but not connected
  Future<List<dynamic>> getConnectedPrinters() async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-Command',
      r'''
    # Get all installed printers
    $allPrinters = Get-Printer -ErrorAction SilentlyContinue
    if (-not $allPrinters) {
        "[]"
        exit
    }

    $usbDevices = Get-WmiObject -Class Win32_PnPEntity -Filter "DeviceID LIKE '%USB%' AND Status='OK'" -ErrorAction SilentlyContinue
    $allPrintersWMI = Get-WmiObject -Class Win32_Printer -ErrorAction SilentlyContinue
    $activePrinters = @()

    foreach ($printer in $allPrinters) {
      $port = $printer.PortName
      $printerName = $printer.Name

      # Skip ONLY these specific virtual printers
      if ($printerName -match 'Microsoft XPS|Microsoft Print to PDF|OneNote|Fax|Send To OneNote') { 
        continue 
      }

      $connected = $false
      $ipAddress = $null
      $connectionType = "Unknown"

      # Check USB/Cable printers
      if ($port -match '^(USB|USBPRINT|DOT4)') {
        $connectionType = "USB/Cable"
        
        # Check if USB device exists
        $usbMatch = $usbDevices | Where-Object { 
          ($_.Name -like "*print*" -or 
           $_.Name -like "*$printerName*" -or 
           $_.DeviceID -like "*PRINT*" -or
           $_.Name -eq "USB Printing Support" -or 
           $_.Name -like "*80Series*" -or
           $_.Name -like "*Xprinter*" -or
           $_.Name -like "*BlackCopper*")
        } | Select-Object -First 1
        
        if ($usbMatch) {
          $printerStatus = $allPrintersWMI | Where-Object { $_.Name -eq $printerName }
          $hasGoodStatus = $printerStatus -and ($printerStatus.PrinterStatus -eq 0 -or $printerStatus.PrinterStatus -eq 3)
          $connected = $hasGoodStatus
        }
      }
      # Check LPT (Parallel) printers
      elseif ($port -match '^LPT') {
        $connectionType = "LPT/Parallel"
        $printerStatus = $allPrintersWMI | Where-Object { $_.Name -eq $printerName }
        $connected = $printerStatus -and ($printerStatus.PrinterStatus -eq 0 -or $printerStatus.PrinterStatus -eq 3)
      }
      # Check COM (Serial) printers
      elseif ($port -match '^COM') {
        $connectionType = "COM/Serial"
        $connected = $printer.PrinterStatus -eq 0
      }
      # Check ALL network printers - broader detection
      else {
        # This catches TCP/IP, WSD, and all other network printers
        $connectionType = "Network/WiFi"
        
        # Try to get IP from printer port
        $tcpPort = Get-PrinterPort -Name $port -ErrorAction SilentlyContinue
        
        if ($tcpPort) {
          # Try PrinterHostAddress first
          if ($tcpPort.PrinterHostAddress -and $tcpPort.PrinterHostAddress -ne "0.0.0.0") {
            $ipAddress = $tcpPort.PrinterHostAddress
          }
          # Try PortNumber (might contain IP)
          elseif ($tcpPort.PortNumber -and $tcpPort.PortNumber -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
            $ipAddress = $matches[1]
          }
        }
        
        # Try to extract IP from port name
        if (-not $ipAddress -or $ipAddress -eq "0.0.0.0") {
          if ($port -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
            $ipAddress = $matches[1]
          }
        }
        
        # For network printers with valid IP - MUST ping successfully
        if ($ipAddress -and $ipAddress -ne "0.0.0.0") {
          # Try ping - REQUIRED for network printers
          $pingResult = Test-Connection -ComputerName $ipAddress -Count 1 -TimeoutSeconds 2 -Quiet -ErrorAction SilentlyContinue
          
          if ($pingResult) {
            # Ping successful - printer is ONLINE
            $connected = $true
          } else {
            # Ping failed - printer is OFFLINE, do NOT include
            $connected = $false
            $ipAddress = $null
          }
        } else {
          # No valid IP detected - skip this network printer
          $connected = $false
          $ipAddress = $null
        }
      }

      # Include thermal printers by name (common POS printer names)
      $isThermalPrinter = $printerName -match 'xprinter|xp-|thermal|pos|receipt|80mm|58mm|BlackCopper|Rongta|HPRT|Epson TM|Star TSP'
      $isCablePrinter = $connectionType -match 'USB|LPT|COM'
      
      # Add printer if connected OR if it's a known thermal printer on cable
      if ($connected -or ($isThermalPrinter -and $isCablePrinter)) {
        $printerObj = $printer | Select-Object Name, DriverName, PortName, PrinterStatus, Default
        $printerObj | Add-Member -NotePropertyName 'IPAddress' -NotePropertyValue $ipAddress
        $printerObj | Add-Member -NotePropertyName 'ConnectionType' -NotePropertyValue $connectionType
        $printerObj | Add-Member -NotePropertyName 'IsConnected' -NotePropertyValue $connected
        $activePrinters += $printerObj
      }
    }

    if ($activePrinters.Count -eq 0) { 
      "[]" 
    }
    else { 
      $activePrinters | ConvertTo-Json -Depth 3
    }
    ''',
    ]);

    if (result.exitCode != 0) {
      debugPrint("❌ PowerShell Error: ${result.stderr}");
      return [];
    }

    final output = result.stdout?.toString().trim();
    if (output == null || output.isEmpty || output == '[]') {
      debugPrint("ℹ️ No connected printers found");
      return [];
    }

    try {
      final decoded = jsonDecode(output);
      final printers = decoded is List ? decoded : [decoded];

      // Log ALL printers returned from PowerShell
      debugPrint("📋 Raw Printers from PowerShell: ${printers.length}");
      for (var printer in printers) {
        final isConnected = printer['IsConnected'] ?? false;
        final connectionType = printer['ConnectionType'] ?? 'Unknown';
        final status = isConnected ? '✅ ONLINE' : '⚠️ DETECTED';
        debugPrint(
          "$status ${printer['Name']} - Type: $connectionType - Port: ${printer['PortName']} - Status: ${printer['PrinterStatus']}",
        );
        if (printer['IPAddress'] != null) {
          debugPrint("   IP: ${printer['IPAddress']}");
        } else {
          debugPrint("   IP: (none)");
        }
      }

      return printers;
    } catch (e) {
      debugPrint("❌ JSON decode error: $e");
      return [];
    }
  }

  /// Scan local network for thermal printers using network_info_plus
  Future<List<Printer>> _scanForNetworkPrinters(String subnet) async {
    List<Printer> foundPrinters = [];
    List<Future> scanTasks = [];

    // Scan only priority IPs to save time
    for (int lastOctet in priorityIPs) {
      final ip = '$subnet.$lastOctet';

      scanTasks.add(
        _checkPrinterAtIP(ip, 9100).then((isAvailable) async {
          if (isAvailable) {
            // Printer found! Try to get more info
            String printerName = 'Network Printer';

            // Try to identify printer type by probing
            try {
              final socket = await Socket.connect(
                ip,
                9100,
                timeout: Duration(milliseconds: 500),
              );

              // Send ESC/POS status request
              socket.add([0x10, 0x04, 0x01]); // DLE EOT n (printer status)
              await Future.delayed(Duration(milliseconds: 200));

              // Some basic identification
              if (ip.endsWith('.200')) {
                printerName = 'Thermal Printer (.$lastOctet)';
              } else {
                printerName = 'Network Printer (.$lastOctet)';
              }

              await socket.close();
            } catch (e) {
              printerName = 'Network Printer (.$lastOctet)';
            }

            foundPrinters.add(
              Printer(
                name: printerName,
                url: ip,
                location: 'Network ($ip:9100)',
                model: 'ESC/POS Thermal',
                isDefault: false,
                isAvailable: true,
              ),
            );

            debugPrint("✅ Found LAN printer at $ip:9100");
          }
        }),
      );

      // Process in batches to avoid overwhelming the network
      if (scanTasks.length >= 10) {
        await Future.wait(scanTasks);
        scanTasks.clear();
      }
    }

    if (scanTasks.isNotEmpty) {
      await Future.wait(scanTasks);
    }

    return foundPrinters;
  }

  /// Check if a printer is available at given IP and port
  Future<bool> _checkPrinterAtIP(String ip, int port) async {
    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: Duration(milliseconds: 500),
      );
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extract the last octet from an IP address
  /// Example: "192.168.1.200" returns 200
  int? _extractLastOctet(String ipAddress) {
    try {
      final parts = ipAddress.split('.');
      if (parts.length == 4) {
        return int.tryParse(parts[3]);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error extracting last octet from $ipAddress: $e");
      return null;
    }
  }
}

 // // Get live printers from Windows terminal using PowerShell
  // Future<List<dynamic>> getLiveTerminalPrinters() async {
  //   final result = await Process.run('powershell', [
  //     '-NoProfile',
  //     '-NonInteractive',
  //     '-ExecutionPolicy',
  //     'Bypass',
  //     '-Command',
  //     r'''
  //     $allPrinters   = Get-Printer
  //     $allPnP        = Get-WmiObject -Class Win32_PnPEntity
  //     $allPrintersWMI= Get-WmiObject -Class Win32_Printer

  //     $activePrinters = @()

  //     foreach ($printer in $allPrinters) {
  //       $port = $printer.PortName
  //       $name = $printer.Name

  //       $isCableConnection = (
  //         $port -match '^USB' -or
  //         $port -match '^LPT' -or
  //         $port -match '^COM' -or
  //         $port -match 'DOT4' -or
  //         $port -match '^USBPRINT'
  //       )

  //       $isNotVirtual = $port -notmatch 'PORTPROMPT|nul:|XPS|OneNote|Fax|PDF|IP_|192\.|10\.|172\.'

  //       if ($isCableConnection -and $isNotVirtual) {
  //         $isPhysicallyConnected = $false

  //         if ($port -match '^USB') {
  //           $usbDevices = $allPnP | Where-Object {
  //             $_.DeviceID -like "*USB*" -and
  //             $_.Status -eq "OK" -and
  //             ($_.Name -like "*print*" -or $_.Name -like "*$name*" -or $_.DeviceID -like "*PRINT*" -or
  //              $_.Name -eq "USB Printing Support" -or $_.Name -like "*80Series*")
  //           }
  //           $isPhysicallyConnected = $usbDevices.Count -gt 0
  //         }
  //         elseif ($port -match '^LPT') {
  //           $isPhysicallyConnected = $true
  //         }
  //         else {
  //           $isPhysicallyConnected = $printer.PrinterStatus -eq 0
  //         }

  //         try {
  //           $printerStatus = $allPrintersWMI | Where-Object { $_.Name -eq $name }
  //           $hasGoodStatus = $printerStatus -and ($printerStatus.PrinterStatus -eq 0 -or $printerStatus.PrinterStatus -eq 3)
  //         } catch {
  //           $hasGoodStatus = $false
  //         }

  //         if ($isPhysicallyConnected -and $hasGoodStatus) {
  //           $activePrinters += $printer
  //         }
  //       }
  //     }

  //     if ($activePrinters.Count -eq 0) {
  //       "[]"
  //     } else {
  //       $activePrinters | Select-Object Name,DriverName,PortName,PrinterStatus,Default | ConvertTo-Json
  //     }
  //     ''',
  //   ]);

  //   if (result.exitCode != 0) {
  //     debugPrint("PowerShell Error: ${result.stderr}");
  //     return [];
  //   }

  //   final output = result.stdout?.toString().trim();
  //   if (output == null || output.isEmpty) return [];

  //   try {
  //     final decoded = jsonDecode(output);
  //     if (decoded is List) return decoded;
  //     if (decoded is Map) return [decoded];
  //     return [];
  //   } catch (e) {
  //     debugPrint("JSON decode error: $e");
  //     debugPrint("Attempted to decode: $output");
  //     return [];
  //   }
  // }
