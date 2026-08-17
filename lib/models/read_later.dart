import 'saved_url.dart';

class ReadLaterQueue {
  const ReadLaterQueue({
    required this.totalCount,
    required this.totalMinutes,
    required this.todaysThreeMinutes,
    required this.todaysThree,
    required this.fiveMinutes,
    required this.sitDown,
  });

  factory ReadLaterQueue.fromJson(Map<String, dynamic> json) {
    List<SavedUrl> items(String key) => (json[key] as List<dynamic>)
        .map((e) => SavedUrl.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReadLaterQueue(
      totalCount: (json['totalCount'] as num).toInt(),
      totalMinutes: (json['totalMinutes'] as num).toInt(),
      todaysThreeMinutes: (json['todaysThreeMinutes'] as num).toInt(),
      todaysThree: items('todaysThree'),
      fiveMinutes: items('fiveMinutes'),
      sitDown: items('sitDown'),
    );
  }

  final int totalCount;
  final int totalMinutes;
  final int todaysThreeMinutes;
  final List<SavedUrl> todaysThree;
  final List<SavedUrl> fiveMinutes;
  final List<SavedUrl> sitDown;
}

class ReadLaterDayStat {
  const ReadLaterDayStat({required this.count, required this.heightPct});

  factory ReadLaterDayStat.fromJson(Map<String, dynamic> json) {
    return ReadLaterDayStat(
      count: (json['count'] as num).toInt(),
      heightPct: (json['heightPct'] as num).toDouble(),
    );
  }

  final int count;
  final double heightPct;
}

class ReadLaterStats {
  const ReadLaterStats({
    required this.days,
    required this.readThisWeek,
    required this.savedThisWeek,
  });

  factory ReadLaterStats.fromJson(Map<String, dynamic> json) {
    return ReadLaterStats(
      days: (json['days'] as List<dynamic>)
          .map((e) => ReadLaterDayStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      readThisWeek: (json['readThisWeek'] as num).toInt(),
      savedThisWeek: (json['savedThisWeek'] as num).toInt(),
    );
  }

  final List<ReadLaterDayStat> days;
  final int readThisWeek;
  final int savedThisWeek;
}
