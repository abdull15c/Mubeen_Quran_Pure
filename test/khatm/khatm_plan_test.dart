import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/khatm/khatm_models.dart';

void main() {
  group('KhatmPlan Tests', () {
    test('Calculates progress percentage and daily target accurately', () {
      final KhatmPlan plan = KhatmPlan(
        id: 'test_khatm',
        title: 'Хатм за 30 дней',
        targetDays: 30,
        startDate: DateTime.now(),
        completedPages: <int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
      );

      expect(plan.completedCount, 10);
      expect(plan.totalPages, 604);
      expect(plan.progressPercentage, closeTo(10 / 604, 0.001));
      expect(plan.dailyTargetPages, (594 / 30).ceil());
      expect(plan.isCompleted, false);
    });

    test('Marks page as completed and serializes to JSON', () {
      final KhatmPlan plan = KhatmPlan(
        id: 'plan_1',
        title: 'Рамадан Хатм',
        targetDays: 30,
        startDate: DateTime.now(),
        completedPages: <int>{1},
      );

      final KhatmPlan updated = plan.markPage(2);
      expect(updated.completedPages.contains(2), true);
      expect(updated.completedCount, 2);

      final String json = updated.toJson();
      final KhatmPlan fromJson = KhatmPlan.fromJson(json);

      expect(fromJson.id, 'plan_1');
      expect(fromJson.title, 'Рамадан Хатм');
      expect(fromJson.completedPages.length, 2);
    });

    test('Rejects out-of-bounds page numbers (<1 or >604)', () {
      final Map<String, Object?> corruptMap = {
        'id': 'corrupt_plan',
        'title': 'Test',
        'target_days': 30,
        'completed_pages': [-5, 0, 1, 604, 605, 999],
      };

      final KhatmPlan plan = KhatmPlan.fromMap(corruptMap);
      // Only 1 and 604 are valid pages!
      expect(plan.completedPages, equals(<int>{1, 604}));
      expect(plan.completedCount, 2);

      final KhatmPlan cannotAddNegative = plan.markPage(-1);
      expect(cannotAddNegative.completedCount, 2);

      final KhatmPlan cannotAdd605 = plan.markPage(605);
      expect(cannotAdd605.completedCount, 2);
    });
  });
}
