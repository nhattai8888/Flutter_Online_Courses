import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool haptic = true,
    bool clearPrevious = true,
  }) {
    if (message.trim().isEmpty) return;

    // ✅ tránh lỗi "called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      final cs = Theme.of(context).colorScheme;
      final cfg = _ToastConfig.from(type, cs);

      if (haptic) {
        // nhẹ thôi, đúng kiểu mobile
        HapticFeedback.selectionClick();
      }

      final messenger = ScaffoldMessenger.of(context);
      if (clearPrevious) messenger.clearSnackBars();

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          backgroundColor: cfg.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              Icon(cfg.icon, color: cfg.fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: cfg.fg,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Đóng',
            textColor: cfg.fg.withOpacity(0.95),
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
    });
  }
}

class _ToastConfig {
  final Color bg;
  final Color fg;
  final IconData icon;

  _ToastConfig({required this.bg, required this.fg, required this.icon});

  factory _ToastConfig.from(AppToastType type, ColorScheme cs) {
    switch (type) {
      case AppToastType.success:
        return _ToastConfig(
          bg: const Color(0xFF16A34A), // green
          fg: Colors.white,
          icon: Icons.check_circle_rounded,
        );
      case AppToastType.error:
        return _ToastConfig(
          bg: cs.error,
          fg: Colors.white,
          icon: Icons.error_rounded,
        );
      case AppToastType.warning:
        return _ToastConfig(
          bg: const Color(0xFFF59E0B), // amber
          fg: const Color(0xFF111827),
          icon: Icons.warning_rounded,
        );
      case AppToastType.info:
      default:
        return _ToastConfig(
          bg: cs.primary,
          fg: Colors.white,
          icon: Icons.info_rounded,
        );
    }
  }
}
