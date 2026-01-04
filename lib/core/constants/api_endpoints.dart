class ApiEndpoints {
  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String profile = '/profile';

  // Residences
  static const String residences = '/residences';
  static String residenceDetail(int id) => '/residences/$id';

  // Activities
  static const String activities = '/activities';
  static String activityDetail(int id) => '/activities/$id';

  // Marketplace
  static const String products = '/marketplace/products';
  static String productDetail(int id) => '/marketplace/products/$id';

  // Bookings
  static const String bookings = '/bookings';
  static String bookingDetail(int id) => '/bookings/$id';
  static String approveBooking(int id) => '/bookings/$id/approve';
  static String rejectBooking(int id) => '/bookings/$id/reject';

  // Transactions
  static const String transactions = '/marketplace/transactions';

  // Bookmarks
  static const String bookmarks = '/bookmarks';

  // Ratings
  static const String ratings = '/ratings';

  // Categories
  static const String categories = '/categories';
  static String categoriesByType(String type) => '/categories?type=$type';

  // Dashboard
  static const String dashboardStudent = '/dashboard/student';
  static const String dashboardProvider = '/dashboard/provider';
}
