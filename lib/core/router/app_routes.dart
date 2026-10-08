/// Route paths — never hardcode a string route in a screen.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String characters = '/characters';
  static const String spa = '/spa';
  static const String studio = '/studio';
  static const String reveal = '/reveal';
  static const String gallery = '/gallery';
  static const String rewards = '/rewards';
  static const String stars = '/stars';
  static const String gifts = '/gifts';
  static const String settings = '/settings';

  /// One gift room, e.g. `/gifts/blush`.
  static String giftRoomPath(String roomId) => '/gifts/$roomId';
}
