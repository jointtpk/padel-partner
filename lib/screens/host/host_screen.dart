import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/game.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart' show Routes;

// ─── Controller ───────────────────────────────────────────────────────────────

class HostController extends GetxController {
  final step = 1.obs; // 1–4

  // Step 1 – Court
  final club       = ''.obs;
  final city       = 'Karachi'.obs;
  final area       = ''.obs;
  final court      = ''.obs;
  final courtType  = 'Indoor'.obs; // Indoor | Outdoor
  final clubCtrl   = TextEditingController();
  final courtCtrl  = TextEditingController();

  // Step 2 – Time
  final selectedWhen = 0.obs; // index into _whenOptions
  final selectedTime = TimeOfDay(hour: 18, minute: 0).obs;
  final duration     = 90.obs; // minutes: 60 | 90 | 120

  static const whenOptions = ['Today', 'Tomorrow', 'Saturday', 'Sunday', 'Monday'];

  // Step 3 – Vibe / Cost
  final vibe         = 'Social'.obs;
  final totalCost    = ''.obs;
  final spots        = 3.obs;   // 1–3 open spots (host fills one)
  final autoApprove  = false.obs;
  final totalCtrl    = TextEditingController();

  static const vibes = ['Social', 'Competitive', 'Practice', 'Beginner-friendly'];

  // Computed
  int get pricePerHead {
    final t = int.tryParse(totalCost.value) ?? 0;
    final heads = spots.value + 1; // open spots + host
    if (heads == 0) return 0;
    return (t / heads).ceil();
  }

  // Validation
  bool get step1Valid =>
      clubCtrl.text.trim().isNotEmpty &&
      area.value.isNotEmpty &&
      courtCtrl.text.trim().isNotEmpty;

  bool get step2Valid => true; // always valid — defaults set

  bool get step3Valid {
    final t = int.tryParse(totalCost.value) ?? 0;
    return t > 0 && vibe.value.isNotEmpty;
  }

  void nextStep() {
    if (step.value < 4) step.value++;
  }

  void prevStep() {
    if (step.value > 1) step.value--;
  }

  @override
  void onClose() {
    clubCtrl.dispose();
    courtCtrl.dispose();
    totalCtrl.dispose();
    super.onClose();
  }

  void publish() {
    final store = AppController.to;
    final whenLabel = whenOptions[selectedWhen.value];
    final h = selectedTime.value.hour;
    final m = selectedTime.value.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final timeStr = '$h12:$m $period';

    final game = Game(
      id: 'g_${DateTime.now().millisecondsSinceEpoch}',
      club: clubCtrl.text.trim(),
      area: area.value,
      when: whenLabel == 'Tomorrow' ? 'Tmrw' : whenLabel,
      time: timeStr,
      duration: '${duration.value} min',
      level: levelByKey(kMe.tier).label,
      levelKey: kMe.tier,
      price: pricePerHead,
      spots: spots.value,
      total: spots.value + 1,
      hostId: kMe.id,
      playerIds: [kMe.id],
      vibe: vibe.value,
      court: '${courtCtrl.text.trim()} · ${courtType.value}',
      weather: courtType.value == 'Indoor' ? 'Indoor' : '—',
      hot: false,
      totalCost: int.tryParse(totalCost.value) ?? 0,
      autoApprove: autoApprove.value,
    );

    store.addHostedGame(game);
    Get.offAllNamed(Routes.home);

    Get.snackbar(
      '',
      '',
      titleText: Text('Game published! 🎾', style: AppFonts.display(14, color: AppColors.ink)),
      messageText: Text('Share with friends to fill your spots.', style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.65))),
      backgroundColor: AppColors.ball,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HostScreen extends StatelessWidget {
  const HostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HostController());
    return Scaffold(
      backgroundColor: AppColors.blue900,
      body: Column(
        children: [
          _Header(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: switch (ctrl.step.value) {
                  2 => _Step2Time(ctrl: ctrl, key: const ValueKey(2)),
                  3 => _Step3Vibe(ctrl: ctrl, key: const ValueKey(3)),
                  4 => _Step4Review(ctrl: ctrl, key: const ValueKey(4)),
                  _ => _Step1Court(ctrl: ctrl, key: const ValueKey(1)),
                },
              );
            }),
          ),
          _CtaBar(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.ctrl});
  final HostController ctrl;

  static const _titles = ['Court details', 'Date & time', 'Vibe & cost', 'Review & publish'];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Obx(() {
      final s = ctrl.step.value;
      return Container(
        color: AppColors.blue900,
        padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back + step counter
            Row(
              children: [
                GestureDetector(
                  onTap: s == 1 ? Get.back : ctrl.prevStep,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                Text(
                  'STEP $s OF 4',
                  style: AppFonts.mono(11, color: Colors.white.withOpacity(0.55), letterSpacing: 0.8),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _titles[s - 1],
              style: AppFonts.display(26, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(height: 14),
            // Progress segments
            Row(
              children: List.generate(4, (i) {
                final filled = i < s;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: filled ? AppColors.ball : Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Step 1: Court ────────────────────────────────────────────────────────────

class _Step1Court extends StatelessWidget {
  const _Step1Court({super.key, required this.ctrl});
  final HostController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Club name'),
          const SizedBox(height: 8),
          _TextInput(controller: ctrl.clubCtrl, hint: 'e.g. Padel Up Karachi', onChanged: (_) => ctrl.club.value = ctrl.clubCtrl.text),

          const SizedBox(height: 20),
          _SectionLabel('City'),
          const SizedBox(height: 8),
          Obx(() => _DropdownField<String>(
            value: ctrl.city.value,
            items: kPkCities,
            label: (c) => c,
            onChanged: (v) {
              ctrl.city.value = v!;
              ctrl.area.value = '';
            },
          )),

          const SizedBox(height: 20),
          _SectionLabel('Area'),
          const SizedBox(height: 8),
          Obx(() {
            final areas = kPkAreas[ctrl.city.value] ?? [];
            return _DropdownField<String>(
              value: ctrl.area.value.isEmpty ? null : ctrl.area.value,
              items: areas,
              label: (a) => a,
              hint: 'Select area',
              onChanged: (v) => ctrl.area.value = v ?? '',
            );
          }),

          const SizedBox(height: 20),
          _SectionLabel('Court name / number'),
          const SizedBox(height: 8),
          _TextInput(controller: ctrl.courtCtrl, hint: 'e.g. Court 2', onChanged: (_) {}),

          const SizedBox(height: 20),
          _SectionLabel('Court type'),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: ['Indoor', 'Outdoor'].map((t) {
              final active = ctrl.courtType.value == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.courtType.value = t,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: t == 'Indoor' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? AppColors.ball : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: active ? AppColors.ball : Colors.white.withOpacity(0.14)),
                    ),
                    child: Center(
                      child: Text(
                        t,
                        style: AppFonts.body(14, color: active ? AppColors.ink : Colors.white, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),

          const SizedBox(height: 20),
          // Map placeholder
          _SectionLabel('Pin location (optional)'),
          const SizedBox(height: 8),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.ball, size: 32),
                const SizedBox(height: 8),
                Text('Tap to drop a pin', style: AppFonts.body(13, color: Colors.white.withOpacity(0.55))),
                const SizedBox(height: 4),
                Text('Google Maps · API key required', style: AppFonts.mono(9, color: Colors.white.withOpacity(0.28), letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Time ─────────────────────────────────────────────────────────────

class _Step2Time extends StatelessWidget {
  const _Step2Time({super.key, required this.ctrl});
  final HostController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Day'),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(HostController.whenOptions.length, (i) {
              final active = ctrl.selectedWhen.value == i;
              return GestureDetector(
                onTap: () => ctrl.selectedWhen.value = i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ball : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(kBorderRadiusPill),
                    border: Border.all(color: active ? AppColors.ball : Colors.white.withOpacity(0.14)),
                  ),
                  child: Text(
                    HostController.whenOptions[i],
                    style: AppFonts.body(13, color: active ? AppColors.ink : Colors.white, weight: FontWeight.w600),
                  ),
                ),
              );
            }),
          )),

          const SizedBox(height: 28),
          _SectionLabel('Start time'),
          const SizedBox(height: 8),
          Obx(() {
            final t = ctrl.selectedTime.value;
            final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
            final m = t.minute.toString().padLeft(2, '0');
            final period = t.hour >= 12 ? 'PM' : 'AM';
            return GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: ctrl.selectedTime.value,
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.ball,
                        onPrimary: AppColors.ink,
                        surface: AppColors.blue800,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) ctrl.selectedTime.value = picked;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$h:$m $period',
                      style: AppFonts.display(28, color: AppColors.ball, letterSpacing: -0.5),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time_rounded, color: Colors.white.withOpacity(0.45)),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 28),
          _SectionLabel('Duration'),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: [60, 90, 120].map((d) {
              final active = ctrl.duration.value == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.duration.value = d,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: d < 120 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? AppColors.ball : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: active ? AppColors.ball : Colors.white.withOpacity(0.14)),
                    ),
                    child: Column(
                      children: [
                        Text('$d', style: AppFonts.display(20, color: active ? AppColors.ink : Colors.white)),
                        Text('min', style: AppFonts.mono(9, color: active ? AppColors.ink.withOpacity(0.55) : Colors.white.withOpacity(0.45))),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
        ],
      ),
    );
  }
}

// ─── Step 3: Vibe & cost ──────────────────────────────────────────────────────

class _Step3Vibe extends StatelessWidget {
  const _Step3Vibe({super.key, required this.ctrl});
  final HostController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Game vibe'),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8, runSpacing: 8,
            children: HostController.vibes.map((v) {
              final active = ctrl.vibe.value == v;
              return GestureDetector(
                onTap: () => ctrl.vibe.value = v,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ball : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(kBorderRadiusPill),
                    border: Border.all(color: active ? AppColors.ball : Colors.white.withOpacity(0.14)),
                  ),
                  child: Text(
                    v,
                    style: AppFonts.body(13, color: active ? AppColors.ink : Colors.white, weight: FontWeight.w600),
                  ),
                ),
              );
            }).toList(),
          )),

          const SizedBox(height: 28),
          _SectionLabel('Total court cost (Rs)'),
          const SizedBox(height: 4),
          Text(
            'Split evenly between all players',
            style: AppFonts.body(12, color: Colors.white.withOpacity(0.45)),
          ),
          const SizedBox(height: 10),
          _TextInput(
            controller: ctrl.totalCtrl,
            hint: 'e.g. 4800',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => ctrl.totalCost.value = v,
          ),
          const SizedBox(height: 8),
          Obx(() {
            final pph = ctrl.pricePerHead;
            if (pph == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ball.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.ball),
                  const SizedBox(width: 8),
                  Text(
                    'Rs $pph per head (${ctrl.spots.value + 1} players)',
                    style: AppFonts.body(12, color: AppColors.ball),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 28),
          _SectionLabel('Open spots'),
          const SizedBox(height: 4),
          Text(
            'You fill one spot as host',
            style: AppFonts.body(12, color: Colors.white.withOpacity(0.45)),
          ),
          const SizedBox(height: 10),
          Obx(() => Row(
            children: [
              _StepperBtn(
                icon: Icons.remove_rounded,
                onTap: () { if (ctrl.spots.value > 1) ctrl.spots.value--; },
              ),
              const SizedBox(width: 20),
              Text(
                '${ctrl.spots.value}',
                style: AppFonts.display(32, color: Colors.white),
              ),
              const SizedBox(width: 20),
              _StepperBtn(
                icon: Icons.add_rounded,
                onTap: () { if (ctrl.spots.value < 3) ctrl.spots.value++; },
              ),
              const SizedBox(width: 16),
              Text(
                'spots open',
                style: AppFonts.body(14, color: Colors.white.withOpacity(0.55)),
              ),
            ],
          )),

          const SizedBox(height: 28),
          _SectionLabel('Approval mode'),
          const SizedBox(height: 8),
          Obx(() => GestureDetector(
            onTap: () => ctrl.autoApprove.value = !ctrl.autoApprove.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctrl.autoApprove.value ? '⚡ Auto-approve' : '✋ Manual approval',
                          style: AppFonts.body(14, color: Colors.white, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ctrl.autoApprove.value
                              ? 'Anyone can join instantly'
                              : 'You approve each request',
                          style: AppFonts.body(12, color: Colors.white.withOpacity(0.50)),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 26,
                    decoration: BoxDecoration(
                      color: ctrl.autoApprove.value ? AppColors.ball : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      alignment: ctrl.autoApprove.value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: ctrl.autoApprove.value ? AppColors.ink : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ─── Step 4: Review & publish ─────────────────────────────────────────────────

class _Step4Review extends StatelessWidget {
  const _Step4Review({super.key, required this.ctrl});
  final HostController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Obx(() {
        final t = ctrl.selectedTime.value;
        final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
        final m = t.minute.toString().padLeft(2, '0');
        final period = t.hour >= 12 ? 'PM' : 'AM';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Looks good?', style: AppFonts.display(22, color: Colors.white, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('Review your game before going live.', style: AppFonts.body(13, color: Colors.white.withOpacity(0.55))),
            const SizedBox(height: 24),

            // Preview card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: [BoxShadow(color: AppColors.ink.withOpacity(0.12), blurRadius: 0, offset: const Offset(4, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctrl.clubCtrl.text.isEmpty ? 'Your club' : ctrl.clubCtrl.text,
                    style: AppFonts.display(20, color: AppColors.ink, letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ctrl.area.value.isEmpty ? ctrl.city.value : ctrl.area.value} · ${ctrl.courtCtrl.text.isEmpty ? 'Court' : ctrl.courtCtrl.text} · ${ctrl.courtType.value}',
                    style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ReviewPill(HostController.whenOptions[ctrl.selectedWhen.value]),
                      const SizedBox(width: 8),
                      _ReviewPill('$h:$m $period'),
                      const SizedBox(width: 8),
                      _ReviewPill('${ctrl.duration.value}min'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vibe', style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.4)),
                            Text(ctrl.vibe.value, style: AppFonts.body(13, color: AppColors.ink, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Open spots', style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.4)),
                            Text('${ctrl.spots.value} of ${ctrl.spots.value + 1}', style: AppFonts.body(13, color: AppColors.ink, weight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Per head', style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.4)),
                            Text(
                              ctrl.pricePerHead > 0 ? 'Rs ${ctrl.pricePerHead}' : '—',
                              style: AppFonts.body(13, color: AppColors.ink, weight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ctrl.autoApprove.value ? AppColors.ball.withOpacity(0.18) : AppColors.blue50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ctrl.autoApprove.value ? '⚡ Auto-approve' : '✋ Host approves',
                      style: AppFonts.body(11, color: AppColors.ink, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _ReviewRow(icon: '🏟', label: 'Club', value: ctrl.clubCtrl.text.isEmpty ? '—' : ctrl.clubCtrl.text),
            _ReviewRow(icon: '📍', label: 'Area', value: ctrl.area.value.isEmpty ? ctrl.city.value : ctrl.area.value),
            _ReviewRow(icon: '🎾', label: 'Court', value: '${ctrl.courtCtrl.text} · ${ctrl.courtType.value}'),
            _ReviewRow(icon: '📅', label: 'When', value: '${HostController.whenOptions[ctrl.selectedWhen.value]}, $h:$m $period'),
            _ReviewRow(icon: '💰', label: 'Total cost', value: ctrl.totalCost.value.isEmpty ? '—' : 'Rs ${ctrl.totalCost.value}'),
          ],
        );
      }),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ink.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppFonts.mono(11, color: AppColors.ink)),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(label, style: AppFonts.mono(11, color: Colors.white.withOpacity(0.45), letterSpacing: 0.3)),
          const Spacer(),
          Text(value, style: AppFonts.body(13, color: Colors.white, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── CTA bar ─────────────────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  const _CtaBar({required this.ctrl});
  final HostController ctrl;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Obx(() {
      final s = ctrl.step.value;
      final isLast = s == 4;
      final isValid = switch (s) {
        2 => ctrl.step2Valid,
        3 => ctrl.step3Valid,
        4 => true,
        _ => ctrl.step1Valid,
      };

      return Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
        decoration: BoxDecoration(
          color: AppColors.blue900,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: GestureDetector(
          onTap: isValid ? (isLast ? ctrl.publish : ctrl.nextStep) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: isValid ? AppColors.ball : Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                isLast ? 'Publish game' : 'Continue',
                style: AppFonts.body(16, color: isValid ? AppColors.ink : Colors.white.withOpacity(0.35), weight: FontWeight.w700),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Shared UI primitives ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.mono(11, color: Colors.white.withOpacity(0.50), letterSpacing: 0.6),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AppFonts.body(15, color: Colors.white),
        cursorColor: AppColors.ball,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppFonts.body(15, color: Colors.white.withOpacity(0.30)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  final T? value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint!, style: AppFonts.body(15, color: Colors.white.withOpacity(0.30))) : null,
          dropdownColor: AppColors.blue800,
          style: AppFonts.body(15, color: Colors.white),
          iconEnabledColor: Colors.white.withOpacity(0.40),
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(label(item), style: AppFonts.body(15, color: Colors.white)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
