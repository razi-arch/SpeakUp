const badgeMilestones = <int, String>{
  10: 'badge_10',
  25: 'badge_25',
  50: 'badge_50',
  100: 'badge_100',
  200: 'badge_200',
  500: 'badge_500',
};

const badgeData = <String, (String, String)>{
  'badge_10': ('🌟', 'Star Collector'),
  'badge_25': ('🏅', 'Champion'),
  'badge_50': ('🦁', 'Brave Explorer'),
  'badge_100': ('🎯', 'Word Master'),
  'badge_200': ('🚀', 'Super Learner'),
  'badge_500': ('👑', 'Legend'),
};

int vocabStarsForAccuracy(double accuracy) {
  final pct = (accuracy * 100).round();
  if (pct >= 100) return 5;
  if (pct >= 80) return 4;
  if (pct >= 60) return 3;
  if (pct >= 40) return 2;
  return 1;
}

int speechStarsForReview(int reviewStars) =>
    reviewStars < 0 ? 0 : (reviewStars > 5 ? 5 : reviewStars);

List<String> unlockedBadgeIds({
  required int previousStars,
  required int newTotalStars,
  required List<String> existingBadges,
}) {
  if (newTotalStars <= previousStars) return const [];

  return badgeMilestones.entries
      .where((entry) => previousStars < entry.key && newTotalStars >= entry.key)
      .map((entry) => entry.value)
      .where((badgeId) => !existingBadges.contains(badgeId))
      .toList();
}
