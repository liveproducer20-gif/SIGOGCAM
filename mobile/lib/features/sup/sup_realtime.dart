import 'dart:async';

import 'sup_api.dart';

/// Comparte una sola conexión SSE entre el tablero y la pantalla de soporte.
/// Los errores de red se absorben y se reintentan con espera progresiva para
/// no bloquear la interfaz ni saturar la consola cuando el backend se reinicia.
class SupportRealtime {
  SupportRealtime._();

  static final SupportRealtime instance = SupportRealtime._();

  final _controller = StreamController<String>.broadcast();
  StreamSubscription<String>? _connection;
  Timer? _retry;
  int _consumers = 0;
  int _attempt = 0;
  bool _connecting = false;

  Stream<String> get events => _controller.stream;

  void attach() {
    _consumers++;
    if (_consumers == 1) _connect();
  }

  void detach() {
    if (_consumers > 0) _consumers--;
    if (_consumers != 0) return;
    _retry?.cancel();
    _retry = null;
    _connection?.cancel();
    _connection = null;
    _connecting = false;
    _attempt = 0;
  }

  void _connect() {
    if (_consumers == 0 || _connecting || _connection != null) return;
    _connecting = true;
    _connection = SupportApi().realtime().listen(
      (line) {
        _connecting = false;
        _attempt = 0;
        if (line.startsWith('data:')) _controller.add(line);
      },
      onError: (_) => _scheduleRetry(),
      onDone: _scheduleRetry,
      cancelOnError: true,
    );
  }

  void _scheduleRetry() {
    _connecting = false;
    _connection?.cancel();
    _connection = null;
    if (_consumers == 0 || _retry?.isActive == true) return;

    const delays = [5, 10, 20, 40, 60, 120];
    final seconds = delays[_attempt.clamp(0, delays.length - 1)];
    if (_attempt < delays.length - 1) _attempt++;
    _retry = Timer(Duration(seconds: seconds), () {
      _retry = null;
      _connect();
    });
  }
}
