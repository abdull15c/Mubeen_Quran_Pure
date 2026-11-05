import 'package:flutter_test/flutter_test.dart';
import 'package:mubeen_quran_pure/data/qf_api_service.dart';

void main() {
  group('QfApiService Tests', () {
    test('can be instantiated and disposed safely', () {
      final QfApiService service = QfApiService();
      expect(service, isNotNull);
      service.dispose();
    });
  });
}
