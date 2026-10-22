import 'package:flutter/material.dart';
import '../main.dart' show AppLocalizations;

class Emotion {
  final String name;
  final Color color;
  final IconData icon;

  const Emotion({
    required this.name,
    required this.color,
    required this.icon,
  });

  static const List<Emotion> emotions = [
    Emotion(
      name: 'друзья',
      color: Color(0xFF2196F3), // Blue
      icon: Icons.people,
    ),
    Emotion(
      name: 'общение',
      color: Color(0xFF4CAF50), // Green
      icon: Icons.chat,
    ),
    Emotion(
      name: 'хобби',
      color: Color(0xFFFF9800), // Orange
      icon: Icons.sports_esports,
    ),
    Emotion(
      name: 'работа',
      color: Color(0xFFF44336), // Red
      icon: Icons.work,
    ),
    Emotion(
      name: 'природа',
      color: Color(0xFF8BC34A), // Light Green
      icon: Icons.nature,
    ),
    Emotion(
      name: 'отдых',
      color: Color(0xFF9C27B0), // Purple
      icon: Icons.beach_access,
    ),
    Emotion(
      name: 'неожиданные события',
      color: Color(0xFFFFEB3B), // Yellow
      icon: Icons.star,
    ),
    Emotion(
      name: 'любовь',
      color: Color(0xFFE91E63), // Pink
      icon: Icons.favorite,
    ),
    Emotion(
      name: 'творчество',
      color: Color(0xFF00BCD4), // Cyan
      icon: Icons.brush,
    ),
    Emotion(
      name: 'достижения',
      color: Color(0xFF795548), // Brown
      icon: Icons.emoji_events,
    ),
    Emotion(
      name: 'любовный интерес',
      color: Color(0xFF009688), // Teal
      icon: Icons.favorite_border,
    ),
  ];

  static Emotion getByName(String name) {
    return emotions.firstWhere(
      (emotion) => emotion.name == name,
      orElse: () => emotions.first,
    );
  }

  static String displayName(BuildContext context, String storedName) {
    final l10n = AppLocalizations.of(context);
    switch (storedName) {
      case 'друзья':
        return l10n.emotionFriends;
      case 'общение':
        return l10n.emotionCommunication;
      case 'хобби':
        return l10n.emotionHobby;
      case 'работа':
        return l10n.emotionWork;
      case 'природа':
        return l10n.emotionNature;
      case 'отдых':
        return l10n.emotionRest;
      case 'неожиданные события':
        return l10n.emotionUnexpectedEvents;
      case 'любовь':
        return l10n.emotionLove;
      case 'творчество':
        return l10n.emotionCreativity;
      case 'достижения':
        return l10n.emotionAchievements;
      case 'любовный интерес':
        return l10n.emotionRomanticInterest;
      default:
        return storedName;
    }
  }
} 