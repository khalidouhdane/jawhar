import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/services/ai_calibration_service.dart';

void main() {
  final service = AICalibrationService();

  test('requires a session interval boundary', () {
    expect(service.isCalibrationDue(6), isFalse);
    expect(service.isCalibrationDue(7), isTrue);
    expect(service.isCalibrationDue(14), isTrue);
  });

  test('does not recalibrate the same profile inside seven days', () {
    expect(
      service.isCalibrationDue(
        14,
        lastCalibrationDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
      isFalse,
    );
    expect(
      service.isCalibrationDue(
        14,
        lastCalibrationDate: DateTime.now().subtract(const Duration(days: 8)),
      ),
      isTrue,
    );
  });
}
