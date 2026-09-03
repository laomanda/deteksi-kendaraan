import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

enum RideCareButtonVariant {
  primary,
  secondary,
  critical,
  outline,
}

/// RideCare standard button with subtle 0.98x press downscale (DSS Table 8 & 10)
class RideCareButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final RideCareButtonVariant variant;
  final double height;
  final bool isFullWidth;
  final bool isLoading;

  const RideCareButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = RideCareButtonVariant.primary,
    this.height = 48.0,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  State<RideCareButton> createState() => _RideCareButtonState();
}

class _RideCareButtonState extends State<RideCareButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.variant) {
      case RideCareButtonVariant.primary:
        bgColor = isEnabled ? AppColors.primaryBlue : AppColors.surfaceSubtle;
        fgColor = isEnabled ? Colors.white : AppColors.textMuted;
        break;
      case RideCareButtonVariant.secondary:
        bgColor = AppColors.surfaceSubtle;
        fgColor = isEnabled ? AppColors.primaryBlue : AppColors.textMuted;
        break;
      case RideCareButtonVariant.critical:
        bgColor = isEnabled ? AppColors.healthCritical : AppColors.surfaceSubtle;
        fgColor = isEnabled ? Colors.white : AppColors.textMuted;
        break;
      case RideCareButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = isEnabled ? AppColors.primaryBlue : AppColors.textMuted;
        border = Border.all(
          color: isEnabled ? AppColors.borderSubtle : AppColors.surfaceSubtle,
          width: 1.0,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fgColor),
          const SizedBox(width: AppSpacing.space8),
        ],
        Text(
          widget.text,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: isEnabled ? widget.onPressed : null,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppSpacing.buttonBorderRadius,
            border: border,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
