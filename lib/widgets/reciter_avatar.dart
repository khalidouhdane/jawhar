import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Circular reciter avatar: photo when we have one bundled, themed initials
/// otherwise. Single source of truth for the reciter popup, the now-playing
/// pill, and the playback sheet.
class ReciterAvatar extends StatelessWidget {
  final int reciterId;
  final String reciterName;
  final double size;

  const ReciterAvatar({
    super.key,
    required this.reciterId,
    required this.reciterName,
    this.size = 44,
  });

  /// Reciter IDs that have an image in assets/images/reciters/
  static const imageIds = <int>{
    1, 2, 3, 4, 5, 6, 7, 12, 13, 19, //
    97, 158, 159, 160, 161, 173, 174, 175,
  };

  /// Build initials from a reciter name (first + last).
  static String initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    if (imageIds.contains(reciterId)) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: theme.pillBackground,
        backgroundImage: AssetImage('assets/images/reciters/$reciterId.jpg'),
        onBackgroundImageError: (e, _) {
          AppLogger.info(
            'ReciterAvatar',
            '[ReciterImage] Asset decode error for $reciterId',
          );
        },
      );
    }

    // Fallback: themed initials circle
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.inputFill,
      child: Text(
        initials(reciterName),
        style: TextStyle(
          color: theme.mutedText,
          // Scales with the avatar (16pt at the menu's 44px reference size).
          fontSize: size * 16 / 44,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
