import 'package:flutter/material.dart';

/// Shared color + gradient constants for all FOMI Store screens.
/// Use these in every shop-related screen to guarantee visual consistency.
class SC {
  // ─── Palette ───────────────────────────────────────────────────────────────
  static const red = Color(0xFFD32F2F);
  static const redDark = Color(0xFFB71C1C);
  static const redLight = Color(0xFFFFEBEE);
  static const redSoft = Color(0xFFFFCDD2);
  static const bg = Color(0xFFF5F5F5);
  static const white = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFFE8F5E9);

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const redGradient = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> redShadow = [
    BoxShadow(
      color: red.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 5),
    ),
  ];
}

/// Shared widget helpers used across all shop screens.
class ShopWidgets {
  /// Red gradient app-bar / header container.
  static Widget header({
    required Widget child,
    required double topPadding,
    Color? bg,
  }) {
    return Container(
      color: bg ?? SC.white,
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: 20,
        right: 16,
        bottom: 14,
      ),
      child: child,
    );
  }

  /// Back button with white circle background.
  static Widget backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: SC.redLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: SC.red),
      ),
    );
  }

  /// Red primary button.
  static Widget primaryButton({
    required String label,
    required VoidCallback? onTap,
    double verticalPad = 14,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: verticalPad),
        decoration: BoxDecoration(
          gradient: onTap != null ? SC.redGradient : null,
          color: onTap == null ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: onTap != null ? SC.redShadow : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: SC.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: SC.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Red-outlined secondary button.
  static Widget outlinedButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: SC.white,
          border: Border.all(color: SC.red, width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SC.red,
            ),
          ),
        ),
      ),
    );
  }

  /// Small badge used on product images / cards.
  static Widget fomiBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: SC.redDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 8, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Terhubung ke FOMI',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
