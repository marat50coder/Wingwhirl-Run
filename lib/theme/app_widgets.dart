import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Wraps a child so it scales down while pressed (juicy button feel).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Primary gradient action button with glow and icon support.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.gradient,
    this.width,
    this.height = 54,
    this.fontSize = 20,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double height;
  final double fontSize;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? AppColors.goldButton;
    return PressableScale(
      enabled: enabled,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: g,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
          boxShadow: [
            BoxShadow(
              color: (g.colors.last).withValues(alpha: 0.55),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: fontSize + 4),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title(fontSize),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Frosted translucent panel with gradient border.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          // Provide a Material ancestor so Material widgets (Switch, etc.) and
          // default text styling work when the panel is shown inside a dialog.
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// Small stat chip used in the HUD (coins, counts, etc).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    this.icon,
    this.iconAsset,
    this.color = AppColors.gold,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final String? iconAsset;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.waterDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.6),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null)
            Image.asset(iconAsset!, width: 26, height: 26)
          else
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          const SizedBox(width: 6),
          Text(label, style: AppText.heavy(16, color: Colors.white)),
        ],
      ),
    );
    if (onTap == null) return chip;
    return PressableScale(onTap: onTap, child: chip);
  }
}

/// Animated gradient progress bar with glow around the filled part.
class GlowProgressBar extends StatelessWidget {
  const GlowProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.gradient,
    this.animate = true,
  });

  final double value; // 0..1
  final double height;
  final Gradient? gradient;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final g = gradient ??
        const LinearGradient(colors: [AppColors.gold, AppColors.coral]);
    return LayoutBuilder(builder: (context, c) {
      final clamped = value.clamp(0.0, 1.0);
      final fill = c.maxWidth * clamped;
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: Duration(milliseconds: animate ? 350 : 0),
            curve: Curves.easeOut,
            width: fill,
            decoration: BoxDecoration(
              gradient: g,
              borderRadius: BorderRadius.circular(height),
              boxShadow: [
                BoxShadow(
                  color: g.colors.last.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Colored rarity pill.
class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.fontSize = 12});
  final Rarity rarity;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7, vertical: 2),
      decoration: BoxDecoration(
        color: rarity.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: rarity.color.withValues(alpha: 0.6), blurRadius: 8),
        ],
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppText.display,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Round icon button used for back / close / settings.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.gradient,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.blueButton,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
          boxShadow: kSoftShadow,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

/// A soft heading label with a small underline accent.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
        ],
        Text(title, style: AppText.title(26)),
      ],
    );
  }
}
