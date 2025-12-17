import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tenx_global_agent/printing_agent/provider/printing_agent_provider.dart';

class PrinterSelectionWidget extends StatelessWidget {
  final bool selectKitchen;
  const PrinterSelectionWidget({super.key, this.selectKitchen = true});

  @override
  Widget build(BuildContext context) => Consumer<PrintingAgentProvider>(
    builder: (context, provider, child) {
      if (provider.isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final available = provider.availablePrinters;
      final customerPrinter = provider.customerPrinter;
      final kotPrinter = provider.kotPrinter;

      // Show warning if no printers available
      if (available.isEmpty) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No cable-connected printers found. Please connect your printer via USB cable.",
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.loadPrinters,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Printers"),
            ),
          ],
        );
      }

      // Build dropdown items from available printers
      final items = [
        const DropdownMenuItem<String>(
          value: null,
          child: Text("Select Printer", style: TextStyle(color: Colors.grey)),
        ),
        ...available.map(
          (p) => DropdownMenuItem(
            value: p.url,
            child: Text(
              "${p.name} • ${p.location}",
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Printer Dropdown
          const Text(
            "Customer Printer",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: customerPrinter?.url,
            items: items,
            onChanged: (url) {
              if (url == null) {
                provider.selectCustomerPrinter(null);
              } else {
                final selectedPrinter = available.firstWhere(
                  (p) => p.url == url,
                );
                provider.selectCustomerPrinter(selectedPrinter);
              }
            },
            hint: const Text("Select Printer"),
          ),
          const SizedBox(height: 16),

          // KOT Printer Dropdown (if enabled)
          if (selectKitchen)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "KOT Printer (Kitchen)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: kotPrinter?.url,
                  items: items,
                  onChanged: (url) {
                    if (url == null) {
                      provider.selectKOTPrinter(null);
                    } else {
                      final selectedPrinter = available.firstWhere(
                        (p) => p.url == url,
                      );
                      provider.selectKOTPrinter(selectedPrinter);
                    }
                  },
                  hint: const Text("Select Printer"),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Refresh Button
          TextButton.icon(
            onPressed: provider.loadPrinters,
            icon: const Icon(Icons.refresh, size: 16, color: Colors.blue),
            label: const Text(
              "Refresh Printers",
              style: TextStyle(color: Colors.blue),
            ),
          ),

          // Show selected printers info
          if (customerPrinter != null || kotPrinter != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selected Printers:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (customerPrinter != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Customer: ${customerPrinter.name}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  if (kotPrinter != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "KOT: ${kotPrinter.name}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
