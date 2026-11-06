import 'package:flutter/widgets.dart';

import 'data.dart';
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
  });

  final String number;
  final List<OrderItem> items;
  final String branchId;
  final int subtotal;
  final double vat;
  final PayMethod method;
  final DateTime date;
  final String reference;

  double get total => subtotal + vat;
  int get count => items.fold(0, (a, b) => a + b.qty);
}

/// حالة التطبيق العامة
class AppState extends ChangeNotifier {
  /// يزيد مع كل تغيير (نستخدمه عشان التبويب الظاهر بس يعيد رسم نفسه)
  int version = 0;

  @override
  void notifyListeners() {
    version++;
    super.notifyListeners();
  }

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
  double get cartVat => cartSubtotal * vatRate;
  double get cartTotal => cartSubtotal + cartVat;

  /// الفروع اللي تتوفر فيها كل الخدمات اللي في السلة
  List<Branch> get cartBranches => branches
      .where((b) => cartItems.every((i) => i.service.availableIn.contains(b.id)))
      .toList();

  void addToCart(String serviceId, {int qty = 1}) {
    cart[serviceId] = ((cart[serviceId] ?? 0) + qty).clamp(1, 20);
    notifyListeners();
  }

  // المفضلة (تشتغل للزائر أيضاً)
  final Set<String> favDoctors = {};
  final Set<String> favServices = {};

  int get favCount => favDoctors.length + favServices.length;

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
      cart[serviceId] = qty.clamp(1, 20);
    }
    notifyListeners();
  }

  void removeFromCart(String serviceId) {
    cart.remove(serviceId);
    notifyListeners();
  }

  Order placeOrder({required String branchId, required PayMethod method, required String reference}) {
    final o = Order(
      number: '${10240 + orders.length + 1}',
      items: cartItems,
      branchId: branchId,
      subtotal: cartSubtotal,
      vat: cartVat,
      method: method,
      date: DateTime.now(),
      reference: reference,
    );
    orders.insert(0, o);
    cart.clear();
    notifyListeners();
    return o;
  }

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
    name = '';
    phone = '';
    profile = null;
    loggedIn = false;
    tab = 0;
    cart.clear();
    orders.clear();
    notifyListeners();
  }

  /// حذف الحساب: يمسح بيانات المستخدم ومواعيده من التطبيق
  void deleteAccount() {
    _accounts.remove(phone);
    _savedOrders.remove(phone);
    favDoctors.clear();
    favServices.clear();
    name = '';
    phone = '';
    profile = null;
    loggedIn = false;
    tab = 0;
    bookings.clear();
    cart.clear();
    orders.clear();
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
