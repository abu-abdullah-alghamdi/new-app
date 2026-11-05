import 'package:flutter/widgets.dart';

import 'data.dart';

/// حالة التطبيق العامة
class AppState extends ChangeNotifier {
  AppState() {
    var up = 3;
    if (DayInfo(up).closed) up = 4;
    var past = -2;
    if (DayInfo(past).closed) past = -3;
    bookings = [
      Booking(id: 'seed1', doctorId: 'd2', cat: 'ortho', dayIndex: up, time: 120),
      Booking(id: 'seed2', doctorId: 'd4', cat: 'derma', dayIndex: past, time: 60),
    ];
  }

  // المستخدم
  String name = '';
  String phone = '';
  bool loggedIn = false;
  bool remindOnWhatsapp = true;

  // التبويب الحالي في الشريط العائم: 0 الرئيسية، 1 مواعيدي، 2 الأطباء، 3 حسابي
  int tab = 0;

  late List<Booking> bookings;

  String get firstName {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? '' : parts.first;
  }

  String get initial => firstName.isNotEmpty ? firstName.characters.first : 'أ';

  List<Booking> get sorted {
    final list = [...bookings];
    list.sort((a, b) {
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      if (a.completed) {
        final c = b.dayIndex.compareTo(a.dayIndex);
        return c != 0 ? c : b.time.compareTo(a.time);
      }
      final c = a.dayIndex.compareTo(b.dayIndex);
      return c != 0 ? c : a.time.compareTo(b.time);
    });
    return list;
  }

  List<Booking> get upcoming => sorted.where((b) => !b.completed).toList();
  int get completedCount => bookings.where((b) => b.completed).length;

  // فلتر التخصص في صفحة الأطباء
  String? doctorCat;

  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void openDoctors([String? cat]) {
    doctorCat = cat;
    tab = 2;
    notifyListeners();
  }

  void setDoctorCat(String? cat) {
    doctorCat = cat;
    notifyListeners();
  }

  void login(String nationalNumber) {
    phone = '0$nationalNumber';
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    name = '';
    phone = '';
    loggedIn = false;
    tab = 0;
    notifyListeners();
  }

  /// حذف الحساب: يمسح بيانات المستخدم ومواعيده من التطبيق
  void deleteAccount() {
    name = '';
    phone = '';
    loggedIn = false;
    tab = 0;
    bookings.clear();
    notifyListeners();
  }

  void setProfile({required String name, required String phone}) {
    this.name = name;
    this.phone = phone;
    notifyListeners();
  }

  void toggleRemind() {
    remindOnWhatsapp = !remindOnWhatsapp;
    notifyListeners();
  }

  Booking addBooking({required String doctorId, required String cat, required int day, required int time}) {
    final b = Booking(
      id: 'b${DateTime.now().microsecondsSinceEpoch}',
      doctorId: doctorId,
      cat: cat,
      dayIndex: day,
      time: time,
    );
    bookings.add(b);
    notifyListeners();
    return b;
  }

  Booking updateBooking(String id, {required String doctorId, required String cat, required int day, required int time}) {
    final b = bookings.firstWhere((x) => x.id == id);
    b
      ..doctorId = doctorId
      ..cat = cat
      ..dayIndex = day
      ..time = time;
    notifyListeners();
    return b;
  }

  void cancelBooking(String id) {
    bookings.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}

/// يوفّر الحالة لكل الشاشات ويعيد بنائها عند التغيير
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
