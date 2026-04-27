import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart';
import '../../core/mock_data.dart';
import '../../core/services/email_otp_service.dart';
import '../../core/services/user_storage.dart';
import '../../core/theme/tokens.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  int _step = 1; // 1 = enter email, 2 = enter code
  bool _loading = false;
  String _error = '';
  String _expectedCode = '';
  DateTime? _codeIssuedAt;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (!_emailRe.hasMatch(email)) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }

    final saved = await UserStorage.load();
    if (saved == null || saved.email == null || saved.email!.toLowerCase() != email.toLowerCase()) {
      setState(() => _error = 'No account found for this email on this device.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      _expectedCode = EmailOtpService.generateCode();
      _codeIssuedAt = DateTime.now();
      final ok = await EmailOtpService.sendCode(toEmail: email, code: _expectedCode);
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = "Couldn't send code. Try again.");
        return;
      }
      _otpCtrl.clear();
      setState(() => _step = 2);
    } catch (_) {
      setState(() => _error = 'Network error. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _verify() {
    final entered = _otpCtrl.text.trim();
    if (entered.length != 4) return;
    if (_codeIssuedAt == null ||
        DateTime.now().difference(_codeIssuedAt!) > const Duration(minutes: 10)) {
      setState(() => _error = 'Code expired. Tap Resend.');
      return;
    }
    if (entered != _expectedCode) {
      setState(() => _error = 'Wrong code. Try again.');
      return;
    }
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final saved = await UserStorage.load();
    if (saved == null) {
      setState(() => _error = 'Something went wrong. Try signing up again.');
      return;
    }
    kMe = saved;
    AppController.to.currentUser.value = saved;
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue900,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Headline
              Text.rich(
                TextSpan(
                  text: 'Welcome\n',
                  style: AppFonts.display(34, color: Colors.white, height: 1.0),
                  children: [
                    TextSpan(text: 'back.', style: AppFonts.display(34, color: AppColors.ball)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? 'Enter the email you signed up with — we\'ll send you a code.'
                    : 'We emailed a 4-digit code to ${_maskEmail(_emailCtrl.text.trim())}',
                style: AppFonts.body(13, color: Colors.white.withOpacity(0.65)),
              ),
              const SizedBox(height: 28),

              if (_step == 1) _buildEmailStep() else _buildCodeStep(),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(_error, style: AppFonts.body(13, color: AppColors.hot)),
              ],

              const Spacer(),

              GestureDetector(
                onTap: _loading
                    ? null
                    : (_step == 1
                        ? _sendCode
                        : (_otpCtrl.text.length == 4 ? _verify : null)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.ball,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: AppColors.ball.withOpacity(0.33), blurRadius: 28, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                            ),
                          )
                        : Text(
                            _step == 1 ? 'Send code →' : 'Sign in →',
                            style: AppFonts.display(16, color: AppColors.ink, letterSpacing: 0.32),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => Get.offAllNamed(Routes.signUp),
                  child: Text.rich(
                    TextSpan(
                      text: "New here? ",
                      style: AppFonts.body(13, color: Colors.white.withOpacity(0.55)),
                      children: [
                        TextSpan(
                          text: 'Create an account',
                          style: AppFonts.body(13, color: AppColors.ball, weight: FontWeight.w700)
                              .copyWith(decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return TextField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      autofocus: true,
      style: AppFonts.body(15, color: Colors.white),
      onChanged: (_) {
        if (_error.isNotEmpty) setState(() => _error = '');
      },
      decoration: InputDecoration(
        hintText: 'you@email.com',
        hintStyle: AppFonts.body(15, color: Colors.white.withOpacity(0.40)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ball, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildCodeStep() {
    final theme = PinTheme(
      width: 58, height: 68,
      textStyle: AppFonts.display(32, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Pinput(
            length: 4,
            controller: _otpCtrl,
            defaultPinTheme: theme,
            focusedPinTheme: theme.copyWith(
              decoration: theme.decoration!.copyWith(
                border: Border.all(color: AppColors.ball, width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            onCompleted: (_) => _verify(),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            onTap: _loading ? null : _sendCode,
            child: Text(
              _loading ? 'SENDING…' : 'RESEND CODE',
              style: AppFonts.mono(11, color: AppColors.ball, letterSpacing: 0.15)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }

  String _maskEmail(String e) {
    final at = e.indexOf('@');
    if (at <= 1) return e;
    final user = e.substring(0, at);
    final domain = e.substring(at);
    final shown = user.length <= 2 ? user : '${user[0]}${'•' * (user.length - 2)}${user[user.length - 1]}';
    return '$shown$domain';
  }
}
