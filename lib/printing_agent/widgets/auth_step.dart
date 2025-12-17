import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tenx_global_agent/printing_agent/provider/login_provider.dart';
import 'package:tenx_global_agent/printing_agent/widgets/custom_text_field.dart';

class AuthStep extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController apiKeyController;
  final bool loading;
  final bool authenticated;
  final String? authError;

  final InputDecoration Function(String label, IconData icon)?
  decorationBuilder;

  const AuthStep({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.apiKeyController,
    required this.loading,
    required this.authenticated,
    required this.authError,

    this.decorationBuilder,
  });

  @override
  State<AuthStep> createState() => _AuthStepState();
}

class _AuthStepState extends State<AuthStep> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: Provider.of<LoginProvider>(context, listen: false).formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Enter your credentials",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 30),

          // Username
          FormTextField(
            controller: widget.usernameController,
            label: "Email",
            icon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return "Please enter your email";
              }

              // Simple email pattern
              final emailRegExp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

              if (!emailRegExp.hasMatch(v.trim())) {
                return "Please enter a valid email";
              }

              return null;
            },
          ),
          const SizedBox(height: 5),

          // Password
          Consumer<LoginProvider>(
            builder: (context, authProvider, _) {
              return FormTextField(
                controller: widget.passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                obscureText: authProvider.hidePassword,
                validator: (v) => v!.isEmpty ? "Enter password" : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    authProvider.hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: authProvider.togglePassword,
                ),
              );
            },
          ),
          const SizedBox(height: 5),

          // // API Key
          // FormTextField(
          //   controller: widget.apiKeyController,
          //   label: "API Key",
          //   icon: Icons.vpn_key_outlined,
          //   validator: (v) => v!.isEmpty ? "Enter API key" : null,
          // ),

          // Error message
          if (widget.authError != null) ...[
            const SizedBox(height: 16),
            _errorBox(widget.authError!),
          ],

          // Success message
          if (widget.authenticated) ...[
            const SizedBox(height: 16),
            _successBox("Authentication successful"),
          ],

          const SizedBox(height: 30),

          Consumer<LoginProvider>(
            builder: (context, authProvider, _) {
              return ElevatedButton(
                onPressed: authProvider.loading
                    ? null
                    : () {
                        authProvider.authenticate(context);
                      },
                style: _btnStyle(),
                child: authProvider.loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Text(
                        "Authenticate",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1976D2),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
  // You can move these outside if you have common widgets
  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800)),
    );
  }

  Widget _successBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(message, style: TextStyle(color: Colors.green.shade800)),
    );
  }
}
