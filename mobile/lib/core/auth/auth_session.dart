class AuthSession {
  static String? token;

  static void setToken(String? value) {
    token = value;
  }

  static void clear() {
    token = null;
  }
}
