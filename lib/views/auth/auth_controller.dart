import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final TextEditingController phoneInput = TextEditingController();
  final TextEditingController otpInput = TextEditingController();

  final RxBool isOtpSent = false.obs;
  final RxBool isLoading = false.obs;
  final RxString statusMessage = ''.obs;
  final RxBool isError = false.obs;

  final RxInt resendCountdown = 60.obs;
  Timer? _timer;

  @override
  void onClose() {
    phoneInput.dispose();
    otpInput.dispose();
    _timer?.cancel();
    super.onClose();
  }

  void appendNumber(String digit) {
    if (!isOtpSent.value) {
      if (phoneInput.text.length < 10) {
        phoneInput.text += digit;
      }
    } else {
      if (otpInput.text.length < 6) {
        otpInput.text += digit;
      }
    }
  }

  void deleteNumber() {
    if (!isOtpSent.value) {
      if (phoneInput.text.isNotEmpty) {
        phoneInput.text = phoneInput.text.substring(0, phoneInput.text.length - 1);
      }
    } else {
      if (otpInput.text.isNotEmpty) {
        otpInput.text = otpInput.text.substring(0, otpInput.text.length - 1);
      }
    }
  }

  Future<void> sendOtp() async {
    final phone = phoneInput.text.trim();
    if (phone.length != 10) {
      _showFeedback('Please enter a valid 10-digit mobile number', error: true);
      return;
    }

    isLoading.value = true;
    _showFeedback('Requesting OTP from Jio authorization servers...');

    final success = await _authRepo.requestOtp(phone);
    isLoading.value = false;

    if (success) {
      isOtpSent.value = true;
      _showFeedback('OTP sent successfully to +91 $phone');
      _startCountdown();
    } else {
      _showFeedback('Unable to send OTP. Please verify number or try demo mode.', error: true);
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpInput.text.trim();
    if (otp.length != 6) {
      _showFeedback('Please enter the 6-digit OTP', error: true);
      return;
    }

    isLoading.value = true;
    _showFeedback('Verifying session tokens...');

    final session = await _authRepo.loginWithOtp(phoneInput.text.trim(), otp);
    isLoading.value = false;

    if (session != null && session.isValid) {
      _showFeedback('Authentication successful! Loading live channels...');
      await Future.delayed(const Duration(milliseconds: 600));
      Get.offAllNamed(AppRoutes.home);
    } else {
      _showFeedback('Invalid OTP. Please check the code and try again.', error: true);
    }
  }

  void _startCountdown() {
    resendCountdown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCountdown.value > 0) {
        resendCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _showFeedback(String message, {bool error = false}) {
    statusMessage.value = message;
    isError.value = error;
  }
}

