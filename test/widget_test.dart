import 'package:areem_clinics/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('تحويل الأرقام للعربية', () {
    expect(ar(2026), '٢٠٢٦');
    expect(en('٠٥٥١'), '0551');
  });

  test('تنسيق الوقت', () {
    expect(fmtTime(0), '٤:٠٠ م');
    expect(fmtTime(150), '٦:٣٠ م');
  });
}
