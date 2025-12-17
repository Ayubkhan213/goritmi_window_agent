import 'package:flutter/material.dart';

class StepProgressRow extends StatelessWidget {
  final int currentStep;
  final bool authenticated;
  final bool connected;
  final bool listening;

  const StepProgressRow({
    super.key,
    required this.currentStep,
    required this.authenticated,
    required this.connected,
    required this.listening,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepItem(1, "Authentication", currentStep == 0, authenticated),
        _line(currentStep > 0),
        _stepItem(2, "Printer Connection", currentStep == 1, connected),
      ],
    );
  }

  Widget _stepItem(int number, String title, bool active, bool done) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: done
              ? Colors.green
              : active
              ? const Color(0xFF1976D2)
              : Colors.grey.shade300,
          child: done
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  "$number",
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey.shade600,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: active ? Colors.blue : Colors.grey.shade600,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _line(bool active) => Container(
    width: 70,
    height: 3,
    color: active ? Colors.green : Colors.grey.shade300,
    margin: const EdgeInsets.only(bottom: 50),
  );
}
