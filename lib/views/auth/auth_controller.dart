import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();

  final RxString phoneNumber = ''.obs;
  final RxString otpCode = ''.obs;

  final RxBool isOtpSent = false.obs;
  final RxBool isLoading = false.obs;
  final RxString statusMessage = ''.obs;
  final RxBool isError = false.obs;

  final RxInt resendCountdown = 60.obs;
  Timer? _timer;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void appendNumber(String digit) {
    if (!isOtpSent.value) {
      if (phoneNumber.value.length < 10) {
        phoneNumber.value += digit;
      }
    } else {
      if (otpCode.value.length < 6) {
        otpCode.value += digit;
      }
    }
  }

  void deleteNumber() {
    if (!isOtpSent.value) {
      if (phoneNumber.value.isNotEmpty) {
        phoneNumber.value = phoneNumber.value.substring(0, phoneNumber.value.length - 1);
      }
    } else {
      if (otpCode.value.isNotEmpty) {
        otpCode.value = otpCode.value.substring(0, otpCode.value.length - 1);
      }
    }
  }

  void clearInput() {
    if (!isOtpSent.value) {
      phoneNumber.value = '';
    } else {
      otpCode.value = '';
    }
  }

  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final digitMap = {
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad9: '9',
    };

    if (digitMap.containsKey(key)) {
      appendNumber(digitMap[key]!);
    } else if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      deleteNumber();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (!isLoading.value) {
        if (isOtpSent.value) {
          verifyOtp();
        } else {
          sendOtp();
        }
      }
    }
  }

  Future<void> sendOtp() async {
    final phone = phoneNumber.value.trim();
    if (phone.length != 10) {
      _showFeedback('Please enter a valid 10-digit Jio mobile number', error: true);
      return;
    }

    isLoading.value = true;
    _showFeedback('Sending OTP to your Jio number...');

    final success = await _authRepo.requestOtp(phone);
    isLoading.value = false;

    if (success) {
      isOtpSent.value = true;
      _showFeedback('Verification OTP sent to +91 $phone');
      _startCountdown();
    } else {
      _showFeedback('Unable to send OTP. Please check your Jio number and try again.', error: true);
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpCode.value.trim();
    if (otp.length != 6) {
      _showFeedback('Please enter the 6-digit verification code', error: true);
      return;
    }

    isLoading.value = true;
    _showFeedback('Verifying OTP with Jio servers...');

    final session = await _authRepo.loginWithOtp(phoneNumber.value.trim(), otp);
    isLoading.value = false;

    if (session != null && session.isValid) {
      if (Get.isRegistered<ChannelRepository>()) {
        Get.find<ChannelRepository>().clearCache();
      }
      _showFeedback('Verification successful! Welcome to PrismTV.');
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed(AppRoutes.splash);
    } else {
      _showFeedback('Invalid OTP. Please check the code and try again.', error: true);
    }
  }

  void changeNumber() {
    isOtpSent.value = false;
    otpCode.value = '';
    _timer?.cancel();
    _showFeedback('');
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
