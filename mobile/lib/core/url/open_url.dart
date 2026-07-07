import 'open_url_stub.dart' if (dart.library.html) 'open_url_web.dart';

Future<void> openExternalUrl(String url) => openExternalUrlImpl(url);

String googleMapsSearchUrl(String value) {
  final encoded = Uri.encodeComponent(value.trim());
  return 'https://www.google.com/maps/search/?api=1&query=$encoded';
}
