class ApiConfig {
  static const String baseUrl = 'https://code-and-coffee-backend.onrender.com/api';

  // ================= AUTH =================
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // ================= CANTEENS =================
  static const String canteens = '/canteens';

  // ================= MENU =================
  static const String menuItems = '/menu';
  static String menuItemById(String id) => '/menu/$id';

  // ================= ORDERS =================
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  static const String userOrders = '/orders/my';

  // ================= ADMIN =================
  static const String adminTodayOrders = '/orders/admin/today';
  static const String adminStats = '/orders/admin/stats';

  // ================= KITCHEN =================
  static const String kitchenOrders = '/orders/kitchen/queue';
}
