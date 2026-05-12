import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLoading extends StatelessWidget {
  final double size;
  final String? message;
  final Color? color;

  const AppLoading({super.key, this.size = 32, this.message, this.color});

  factory AppLoading.compact({Color? color}) =>
      AppLoading(size: 24, color: color);

  factory AppLoading.centered({String? message}) =>
      AppLoading(size: 36, message: message);

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
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(c),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                fontFamily: 'MSPGothic',
                color: AppColors.grayTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
