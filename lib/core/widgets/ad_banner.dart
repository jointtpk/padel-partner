import 'package:flutter/material.dart';
import '../theme/tokens.dart';

// Placeholder ad banners — in production replace with real ad network SDK widgets
class AdBanner extends StatelessWidget {
  const AdBanner({super.key, this.variant = 'sport'});

  final String variant; // 'sport' | 'court'

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      'court' => _CourtAd(),
      _       => _SportAd(),
    };
  }
}

class _SportAd extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: const Center(child: Text('🎾', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upgrade your game', style: AppFonts.display(13, color: AppColors.ink)),
                Text('Get Padel Partner Pro — unlimited games', style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.60))),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('AD', style: AppFonts.mono(9, color: AppColors.ball.withOpacity(0.70))),
          ),
        ],
      ),
    );
  }
}

class _CourtAd extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue900, AppColors.blue800],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book a spot in seconds', style: AppFonts.display(13, color: Colors.white)),
                Text('Padel Up Karachi · from Rs 2,400/hr', style: AppFonts.body(11, color: Colors.white.withOpacity(0.65))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.ball, borderRadius: BorderRadius.circular(999)),
            child: Text('BOOK', style: AppFonts.display(11, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key, required this.daysLeft, required this.onUpgrade});

  final int daysLeft;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.ball,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text('⚡', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$daysLeft days of free trial left',
                  style: AppFonts.display(13, color: AppColors.ink),
                ),
                Text(
                  'Then Rs 100/month. Cancel anytime.',
                  style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.70)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUpgrade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('UPGRADE', style: AppFonts.display(11, color: AppColors.ball, letterSpacing: 0.55)),
            ),
          ),
        ],
      ),
    );
  }
}
