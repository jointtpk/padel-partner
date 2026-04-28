import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/controllers/app_controller.dart';
import '../models/friend.dart' show Subscription;

/// Wraps the `in_app_purchase` plugin for the Pro subscription.
///
/// Usage:
///   1. Call [init] once at app launch (in `main.dart`).
///   2. Call [buyPro] to initiate the purchase flow.
///   3. Listen on [results] for the outcome (success / cancel / error).
///
/// Store-side prerequisites — neither store will fulfill purchases until
/// these exist:
///   - Google Play Console: create a subscription with product ID
///     [proMonthlySku] at Rs 100/month, link it to a billing test account.
///   - App Store Connect: create an auto-renewable subscription with the same
///     product ID, agree to the Paid Apps agreement, set up sandbox testers.
///
/// In dev / web (no IAP backend reachable), [isAvailable] returns false and
/// the UI should fall back to a simulated upgrade so the dev flow keeps
/// working — see `_UpgradeConfirmSheetState._confirm`.
class BillingService {
  BillingService._();
  static final BillingService instance = BillingService._();

  /// Must match the subscription SKU configured in both stores.
  static const proMonthlySku = 'padel_pro_monthly';

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _resultsCtrl = StreamController<PurchaseResult>.broadcast();
  ProductDetails? _proProduct;

  /// Outcome stream. Emits one event per [buyPro] / [restorePurchases] cycle.
  Stream<PurchaseResult> get results => _resultsCtrl.stream;

  /// Subscribe to the global purchase stream once at app launch so pending
  /// purchases (e.g. resumed after an app restart) are still acknowledged
  /// and acted on, even if the upgrade sheet has been dismissed.
  Future<void> init() async {
    if (kIsWeb) return;
    bool available;
    try {
      available = await _iap.isAvailable();
    } catch (_) {
      return;
    }
    if (!available) return;
    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (e) => debugPrint('BillingService stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _resultsCtrl.close();
  }

  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _iap.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Initiates the Pro purchase flow. Returns true if the native sheet was
  /// shown; the actual outcome is delivered via [results]. Returns false (and
  /// emits an error on [results]) if the product isn't configured server-side.
  Future<bool> buyPro() async {
    if (!await isAvailable()) {
      _resultsCtrl.add(const PurchaseResult.error(
        'In-app purchases are not available on this device.',
      ));
      return false;
    }
    if (_proProduct == null) {
      final response = await _iap.queryProductDetails({proMonthlySku});
      if (response.notFoundIDs.contains(proMonthlySku) ||
          response.productDetails.isEmpty) {
        _resultsCtrl.add(const PurchaseResult.error(
          'Pro subscription is not configured in the store yet.',
        ));
        return false;
      }
      _proProduct = response.productDetails.first;
    }
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _proProduct!),
    );
  }

  /// For users who already paid on another device or after a reinstall.
  Future<void> restorePurchases() async {
    if (!await isAvailable()) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != proMonthlySku) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // TODO: server-side receipt verification before granting Pro in
          // production. Without it, a user can fake purchase tokens.
          AppController.to.subscription.value =
              const Subscription(plan: 'pro', daysLeft: 0);
          _resultsCtrl.add(const PurchaseResult.success());
          break;
        case PurchaseStatus.error:
          _resultsCtrl.add(PurchaseResult.error(
            p.error?.message ?? 'Purchase failed.',
          ));
          break;
        case PurchaseStatus.canceled:
          _resultsCtrl.add(const PurchaseResult.canceled());
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }
}

/// Discriminated union of purchase outcomes surfaced to the UI.
class PurchaseResult {
  const PurchaseResult.success()
      : kind = PurchaseResultKind.success,
        message = null;
  const PurchaseResult.canceled()
      : kind = PurchaseResultKind.canceled,
        message = null;
  const PurchaseResult.error(String msg)
      : kind = PurchaseResultKind.error,
        message = msg;

  final PurchaseResultKind kind;
  final String? message;
}

enum PurchaseResultKind { success, canceled, error }
