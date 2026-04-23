enum ActivityCategory {
  education,
  entertainment,
  social,
  neutral,
}

class ActivityClassifierService {
  const ActivityClassifierService._();

  static ActivityCategory classifyScreen(String screenName) {
    final normalizedScreenName = screenName.trim().toLowerCase();

    switch (normalizedScreenName) {
      case 'quiz':
      case 'learning':
      case 'lesson':
      case 'content':
        return ActivityCategory.education;
      case 'rewards':
      case 'reward':
      case 'game':
      case 'video':
        return ActivityCategory.entertainment;
      case 'chat':
      case 'social':
      case 'messages':
        return ActivityCategory.social;
      default:
        return ActivityCategory.neutral;
    }
  }

  static String toFirestoreValue(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.education:
        return 'Education';
      case ActivityCategory.entertainment:
        return 'Entertainment';
      case ActivityCategory.social:
        return 'Social';
      case ActivityCategory.neutral:
        return 'Neutral';
    }
  }
}
