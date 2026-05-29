import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class AppLoading extends StatelessWidget {
  final double size;
  final String? message;
  final Color? color;

  const AppLoading({super.key, this.size = AppStyles.sizeSpinner, this.message, this.color});

  factory AppLoading.compact({Color? color}) =>
      AppLoading(size: AppStyles.sizeSpinner, color: color);

  factory AppLoading.centered({String? message}) =>
      AppLoading(size: AppStyles.sizeSpinner, message: message);

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: AppStyles.widthSpinnerStroke,
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                fontFamily: AppStyles.font,
                color: AppColors.grayTextColor,
                fontSize: AppStyles.sizeCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
