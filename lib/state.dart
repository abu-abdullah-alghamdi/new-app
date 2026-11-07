import 'package:flutter/widgets.dart';

import 'countries.dart';
import 'data.dart';
import 'native.dart';
import 'payments.dart';
import 'services_data.dart';

/// المعلومات الشخصية للمستخدم
class Profile {
  const Profile({
    required this.name,
    required this.idNumber,
    required this.gender,
    required this.birthDate,
    required this.nationality,
    required this.phone,
    this.email = '',
  });

  final String name;
  final String idNumber;

  /// 'm' ذكر، 'f' أنثى
  final String gender;
  final DateTime birthDate;
  final String nationality;
  final String phone;
  final String email;
}

/// عنصر في طلب (خدمة وكميتها)
class OrderItem {
  const OrderItem(this.service, this.qty);

  final Service service;
  final int qty;

  int get total => service.finalPrice * qty;
}

/// طلب خدمات مدفوع (أو الدفع في العيادة)
class Order {
  const Order({
    required this.number,
    required this.items,
    required this.branchId,
    required this.subtotal,
    required this.vat,
    required this.method,
    required this.date,
    required this.reference,
    this.cardLast4,
  });

  final String number;
  final List<OrderItem> items;
  final String branchId;
  final int subtotal;
  final double vat;
  final PayMethod method;
  final DateTime date;
  final String reference;

  /// آخر 4 أرقام من البطاقة (لو الدفع ببطاقة)
  final String? cardLast4;

  double get total => subtotal + vat;

  /// طريقة الدفع للعرض: "مدى ···· 4821"
  String get methodText => cardLast4 == null ? method.label : '${method.label} ···· $cardLast4';

  /// مدفوع فعلاً من التطبيق (مو الدفع في العيادة)
  bool get paidOnline => method != PayMethod.cash;
  int get count => items.fold(0, (a, b) => a + b.qty);
}

/// أكبر كمية للخدمة الوحدة في السلة
const maxQty = 20;

/// حالة التطبيق العامة
class AppState extends ChangeNotifier {
  /// يبدأ بموعدين تجريبيين: واحد قادم وواحد مكتمل (بعيد عن يوم الجمعة)
  AppState() {
    final up = DayInfo(3).closed ? 4 : 3;
    final past = DayInfo(-2).closed ? -3 : -2;
    bookings.addAll([
      Booking(id: 'seed1', doctorId: 'd2', cat: 'ortho', dayIndex: up, time: 120, branchId: 'rawdah'),
      Booking(id: 'seed2', doctorId: 'd4', cat: 'derma', dayIndex: past, time: 60, branchId: 'hamdaniyah'),
    ]);
  }

  /// يزيد مع كل تغيير (نستخدمه عشان التبويب الظاهر بس يعيد رسم نفسه)
  int version = 0;

  @override
  void notifyListeners() {
    version++;
    super.notifyListeners();
  }

  // المستخدم
  String name = '';
  String phone = '';
  bool loggedIn = false;
  bool remindOnWhatsapp = true;
  Profile? profile;

  /// الحسابات المسجلة على هذا الجهاز (للتجربة، بدل الخادم): رقم الجوال ← المعلومات
  final Map<String, Profile> _accounts = {};

  bool hasAccount(String phone) => _accounts.containsKey(phone);

  /// طلبات كل حساب (ترجع لما يسجّل دخوله مرة ثانية)
  final Map<String, List<Order>> _savedOrders = {};

  // التبويب الحالي في الشريط العائم:
  // 0 الرئيسية، 1 مواعيدي، 2 الأطباء، 3 حسابي، 4 الخدمات
  int tab = 0;

  // السلة: رقم الخدمة ← الكمية
  final Map<String, int> cart = {};
  final List<Order> orders = [];

  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  List<OrderItem> get cartItems => [for (final e in cart.entries) OrderItem(serviceById(e.key), e.value)];
  int get cartSubtotal => cartItems.fold(0, (a, b) => a + b.total);
  double get cartVat => vatFor(cartSubtotal);
  double get cartTotal => cartSubtotal + cartVat;

  /// ضريبة القيمة المضافة: المواطن السعودي ما عليه ضريبة على الخدمات الصحية الخاصة، والمقيم 15%.
  /// الزائر ما تنحسب له لين يسجّل (الدفع يحتاج تسجيل دخول أصلاً)
  bool get chargesVat => loggedIn && profile != null && profile!.nationality != saudiArabia;

  double vatFor(int subtotal) => chargesVat ? subtotal * vatRate : 0;

  void addToCart(String serviceId, {int qty = 1}) {
    cart[serviceId] = ((cart[serviceId] ?? 0) + qty).clamp(1, maxQty);
    notifyListeners();
  }

  // المفضلة (تشتغل للزائر أيضاً)
  final Set<String> favDoctors = {};
  final Set<String> favServices = {};

  void toggleFavDoctor(String id) {
    if (!favDoctors.remove(id)) favDoctors.add(id);
    notifyListeners();
  }

  void toggleFavService(String id) {
    if (!favServices.remove(id)) favServices.add(id);
    notifyListeners();
  }

  void setQty(String serviceId, int qty) {
    if (qty <= 0) {
      cart.remove(serviceId);
    } else {
      cart[serviceId] = qty.clamp(1, maxQty);
    }
    notifyListeners();
  }

  void removeFromCart(String serviceId) {
    cart.remove(serviceId);
    notifyListeners();
  }

  Order placeOrder({
    required List<OrderItem> items,
    required String branchId,
    required PayMethod method,
    required String reference,
    String? cardLast4,
    bool clearCart = false,
  }) {
    final subtotal = items.fold(0, (a, b) => a + b.total);
    final o = Order(
      number: '${10240 + orders.length + 1}',
      items: items,
      branchId: branchId,
      subtotal: subtotal,
      vat: vatFor(subtotal),
      method: method,
      date: DateTime.now(),
      reference: reference,
      cardLast4: cardLast4,
    );
    orders.insert(0, o);
    if (clearCart) cart.clear();
    notifyListeners();
    return o;
  }

  final List<Booking> bookings = [];

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

  /// المواعيد القادمة الفعلية (بدون اللي ألغتها العيادة)
  List<Booking> get upcoming => sorted.where((b) => !b.completed && !b.cancelledByClinic).toList();

  /// الطلب اللي دُفع فيه الموعد (لو موجود)
  Order? orderFor(Booking b) {
    for (final o in orders) {
      if (o.number == b.orderNumber) return o;
    }
    return null;
  }

  /// موعد ثاني قادم مع نفس الطبيب في نفس اليوم (للتنبيه قبل الحجز المكرر)
  Booking? sameDayBooking(String doctorId, int day) {
    for (final b in upcoming) {
      if (b.doctorId == doctorId && b.dayIndex == day) return b;
    }
    return null;
  }
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

  // فلتر صفحة الخدمات (null = الكل)
  String? serviceCatFilter;

  void openServices([String? cat]) {
    serviceCatFilter = cat;
    tab = 4;
    notifyListeners();
  }

  void setServiceCat(String? cat) {
    serviceCatFilter = cat;
    notifyListeners();
  }

  /// دخول رقم مسجّل من قبل (يرجّع معلوماته)
  void login(String nationalNumber) {
    phone = '0$nationalNumber';
    profile = _accounts[phone];
    if (profile != null) name = profile!.name;
    orders
      ..clear()
      ..addAll(_savedOrders[phone] ?? const []);
    loggedIn = true;
    notifyListeners();
  }

  /// حفظ المعلومات الشخصية (أول تسجيل أو تعديل) وتسجيل الدخول
  void saveProfile(Profile p) {
    profile = p;
    name = p.name;
    phone = p.phone;
    _accounts[p.phone] = p;
    loggedIn = true;
    notifyListeners();
  }

  void logout() {
    if (phone.isNotEmpty) _savedOrders[phone] = [...orders];
    _signOut();
  }

  /// حذف الحساب: يمسح بيانات المستخدم ومواعيده من التطبيق
  void deleteAccount() {
    Reminders.cancelAll();
    _accounts.remove(phone);
    _savedOrders.remove(phone);
    favDoctors.clear();
    favServices.clear();
    bookings.clear();
    _signOut();
  }

  /// يرجّع التطبيق لوضع الزائر (مشتركة بين الخروج وحذف الحساب)
  void _signOut() {
    name = '';
    phone = '';
    profile = null;
    loggedIn = false;
    tab = 0;
    cart.clear();
    orders.clear();
    notifyListeners();
  }

  void toggleRemind() {
    remindOnWhatsapp = !remindOnWhatsapp;
    notifyListeners();
  }

  Booking addBooking({
    required String doctorId,
    required String cat,
    required int day,
    required int time,
    required String branchId,
    List<String> serviceIds = const [],
    String? orderNumber,
  }) {
    final b = Booking(
      id: 'b${DateTime.now().microsecondsSinceEpoch}',
      doctorId: doctorId,
      cat: cat,
      dayIndex: day,
      time: time,
      branchId: branchId,
      serviceIds: serviceIds,
      orderNumber: orderNumber,
    );
    bookings.add(b);
    notifyListeners();
    // تذكير من الجوال قبل الموعد بساعة
    Reminders.schedule(b);
    return b;
  }

  Booking updateBooking(String id, {required String doctorId, required String cat, required int day, required int time, String? branchId}) {
    final b = bookings.firstWhere((x) => x.id == id);
    b
      ..doctorId = doctorId
      ..cat = cat
      ..dayIndex = day
      ..time = time
      ..branchId = branchId ?? b.branchId;
    notifyListeners();
    Reminders.schedule(b);
    return b;
  }

  /// العيادة ألغت الموعد (يوصل من نظام العيادة بعد الربط، وحالياً من صفحة المعاينة)
  void cancelByClinic(String id, String reason) {
    final b = bookings.firstWhere((x) => x.id == id);
    b.clinicCancelReason = reason;
    Reminders.cancel(id);
    notifyListeners();
  }

  void cancelBooking(String id) {
    bookings.removeWhere((b) => b.id == id);
    Reminders.cancel(id);
    notifyListeners();
  }
}

/// يوفّر الحالة لكل الشاشات ويعيد بنائها عند التغيير
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// يرجّع الحالة ويعيد رسم الويدجت لما تتغير.
  /// داخل التبويبات: يعيد الرسم بس إذا التبويب ظاهر (شوف [TabScope]).
  static AppState of(BuildContext context) {
    final tab = context.dependOnInheritedWidgetOfExactType<TabScope>();
    if (tab != null) return tab.state;
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// يغلّف كل تبويب في الشريط العائم: التبويبات المخفية ما تعيد رسم نفسها مع كل تغيير،
/// وأول ما يظهر التبويب يتحدث بآخر البيانات.
class TabScope extends InheritedWidget {
  const TabScope({super.key, required this.state, required this.active, required this.version, required super.child});

  final AppState state;
  final bool active;
  final int version;

  @override
  bool updateShouldNotify(TabScope oldWidget) => active && (version != oldWidget.version || !oldWidget.active);
}
