import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:oktoast/oktoast.dart';

/// A tappable banner at the top for a customer-service reply that arrives
/// while the app is open on another screen.
void showSupportReplyBanner(String body, VoidCallback onTap) {
  showToastWidget(
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              dismissAllToast();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.support_agent_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('خدمة عملاء Goal Master',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF687469))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    dismissOtherToast: true,
    handleTouch: true,
    position: ToastPosition.top,
    duration: const Duration(seconds: 6),
  );
}
