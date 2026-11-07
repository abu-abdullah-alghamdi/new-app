import 'package:areem_clinics/countries.dart';
import 'package:areem_clinics/data.dart';
import 'package:areem_clinics/services_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الأرقام بالإنجليزي', () {
    expect(fmtNum(2026), '2026');
    expect(normalizeDigits('٠٥٥١'), '0551');
  });

  test('تنسيق الوقت', () {
    expect(fmtTime(0), '4:00 م');
    expect(fmtTime(150), '6:30 م');
  });

  test('الجنسيات: السعودية أولها', () {
    expect(countries.first, saudiArabia);
    expect(countries.toSet().length, countries.length);
  });

  test('تنسيق المبالغ', () {
    expect(money(200), '200 ريال');
    expect(money(52.5), '52.50 ريال');
  });
}
