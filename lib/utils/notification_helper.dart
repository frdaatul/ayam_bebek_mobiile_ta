import 'package:flutter/material.dart';

class NotificationHelper {
  static OverlayEntry? _currentOverlayEntry;

  static void show(
    BuildContext context, 
    dynamic message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Hapus notifikasi lama jika ada
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    String? title;
    List<String> messages = [];

    if (message is String) {
      messages.add(message);
    } else if (message is List) {
      messages = message.map((e) => e.toString()).toList();
    } else if (message is Map) {
      title = message['title']?.toString();
      if (message['list'] is List) {
        messages = (message['list'] as List).map((e) => e.toString()).toList();
      } else if (message['message'] != null) {
        messages.add(message['message'].toString());
      }
    }

    // Animation logic
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: Navigator.of(context),
    );

    final slideInAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2), // Mulai dari atas layar
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        right: 15,
        left: 15,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: slideInAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.red[600] : Colors.green[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ...messages.map((msg) => Text(
                          msg,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      controller.reverse().then((_) {
                        if (overlayEntry.mounted) {
                          overlayEntry.remove();
                          if (_currentOverlayEntry == overlayEntry) {
                            _currentOverlayEntry = null;
                          }
                        }
                      });
                    },
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _currentOverlayEntry = overlayEntry;
    overlay.insert(overlayEntry);
    controller.forward();

    // Auto hide
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        controller.reverse().then((_) {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
            if (_currentOverlayEntry == overlayEntry) {
              _currentOverlayEntry = null;
            }
          }
        });
      }
    });
  }
}
