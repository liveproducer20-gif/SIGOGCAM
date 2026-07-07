class NotifReadStore {
  static final Set<String> _readIds = {};

  static bool isRead(String id) => _readIds.contains(id);

  static void markRead(String id) {
    _readIds.add(id);
  }
}
