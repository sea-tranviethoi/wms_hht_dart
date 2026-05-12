import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/audio/sound_manager.dart';

/// Port từ components/Notification.js — VerifyNotification
/// Dialog đa năng: thông báo, xác nhận, download progress
class VerifyNotification extends StatelessWidget {
  final bool visible;
  final String title;
  final String message;
  final int numberButton;       // 1 hoặc 2
  final NotifyButton? btn1;
  final NotifyButton? btn2;
  final bool showProgress;      // = extend trong RN
  final double progressValue;   // 0.0 → 1.0
  final String? soundType;      // 'error' | 'correct' | 'warning'

  const VerifyNotification({
    super.key,
    required this.visible,
    required this.title,
    required this.message,
    this.numberButton = 1,
    this.btn1,
    this.btn2,
    this.showProgress = false,
    this.progressValue = 0,
    this.soundType,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    // Play sound
    if (soundType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (soundType) {
          case 'error':
            SoundManager.instance.playError();
          case 'correct':
            SoundManager.instance.playCorrect();
          case 'warning':
            SoundManager.instance.playWarning();
        }
      });
    }

    return Stack(
      children: [
        // Overlay mờ
        const Opacity(
          opacity: 0.6,
          child: ModalBarrier(dismissible: false, color: AppColors.black),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadowLight, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'MSPGothic',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'MSPGothic',
                      fontSize: 14,
                      color: AppColors.grayTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Progress bar (OTA download)
                  if (showProgress) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: AppColors.light,
                      color: AppColors.btnGreen,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progressValue * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'MSPGothic',
                        fontSize: 12,
                        color: AppColors.grayTextColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    mainAxisAlignment: numberButton == 1
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceEvenly,
                    children: [
                      if (numberButton == 2 && btn2 != null)
                        _buildButton(btn2!),
                      if (btn1 != null) _buildButton(btn1!),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(NotifyButton btn) {
    return ElevatedButton(
      onPressed: btn.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btn.color ?? AppColors.btnBlue,
        foregroundColor: AppColors.white,
        minimumSize: const Size(100, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        btn.text,
        style: const TextStyle(fontFamily: 'MSPGothic', fontSize: 14),
      ),
    );
  }
}

/// Model cho nút bấm trong VerifyNotification
class NotifyButton {
  final String text;
  final Color? color;
  final VoidCallback onPressed;

  const NotifyButton({
    required this.text,
    required this.onPressed,
    this.color,
  });
}
