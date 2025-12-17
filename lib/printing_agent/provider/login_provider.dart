import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tenx_global_agent/core/constants/app_constant.dart';
import 'package:tenx_global_agent/core/constants/app_url.dart';
import 'package:tenx_global_agent/core/constants/utils.dart';
import 'package:tenx_global_agent/core/services/api_services/base_api_services.dart';
import 'package:tenx_global_agent/core/services/api_services/network_api_services.dart';
import 'package:tenx_global_agent/core/services/hive_services/business_info_service.dart';
import 'package:tenx_global_agent/models/api_response.dart';
import 'package:tenx_global_agent/models/business_info_model.dart';

class LoginProvider extends ChangeNotifier {
  BaseApiServices apiServices = NetworkApiServices();
  // ------------------ CONTROLLERS ------------------
  final email = TextEditingController();
  final password = TextEditingController();
  final apiKey = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // ------------------ STATES ------------------
  int currentStep = 0;
  bool loading = false;
  bool hidePassword = true;
  bool isAuthenticated = false;
  bool isConnected = false;
  bool isListening = false;
  String? authError;
  String listenStatus = "Ready to start";
  int jobCount = 0;

  // ------------------ AUTHENTICATION ------------------
  Future<void> authenticate(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    loading = true;
    authError = null;
    notifyListeners();

    try {
      var res = await apiServices.getPostApiResponse(
        url: AppUrl.authUrl,
        body: jsonEncode({
          "email": email.text.trim(),
          "password": password.text.trim(),
          "api_key": "http://${AppConstants.ip}:8085/print",
        }),
      );
      // -------------------------
      // SHOW SNACKBAR ON ERROR
      // -------------------------
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfullt Authenticate',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      loading = false;
      isAuthenticated = true;
      currentStep = 1;
      notifyListeners();

      print(res);
      // Parse response into BusinessInfoModel
      final businessInfo = BusinessInfoModel.fromJson(res);

      // Store in Hive
      await BusinessInfoBoxService.saveBusinessInfo(businessInfo);
    } catch (e) {
      // email.clear();
      // password.clear();

      loading = false;
      isAuthenticated = false;
      currentStep = 0;
      notifyListeners();

      // -------------------------
      // SHOW SNACKBAR ON ERROR
      // -------------------------
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      print('========================');
      print(e.toString());
    }
  }

  void togglePassword() {
    hidePassword = !hidePassword;
    notifyListeners();
  }

  // ------------------ LISTENER ------------------
  void startListening() {
    isListening = true;
    listenStatus = "Listening for print jobs...";
    notifyListeners();
    _simulateJobs();
  }

  void stopListening() {
    isListening = false;
    listenStatus = "Listener stopped";
    notifyListeners();
  }

  void _simulateJobs() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!isListening) return;

      jobCount++;
      listenStatus = "Job #$jobCount received and printed";
      notifyListeners();

      _simulateJobs();
    });
  }

  // ------------------ PRINTER ------------------
  void completeConnection() {
    isConnected = true;
    currentStep = 2;
    notifyListeners();
  }

  // ------------------ DISPOSE ------------------
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    apiKey.dispose();
    super.dispose();
  }
}
