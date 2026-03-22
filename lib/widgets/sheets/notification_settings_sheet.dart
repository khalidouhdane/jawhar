import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/notification_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// Bottom sheet for configuring daily Hifz session reminder notifications.
class NotificationSettingsSheet extends StatelessWidget {
  const NotificationSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final notif = context.watch<NotificationProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Title ──
          Row(
            children: [
              Icon(LucideIcons.bell, size: 20, color: theme.accentColor),
              const SizedBox(width: 10),
              Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Get reminded to complete your daily Hifz session.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 24),

          // ── Enable Toggle ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.bellRing, size: 18, color: theme.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Reminder',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        notif.isEnabled
                            ? 'Reminder set for ${notif.reminderTimeFormatted}'
                            : 'Off',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: notif.isEnabled,
                  onChanged: notif.isSupported
                      ? (val) => notif.toggleNotifications(val)
                      : null,
                  activeColor: theme.accentColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Time Picker ──
          if (notif.isEnabled) ...[
            GestureDetector(
              onTap: () => _pickTime(context, theme, notif),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, size: 18, color: theme.accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reminder Time',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                          Text(
                            notif.reminderTimeFormatted,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: theme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: theme.mutedText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Smart Skip Info ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Smart skip: You won\'t be notified if you\'ve already completed today\'s session.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Desktop Warning ──
          if (!notif.isSupported) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.monitor,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Push notifications are available on mobile devices only. Your settings will be saved for when you use the app on your phone.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    ThemeProvider theme,
    NotificationProvider notif,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: notif.reminderTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.accentColor,
              surface: theme.cardColor,
              onSurface: theme.primaryText,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.cardColor,
              dialHandColor: theme.accentColor,
              hourMinuteTextColor: theme.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await notif.setReminderTime(picked);
    }
  }
}
