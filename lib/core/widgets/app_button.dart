import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppColors.primary;
    final effectiveTextColor = textColor ?? Colors.white;

    final child = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveTextColor,
        disabledBackgroundColor: effectiveBackgroundColor.withAlpha(180),
        disabledForegroundColor: effectiveTextColor.withAlpha(200),
        minimumSize: Size(isFullWidth ? double.infinity : 120, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
              ),
            )
          : Text(label),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: child,
      );
    }

    return SizedBox(
      height: height,
      child: child,
    );
  }
}
