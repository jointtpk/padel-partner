import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
// import '../../app/controllers/auth_controller.dart';

class SignUpController extends GetxController {
  // ── Step ──────────────────────────────────────────────────────────────────
  final step = 1.obs;

  // ── Step 1 form ───────────────────────────────────────────────────────────
  final nameController    = TextEditingController();
  final phoneController   = TextEditingController();
  final phoneText         = ''.obs;
  final emailController   = TextEditingController();
  final dob               = Rx<DateTime?>(null);

  // ── Step 2 OTP ────────────────────────────────────────────────────────────
  final otpController     = TextEditingController();

  // ── Step 3 profile ────────────────────────────────────────────────────────
  final usernameController = TextEditingController();
  final bioController      = TextEditingController();
  final bioText            = ''.obs;
  final photoPath          = Rx<String?>(null);

  // ── Step 4 tags ───────────────────────────────────────────────────────────
  final tags = <String, String>{}.obs;

  // ── Loading ───────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final errorMsg  = ''.obs;

  // ── Validation ────────────────────────────────────────────────────────────
  bool get step1Valid =>
      nameController.text.trim().length > 1 &&
      dob.value != null &&
      phoneController.text.replaceAll(RegExp(r'[^\d]'), '').length >= 10;

  bool get step2Valid => otpController.text.length == 4;
  bool get step3Valid => usernameController.text.trim().length >= 3;
  bool get step4Valid => tags.length >= 3;

  bool get currentStepValid => switch (step.value) {
        1 => step1Valid,
        2 => step2Valid,
        3 => step3Valid,
        4 => step4Valid,
        _ => false,
      };

  // ── Proceed ───────────────────────────────────────────────────────────────
  Future<void> proceed() async {
    if (!currentStepValid) return;
    errorMsg.value = '';

    if (step.value == 1) {
      // In production: send OTP via AuthController
      // final auth = AuthController.to;
      // await auth.sendOTP(phoneNumber: '+92${phoneController.text}');
      step.value++;
    } else if (step.value == 2) {
      // In production: verify OTP
      // final ok = await AuthController.to.verifyOTP(otpController.text);
      // if (!ok) { errorMsg.value = 'Invalid code'; return; }
      step.value++;
    } else if (step.value < 4) {
      step.value++;
    } else {
      Get.offAllNamed(Routes.home);
    }
  }

  void goBack() {
    if (step.value > 1) {
      step.value--;
    } else {
      Get.back();
    }
  }

  void toggleTag(String key, String value) {
    if (tags[key] == value) {
      tags.remove(key);
    } else {
      tags[key] = value;
    }
  }

  @override
  void onInit() {
    super.onInit();
    phoneText.value = phoneController.text;
    bioText.value = bioController.text;
    phoneController.addListener(() => phoneText.value = phoneController.text);
    bioController.addListener(() => bioText.value = bioController.text);
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    otpController.dispose();
    usernameController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
