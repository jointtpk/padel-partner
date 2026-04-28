import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart';
import '../../core/mock_data.dart';
import '../../core/models/player.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/email_otp_service.dart';
import '../../core/services/user_storage.dart';

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
  final otpText           = ''.obs;
  String _expectedCode    = '';
  DateTime? _codeIssuedAt;

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

  /// True when the email entered at step 1 already maps to a known
  /// profile in the local registry. After OTP verification we skip the
  /// remaining sign-up steps and restore that profile straight to home,
  /// so the same email always lands on the same identity.
  Player? _returningUser;

  // ── Validation ────────────────────────────────────────────────────────────
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get step1Valid =>
      nameController.text.trim().length > 1 &&
      dob.value != null &&
      phoneController.text.replaceAll(RegExp(r'[^\d]'), '').length >= 10 &&
      _emailRe.hasMatch(emailController.text.trim());

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

  String get maskedEmail {
    final e = emailController.text.trim();
    final at = e.indexOf('@');
    if (at <= 1) return e;
    final user = e.substring(0, at);
    final domain = e.substring(at);
    final shown = user.length <= 2 ? user : '${user[0]}${'•' * (user.length - 2)}${user[user.length - 1]}';
    return '$shown$domain';
  }

  // ── Proceed ───────────────────────────────────────────────────────────────
  Future<void> proceed() async {
    if (!currentStepValid) return;
    if (isLoading.value) return;
    errorMsg.value = '';

    if (step.value == 1) {
      await _sendCode();
    } else if (step.value == 2) {
      _verifyCode();
    } else if (step.value < 4) {
      step.value++;
    } else {
      _saveProfile();
      // Mint a Firebase UID so Firestore writes are server-verifiable.
      // Best-effort — failure here doesn't block sign-up; the app falls
      // back to the per-install UUID for sync.
      unawaited(AuthService.instance.ensureSignedIn());
      Get.offAllNamed(Routes.home);
    }
  }

  Future<void> _sendCode() async {
    isLoading.value = true;
    try {
      // Detect a returning user upfront so we can branch after OTP.
      _returningUser =
          await UserStorage.findByEmail(emailController.text.trim());

      _expectedCode = EmailOtpService.generateCode();
      _codeIssuedAt = DateTime.now();
      final ok = await EmailOtpService.sendCode(
        toEmail: emailController.text.trim(),
        code: _expectedCode,
      );
      if (!ok) {
        errorMsg.value = "Couldn't send code. Check your email and try again.";
        return;
      }
      otpController.clear();
      step.value = 2;
    } catch (e) {
      errorMsg.value = 'Network error sending code. Try again.';
    } finally {
      isLoading.value = false;
    }
  }

  void _verifyCode() {
    final entered = otpController.text.trim();
    final expired = _codeIssuedAt == null ||
        DateTime.now().difference(_codeIssuedAt!) > const Duration(minutes: 10);
    if (expired) {
      errorMsg.value = 'Code expired. Tap Resend.';
      return;
    }
    if (entered != _expectedCode) {
      errorMsg.value = 'Wrong code. Double-check and try again.';
      return;
    }
    errorMsg.value = '';

    // Returning user: skip the profile/tags steps and restore the saved
    // identity. Same email = same person — never create a duplicate.
    final existing = _returningUser;
    if (existing != null) {
      _restoreReturningUser(existing);
      return;
    }

    step.value = 3;
  }

  Future<void> _restoreReturningUser(Player p) async {
    await UserStorage.save(p);
    kMe = p;
    AppController.to.currentUser.value = p;
    unawaited(AuthService.instance.ensureSignedIn());
    Get.offAllNamed(Routes.home);
    Get.snackbar(
      'Welcome back',
      'Signed in as ${p.name}',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> resendCode() async {
    if (isLoading.value) return;
    if (emailController.text.trim().isEmpty) return;
    await _sendCode();
    if (errorMsg.value.isEmpty) {
      Get.snackbar('Sent', 'A new code is on its way',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16), borderRadius: 12,
          duration: const Duration(seconds: 2));
    }
  }

  void _saveProfile() {
    final age = dob.value == null
        ? null
        : DateTime.now().year - dob.value!.year;
    final username = usernameController.text.trim();
    AppController.to.updateCurrentUser(
      name: nameController.text.trim(),
      handle: username.isEmpty ? null : '@$username',
      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      bio: bioController.text.trim().isEmpty ? null : bioController.text.trim(),
      photoPath: photoPath.value,
      age: age,
      tags: Map<String, String>.from(tags),
    );
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
    otpText.value = otpController.text;
    phoneController.addListener(() => phoneText.value = phoneController.text);
    bioController.addListener(() => bioText.value = bioController.text);
    otpController.addListener(() => otpText.value = otpController.text);
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
