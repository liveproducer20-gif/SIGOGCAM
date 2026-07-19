import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_client.dart';

void main() {
  const localApi = 'http://127.0.0.1:3000/api';

  test('conserva la URL local al ejecutar en Chrome', () {
    expect(
      resolveApiUrl(
        localApi,
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      localApi,
    );
  });

  test('usa el host del equipo al ejecutar en el emulador Android', () {
    expect(
      resolveApiUrl(
        localApi,
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      'http://10.0.2.2:3000/api',
    );
  });

  test('tambien adapta localhost en Android', () {
    expect(
      resolveApiUrl(
        'http://localhost:3000/api',
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      'http://10.0.2.2:3000/api',
    );
  });

  test('respeta una URL remota configurada manualmente', () {
    const remoteApi = 'https://api.example.com/api';
    expect(
      resolveApiUrl(
        remoteApi,
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      remoteApi,
    );
  });
}
