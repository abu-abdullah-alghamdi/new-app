import 'package:areem_clinics/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('تحويل الأرقام للعربية', () {
    expect(ar(2026), '2026');
    expect(en('٠٥٥١'), '0551');
  });

  test('تنسيق الوقت', () {
    expect(fmtTime(0), '4:00 م');
    expect(fmtTime(150), '6:30 م');
  });
}
