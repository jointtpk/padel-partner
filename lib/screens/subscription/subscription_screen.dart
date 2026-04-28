import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/models/friend.dart';
import '../../core/services/billing_service.dart';
import '../../app/controllers/app_controller.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppController.to;
    final bottom = MediaQuery.of(context).padding.bottom;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.blue900,
      body: Obx(() {
        final sub = store.subscription.value;
        final isPro = sub.plan == 'pro';

        return Stack(
          children: [
            // Background glow
            Positioned(
              top: -80, right: -80,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.ball.withOpacity(0.12), Colors.transparent],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, top + 12, 20, bottom + 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Hero
                  Text(
                    isPro ? 'You\'re on Pro 🎉' : 'Upgrade to Pro',
                    style: AppFonts.display(30, color: Colors.white, letterSpacing: -0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? 'Thanks for supporting Padel Partner. Enjoy unlimited access.'
                        : 'Unlimited games, full features, cancel anytime.',
                    style: AppFonts.body(14, color: Colors.white.withOpacity(0.60), height: 1.5),
                  ),

                  const SizedBox(height: 32),

                  // Plan card
                  isPro
                      ? _ProActiveCard(sub: sub)
                      : _PlanCard(sub: sub),

                  const SizedBox(height: 28),

                  // Feature list
                  _FeatureList(isPro: isPro),

                  const SizedBox(height: 28),

                  // FAQ
                  _Faq(),

                  if (!isPro) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Billed monthly · Cancel anytime · Secure via Google Play',
                        style: AppFonts.mono(9, color: Colors.white.withOpacity(0.30), letterSpacing: 0.2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(child: _RestorePurchasesLink()),
                  ],
                ],
              ),
            ),

            // Sticky CTA
            if (!isPro)
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _StickyUpgradeCta(store: store, bottom: bottom, sub: sub),
              ),
          ],
        );
      }),
    );
  }
}

// ─── Plan card (trial/free users) ────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.sub});
  final Subscription sub;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _annual = false;

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = 100;
    final annualPrice = 960; // Rs 80/mo × 12

    return Column(
      children: [
        // Billing toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _ToggleOption(
                label: 'Monthly',
                active: !_annual,
                onTap: () => setState(() => _annual = false),
              ),
              _ToggleOption(
                label: 'Annual  (save 20%)',
                active: _annual,
                onTap: () => setState(() => _annual = true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Price card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ball, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ball,
                      borderRadius: BorderRadius.circular(kBorderRadiusPill),
                    ),
                    child: Text('PRO', style: AppFonts.mono(10, color: AppColors.ink, letterSpacing: 0.6)),
                  ),
                  if (_annual) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.hot.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(kBorderRadiusPill),
                      ),
                      child: Text('SAVE 20%', style: AppFonts.mono(9, color: AppColors.hot, letterSpacing: 0.4)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${_annual ? annualPrice : monthlyPrice}',
                    style: AppFonts.display(36, color: AppColors.ball, letterSpacing: -0.8),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      _annual ? '/ year' : '/ month',
                      style: AppFonts.body(14, color: Colors.white.withOpacity(0.50)),
                    ),
                  ),
                ],
              ),
              if (_annual) ...[
                const SizedBox(height: 2),
                Text(
                  'Rs 80/month billed annually',
                  style: AppFonts.mono(10, color: Colors.white.withOpacity(0.40)),
                ),
              ],
              const SizedBox(height: 6),
              if (widget.sub.plan == 'trial')
                Text(
                  '${widget.sub.daysLeft} days of free trial remaining',
                  style: AppFonts.body(12, color: AppColors.ball.withOpacity(0.75)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: AppFonts.body(12,
                color: active ? Colors.white : Colors.white.withOpacity(0.40),
                weight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pro active card ─────────────────────────────────────────────────────────

class _ProActiveCard extends StatelessWidget {
  const _ProActiveCard({required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue800, AppColors.blue700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ball.withOpacity(0.40)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.ball, shape: BoxShape.circle),
            child: Center(child: Text('⭐', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Padel Partner Pro', style: AppFonts.display(16, color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text('Active · Renews monthly', style: AppFonts.body(12, color: Colors.white.withOpacity(0.55))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.ball,
              borderRadius: BorderRadius.circular(kBorderRadiusPill),
            ),
            child: Text('ACTIVE', style: AppFonts.mono(9, color: AppColors.ink, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ─── Feature list ─────────────────────────────────────────────────────────────

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.isPro});
  final bool isPro;

  static const _features = [
    (icon: '🎾', title: 'Unlimited game joins', sub: 'No monthly cap on games you can join', pro: true),
    (icon: '🏟', title: 'Host unlimited games', sub: 'Create as many games as you like', pro: true),
    (icon: '⚡', title: 'Priority matching', sub: 'Get matched with nearby games first', pro: true),
    (icon: '📊', title: 'Full stats & history', sub: 'Complete performance breakdown', pro: true),
    (icon: '💬', title: 'Unlimited DMs', sub: 'Chat with any player, no restrictions', pro: true),
    (icon: '🏷', title: 'Pro badge', sub: 'Stand out on your profile', pro: true),
    (icon: '🔍', title: 'Browse games', sub: 'Always free', pro: false),
    (icon: '👥', title: 'Add friends', sub: 'Always free', pro: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What\'s included', style: AppFonts.display(16, color: Colors.white, letterSpacing: -0.3)),
        const SizedBox(height: 14),
        ..._features.map((f) => _FeatureRow(
          icon: f.icon,
          title: f.title,
          sub: f.sub,
          isPro: f.pro,
          unlocked: isPro || !f.pro,
        )),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.isPro,
    required this.unlocked,
  });

  final String icon;
  final String title;
  final String sub;
  final bool isPro;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: unlocked
                  ? (isPro ? AppColors.ball.withOpacity(0.12) : Colors.white.withOpacity(0.06))
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.body(13, color: unlocked ? Colors.white : Colors.white.withOpacity(0.35), weight: FontWeight.w600),
                ),
                Text(
                  sub,
                  style: AppFonts.body(11, color: Colors.white.withOpacity(unlocked ? 0.45 : 0.22)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          unlocked
              ? Icon(Icons.check_circle_rounded, color: isPro ? AppColors.ball : Colors.white.withOpacity(0.30), size: 20)
              : Icon(Icons.lock_outline_rounded, color: Colors.white.withOpacity(0.20), size: 18),
        ],
      ),
    );
  }
}

// ─── FAQ ─────────────────────────────────────────────────────────────────────

class _Faq extends StatelessWidget {
  const _Faq();

  static const _items = [
    ('Can I cancel anytime?', 'Yes — cancel from Google Play subscriptions at any time. You keep access until the end of your billing period.'),
    ('What happens after the trial?', 'You\'ll be moved to the free plan automatically. No charge without your explicit upgrade.'),
    ('Is my payment secure?', 'Payments are processed entirely through Google Play Billing — we never store your card details.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FAQ', style: AppFonts.display(16, color: Colors.white, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        ..._items.map((item) => _FaqItem(q: item.$1, a: item.$2)),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.q, style: AppFonts.body(13, color: Colors.white, weight: FontWeight.w600)),
                ),
                Icon(
                  _open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withOpacity(0.40),
                  size: 20,
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 8),
              Text(widget.a, style: AppFonts.body(12, color: Colors.white.withOpacity(0.55), height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Upgrade confirmation sheet ───────────────────────────────────────────────

void _showUpgradeConfirm(BuildContext context, AppController store) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _UpgradeConfirmSheet(),
  ).then((_) {});
}

class _UpgradeConfirmSheet extends StatefulWidget {
  const _UpgradeConfirmSheet();

  @override
  State<_UpgradeConfirmSheet> createState() => _UpgradeConfirmSheetState();
}

class _UpgradeConfirmSheetState extends State<_UpgradeConfirmSheet> {
  bool _processing = false;
  StreamSubscription<PurchaseResult>? _resultSub;

  @override
  void dispose() {
    _resultSub?.cancel();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    final billing = BillingService.instance;
    final iapAvailable = await billing.isAvailable();

    // Dev fallback: when running without a configured store (web, emulator
    // without a Play account, etc.) keep the simulated upgrade so the dev
    // flow still works end-to-end.
    if (!iapAvailable) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      AppController.to.subscription.value =
          const Subscription(plan: 'pro', daysLeft: 0);
      _onSuccess(simulated: true);
      return;
    }

    // Real flow. The actual purchase outcome arrives asynchronously via the
    // global purchase stream, so listen before initiating.
    _resultSub?.cancel();
    _resultSub = billing.results.listen((r) {
      if (!mounted) return;
      switch (r.kind) {
        case PurchaseResultKind.success:
          _onSuccess();
          break;
        case PurchaseResultKind.canceled:
          setState(() => _processing = false);
          break;
        case PurchaseResultKind.error:
          setState(() => _processing = false);
          _showError(r.message ?? 'Purchase failed.');
          break;
      }
    });

    final started = await billing.buyPro();
    if (!started && mounted) {
      // buyPro emits its own error on `results`; just keep the spinner off
      // if the listener hasn't fired yet (e.g. queryProductDetails failed
      // before the stream).
      setState(() => _processing = false);
    }
  }

  void _onSuccess({bool simulated = false}) {
    _resultSub?.cancel();
    Navigator.of(context).pop();
    Get.back();
    Get.snackbar(
      '',
      '',
      titleText: Text(
        simulated ? "You're now on Pro! ⭐ (dev)" : "You're now on Pro! ⭐",
        style: AppFonts.display(14, color: AppColors.ink),
      ),
      messageText: Text('Enjoy unlimited access to Padel Partner.',
          style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.65))),
      backgroundColor: AppColors.ball,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  void _showError(String msg) {
    Get.snackbar(
      '',
      '',
      titleText: Text('Upgrade failed',
          style: AppFonts.display(14, color: Colors.white)),
      messageText: Text(msg,
          style: AppFonts.body(12, color: Colors.white.withOpacity(0.85))),
      backgroundColor: AppColors.ink,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.blue900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Confirm upgrade',
              style: AppFonts.display(22, color: Colors.white, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text(
            'You\'re subscribing to Padel Partner Pro. Payment is processed by Google Play.',
            style: AppFonts.body(13, color: Colors.white.withOpacity(0.60), height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Plan', value: 'Pro · Monthly'),
                const SizedBox(height: 10),
                _SummaryRow(label: 'Price', value: 'Rs 100 / month'),
                const SizedBox(height: 10),
                _SummaryRow(label: 'Billed via', value: 'Google Play'),
                const SizedBox(height: 10),
                _SummaryRow(label: 'Cancel', value: 'Anytime'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'You\'ll be charged Rs 100 today and the same amount each month until you cancel. Manage your subscription in Google Play any time.',
            style: AppFonts.body(11, color: Colors.white.withOpacity(0.45), height: 1.5),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _processing ? null : () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Center(
                      child: Text('Cancel',
                          style: AppFonts.body(15,
                              color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _processing ? null : _confirm,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _processing
                          ? AppColors.ball.withOpacity(0.55)
                          : AppColors.ball,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _processing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.ink),
                              ),
                            )
                          : Text('Pay Rs 100 & subscribe',
                              style: AppFonts.body(15,
                                  color: AppColors.ink,
                                  weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: AppFonts.mono(11,
                color: Colors.white.withOpacity(0.45), letterSpacing: 0.4)),
        const Spacer(),
        Text(value,
            style: AppFonts.body(13, color: Colors.white, weight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Sticky upgrade CTA ───────────────────────────────────────────────────────

class _StickyUpgradeCta extends StatelessWidget {
  const _StickyUpgradeCta({required this.store, required this.bottom, required this.sub});
  final AppController store;
  final double bottom;
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.blue900.withOpacity(0), AppColors.blue900],
          stops: const [0.0, 0.35],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showUpgradeConfirm(context, store);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: AppColors.ball,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ball.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  sub.plan == 'trial'
                      ? 'Upgrade now — Rs 100/month'
                      : 'Get Pro — Rs 100/month',
                  style: AppFonts.body(16, color: AppColors.ink, weight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Secure payment via Google Play',
            style: AppFonts.mono(9, color: Colors.white.withOpacity(0.30), letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

// ─── Restore purchases link ──────────────────────────────────────────────────
// Required by App Store review for any non-consumable / subscription product.
// Calls into BillingService and waits a short window for results from the
// global purchase stream. If nothing arrives within the window we treat that
// as "no prior purchase to restore".

class _RestorePurchasesLink extends StatefulWidget {
  const _RestorePurchasesLink();

  @override
  State<_RestorePurchasesLink> createState() => _RestorePurchasesLinkState();
}

class _RestorePurchasesLinkState extends State<_RestorePurchasesLink> {
  bool _busy = false;

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);

    final billing = BillingService.instance;
    if (!await billing.isAvailable()) {
      if (mounted) setState(() => _busy = false);
      _toast('In-app purchases are not available on this device.');
      return;
    }

    // The plugin emits restored purchases through the same stream as buys.
    // Listen for ~3s; if nothing arrives, assume there's nothing to restore.
    StreamSubscription<PurchaseResult>? sub;
    final completer = Completer<PurchaseResult?>();
    sub = billing.results.listen((r) {
      if (!completer.isCompleted) completer.complete(r);
    });

    await billing.restorePurchases();

    final result = await completer.future
        .timeout(const Duration(seconds: 3), onTimeout: () => null);
    await sub.cancel();

    if (!mounted) return;
    setState(() => _busy = false);

    if (result == null) {
      _toast('No previous purchases found.');
      return;
    }
    switch (result.kind) {
      case PurchaseResultKind.success:
        _toast('Purchases restored. Welcome back to Pro!');
        Get.back();
        break;
      case PurchaseResultKind.canceled:
        _toast('No previous purchases found.');
        break;
      case PurchaseResultKind.error:
        _toast(result.message ?? 'Could not restore purchases.');
        break;
    }
  }

  void _toast(String msg) {
    Get.snackbar(
      '',
      '',
      titleText: Text('Restore purchases',
          style: AppFonts.display(13, color: Colors.white)),
      messageText: Text(msg,
          style: AppFonts.body(12, color: Colors.white.withOpacity(0.80))),
      backgroundColor: AppColors.ink,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _restore,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy) ...[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _busy ? 'Restoring…' : 'Restore purchases',
              style: AppFonts.body(
                12,
                color: Colors.white.withOpacity(_busy ? 0.45 : 0.70),
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
