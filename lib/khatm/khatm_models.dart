import 'dart:convert';
import 'dart:math' as math;

final class KhatmPlan {
  const KhatmPlan({
    required this.id,
    required this.title,
    required this.targetDays,
    required this.startDate,
    required this.completedPages,
    this.lastReadDate,
  });

  final String id;
  final String title;
  final int targetDays;
  final DateTime startDate;
  final Set<int> completedPages;
  final DateTime? lastReadDate;

  int get totalPages => 604;
  int get completedCount => completedPages.length;
  double get progressPercentage =>
      (completedCount / totalPages).clamp(0.0, 1.0);
  int get progressPercentInt => (progressPercentage * 100).round();
  bool get isCompleted => completedCount >= totalPages;

  int get daysPassed {
    final DateTime now = DateTime.now();
    return now.difference(startDate).inDays.clamp(0, 365);
  }

  int get daysRemaining => math.max(1, targetDays - daysPassed);

  int get dailyTargetPages {
    final int remainingPages = math.max(0, totalPages - completedCount);
    return (remainingPages / daysRemaining).ceil();
  }

  KhatmPlan markPage(int page) {
    if (page < 1 || page > 604) return this;
    final Set<int> updated = Set<int>.from(completedPages)..add(page);
    return KhatmPlan(
      id: id,
      title: title,
      targetDays: targetDays,
      startDate: startDate,
      completedPages: updated,
      lastReadDate: DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'target_days': targetDays,
      'start_date': startDate.toIso8601String(),
      'completed_pages': completedPages.toList(),
      'last_read_date': lastReadDate?.toIso8601String(),
    };
  }

  factory KhatmPlan.fromMap(Map<String, Object?> map) {
    final List<dynamic> pagesRaw =
        (map['completed_pages'] as List<dynamic>?) ?? <dynamic>[];
    final Set<int> pages = pagesRaw
        .map((dynamic e) => e is int ? e : int.tryParse(e.toString()))
        .whereType<int>()
        .where((int p) => p >= 1 && p <= 604)
        .toSet();

    return KhatmPlan(
      id: (map['id'] as String?) ?? 'default_khatm',
      title: (map['title'] as String?) ?? 'Хатм за 30 дней',
      targetDays: (map['target_days'] as int?) ?? 30,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : DateTime.now(),
      completedPages: pages,
      lastReadDate: map['last_read_date'] != null
          ? DateTime.parse(map['last_read_date'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory KhatmPlan.fromJson(String jsonStr) =>
      KhatmPlan.fromMap(jsonDecode(jsonStr) as Map<String, Object?>);
}
