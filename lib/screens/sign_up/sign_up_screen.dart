import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';

import '../../core/theme/tokens.dart';
import 'sign_up_controller.dart';

// ─── Tag questions (step 4) ─────────────────────────────────────────────────
const _tagQuestions = [
  _TagQ(key: 'experience', q: 'Playing since?',
      opts: ['< 6 months', '6–12 months', '1–2 years', '3+ years', 'Former tennis/squash']),
  _TagQ(key: 'frequency', q: 'How often do you play?',
      opts: ['Once a month', '2–3x a month', 'Weekly', '2–3x a week', 'Basically live here']),
  _TagQ(key: 'vibe', q: 'Match energy?',
      opts: ['🧘 Chill hits', '🎾 Social + fun', '🔥 Competitive', '🏆 Tournament prep']),
  _TagQ(key: 'hand', q: 'Which hand?',
      opts: ['Righty', 'Lefty', 'Switches it up']),
  _TagQ(key: 'slots', q: 'When are you usually free?',
      opts: ['Early mornings', 'Lunch breaks', 'Weeknights', 'Weekend days', 'Night owl']),
];

class _TagQ {
  const _TagQ({required this.key, required this.q, required this.opts});
  final String key;
  final String q;
  final List<String> opts;
}

// ─── Screen ─────────────────────────────────────────────────────────────────
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SignUpController());
    return Scaffold(
      backgroundColor: AppColors.blue900,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Ambient ball glow (top-right)
          Positioned(
            top: -60, right: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.ball.withOpacity(0.27), Colors.transparent],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header: back button + step counter + progress bar
                _Header(ctrl: ctrl),
                // Scrollable step content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
                    child: Obx(() => _buildStep(ctrl, context)),
                  ),
                ),
              ],
            ),
          ),
          // Sticky CTA
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _CTA(ctrl: ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(SignUpController ctrl, BuildContext context) {
    return switch (ctrl.step.value) {
      1 => _StepInfo(ctrl: ctrl),
      2 => _StepOtp(ctrl: ctrl),
      3 => _StepProfile(ctrl: ctrl),
      4 => _StepTags(ctrl: ctrl),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.ctrl});
  final SignUpController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: ctrl.goBack,
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
              const Spacer(),
              Obx(() => Text(
                'STEP ${ctrl.step.value} OF 4',
                style: AppFonts.mono(10, color: Colors.white.withOpacity(0.60), letterSpacing: 0.20),
              )),
              const Spacer(),
              const SizedBox(width: 40), // mirror of back button
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Obx(() => Row(
            children: List.generate(4, (i) {
              final active = i < ctrl.step.value;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ball : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          )),
        ],
      ),
    );
  }
}

// ─── CTA button ──────────────────────────────────────────────────────────────
class _CTA extends StatelessWidget {
  const _CTA({required this.ctrl});
  final SignUpController ctrl;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 28 + bottomPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.blue900],
          stops: const [0.0, 0.40],
        ),
      ),
      child: Obx(() {
        final valid = ctrl.currentStepValid;
        return GestureDetector(
          onTap: valid ? ctrl.proceed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: valid ? AppColors.ball : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              boxShadow: valid
                  ? [BoxShadow(color: AppColors.ball.withOpacity(0.33), blurRadius: 28, offset: const Offset(0, 10))]
                  : [],
            ),
            child: Center(
              child: Text(
                ctrl.step.value < 4 ? 'Continue →' : 'Finish & play →',
                style: AppFonts.display(16,
                  color: valid ? AppColors.ink : Colors.white.withOpacity(0.40),
                  letterSpacing: 0.32,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Basic info
// ─────────────────────────────────────────────────────────────────────────────
class _StepInfo extends StatelessWidget {
  const _StepInfo({required this.ctrl});
  final SignUpController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Welcome.\nLet\'s get you ',
            style: AppFonts.display(34, color: Colors.white, height: 1.0),
            children: [
              TextSpan(
                text: 'on court.',
                style: AppFonts.display(34, color: AppColors.ball),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A few basics. Email is optional.',
          style: AppFonts.body(13, color: Colors.white.withOpacity(0.60)),
        ),
        const SizedBox(height: 24),

        _FieldLabel(label: 'FULL NAME', required: true),
        const SizedBox(height: 6),
        _AppTextField(
          controller: ctrl.nameController,
          placeholder: 'Zara Ahmad',
          onChanged: (_) => ctrl.step.refresh(),
        ),
        const SizedBox(height: 12),

        _FieldLabel(label: 'DATE OF BIRTH', required: true),
        const SizedBox(height: 6),
        Obx(() => GestureDetector(
          onTap: () => _pickDate(context, ctrl),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Text(
              ctrl.dob.value != null
                  ? DateFormat('dd MMM yyyy').format(ctrl.dob.value!)
                  : 'Select date',
              style: AppFonts.body(
                15,
                color: ctrl.dob.value != null ? Colors.white : Colors.white.withOpacity(0.40),
              ),
            ),
          ),
        )),
        const SizedBox(height: 12),

        _FieldLabel(label: 'PHONE NUMBER', required: true),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Text('🇵🇰 +92', style: AppFonts.mono(13, color: Colors.white)),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl.phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppFonts.body(15, color: Colors.white),
                  onChanged: (_) => ctrl.step.refresh(),
                  decoration: InputDecoration(
                    hintText: '300 1234567',
                    hintStyle: AppFonts.body(15, color: Colors.white.withOpacity(0.40)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _FieldLabel(label: 'EMAIL', optional: true),
        const SizedBox(height: 6),
        _AppTextField(
          controller: ctrl.emailController,
          placeholder: 'you@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, SignUpController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.ball,
            onPrimary: AppColors.ink,
            surface: AppColors.blue800,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) ctrl.dob.value = picked;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — OTP verification
// ─────────────────────────────────────────────────────────────────────────────
class _StepOtp extends StatelessWidget {
  const _StepOtp({required this.ctrl});
  final SignUpController ctrl;

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 58,
      height: 68,
      textStyle: AppFonts.display(32, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
      ),
    );
    final focusedTheme = defaultTheme.copyWith(
      decoration: defaultTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.ball, width: 2),
      ),
    );
    final submittedTheme = defaultTheme.copyWith(
      textStyle: AppFonts.display(32, color: AppColors.ink),
      decoration: defaultTheme.decoration!.copyWith(
        color: AppColors.ball,
        border: Border.all(color: AppColors.ball, width: 2),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Verify\nyour ',
            style: AppFonts.display(34, color: Colors.white, height: 1.0),
            children: [
              TextSpan(text: 'number.', style: AppFonts.display(34, color: AppColors.ball)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'We texted a 4-digit code to ',
            style: AppFonts.body(13, color: Colors.white.withOpacity(0.70)),
            children: [
              TextSpan(
                text: '+92 ${ctrl.phoneController.text.isNotEmpty ? ctrl.phoneController.text : '300 1234567'}',
                style: AppFonts.body(13, color: Colors.white, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Center(
          child: Pinput(
            length: 4,
            controller: ctrl.otpController,
            defaultPinTheme: defaultTheme,
            focusedPinTheme: focusedTheme,
            submittedPinTheme: submittedTheme,
            keyboardType: TextInputType.number,
            onChanged: (_) => ctrl.step.refresh(),
            onCompleted: (_) => ctrl.step.refresh(),
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => ctrl.otpController.clear(),
                child: Text(
                  'RESEND CODE',
                  style: AppFonts.mono(11,
                    color: AppColors.ball,
                    letterSpacing: 0.15,
                  ).copyWith(decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Didn't get it? Check spam or try again in 30s.",
                style: AppFonts.body(12, color: Colors.white.withOpacity(0.50)),
              ),
            ],
          ),
        ),

        Obx(() {
          if (ctrl.errorMsg.value.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              ctrl.errorMsg.value,
              style: AppFonts.body(13, color: AppColors.hot),
              textAlign: TextAlign.center,
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — Player card (photo + username + bio)
// ─────────────────────────────────────────────────────────────────────────────
class _StepProfile extends StatelessWidget {
  const _StepProfile({required this.ctrl});
  final SignUpController ctrl;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) ctrl.photoPath.value = xfile.path;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Build your\n',
            style: AppFonts.display(34, color: Colors.white, height: 1.0),
            children: [
              TextSpan(text: 'player card.', style: AppFonts.display(34, color: AppColors.ball)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hosts see this when you request to join.',
          style: AppFonts.body(13, color: Colors.white.withOpacity(0.60)),
        ),
        const SizedBox(height: 22),

        // Photo + caption
        Row(
          children: [
            Obx(() => GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: ctrl.photoPath.value == null
                      ? Border.all(color: Colors.white.withOpacity(0.25), style: BorderStyle.solid)
                      : null,
                  image: ctrl.photoPath.value != null
                      ? DecorationImage(
                          image: NetworkImage(ctrl.photoPath.value!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: ctrl.photoPath.value == null
                    ? const Center(child: Text('📷', style: TextStyle(fontSize: 30)))
                    : null,
              ),
            )),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PHOTO · OPTIONAL',
                      style: AppFonts.mono(10, color: Colors.white.withOpacity(0.60), letterSpacing: 0.15)),
                  const SizedBox(height: 6),
                  Text(
                    'Square crop, PNG/JPG.\nSkip if you want.',
                    style: AppFonts.body(12, color: Colors.white.withOpacity(0.50)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        _FieldLabel(label: 'USERNAME', required: true),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                child: Text('@', style: AppFonts.mono(14, color: Colors.white.withOpacity(0.50))),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl.usernameController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
                    LengthLimitingTextInputFormatter(18),
                  ],
                  style: AppFonts.body(15, color: Colors.white),
                  onChanged: (_) => ctrl.step.refresh(),
                  decoration: InputDecoration(
                    hintText: 'zara.plays',
                    hintStyle: AppFonts.body(15, color: Colors.white.withOpacity(0.40)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FieldLabel(label: 'BIO', optional: true),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: ctrl.bioController,
              builder: (_, v, __) => Text(
                '${v.text.length}/100',
                style: AppFonts.mono(10, color: Colors.white.withOpacity(0.50)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: TextField(
            controller: ctrl.bioController,
            maxLines: 3,
            maxLength: 100,
            style: AppFonts.body(15, color: Colors.white),
            onChanged: (_) => ctrl.step.refresh(),
            decoration: InputDecoration(
              hintText: '3.0 level · weekend hitter · big forehand, bigger smack talk.',
              hintStyle: AppFonts.body(14, color: Colors.white.withOpacity(0.40)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 4 — Smart tags
// ─────────────────────────────────────────────────────────────────────────────
class _StepTags extends StatelessWidget {
  const _StepTags({required this.ctrl});
  final SignUpController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'A few\n',
            style: AppFonts.display(32, color: Colors.white, height: 1.0),
            children: [
              TextSpan(text: 'smart tags.', style: AppFonts.display(32, color: AppColors.ball)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'These help us match you with the right games. Answer at least 3.',
          style: AppFonts.body(13, color: Colors.white.withOpacity(0.65)),
        ),
        const SizedBox(height: 14),

        // Progress counter
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.ball.withOpacity(0.13),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.ball.withOpacity(0.33)),
          ),
          child: Text(
            '${ctrl.tags.length} / 5 ANSWERED',
            style: AppFonts.mono(10, color: AppColors.ball, letterSpacing: 0.15),
          ),
        )),
        const SizedBox(height: 18),

        ...List.generate(_tagQuestions.length, (i) {
          final tq = _tagQuestions[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(() => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: ctrl.tags[tq.key] != null ? AppColors.ball : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: AppFonts.display(12,
                            color: ctrl.tags[tq.key] != null ? AppColors.ink : Colors.white.withOpacity(0.50),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(width: 8),
                    Text(tq.q, style: AppFonts.display(17, color: Colors.white, letterSpacing: -0.17)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: tq.opts.map((opt) {
                    return Obx(() {
                      final selected = ctrl.tags[tq.key] == opt;
                      return GestureDetector(
                        onTap: () => ctrl.toggleTag(tq.key, opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.ball : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? AppColors.ball : Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: AppFonts.body(13,
                              color: selected ? AppColors.ink : Colors.white,
                              weight: selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    });
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false, this.optional = false});
  final String label;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppFonts.mono(10, color: Colors.white.withOpacity(0.60), letterSpacing: 0.15),
        ),
        if (optional) ...[
          const SizedBox(width: 4),
          Text(
            '· OPTIONAL',
            style: AppFonts.mono(10, color: Colors.white.withOpacity(0.40)),
          ),
        ],
      ],
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppFonts.body(15, color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: placeholder,
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
}
