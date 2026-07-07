import '../../core/api/api_client.dart';
import '../../core/auth/app_user.dart';
import '../../core/auth/auth_session.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AppUser> login({
    required String usuario,
    required String password,
  }) async {
    final response = await _client.post<AppUser>(
      'auth/login',
      {
        'usuario': usuario,
        'password': password,
      },
      (value) {
        final map = value as Map<String, dynamic>? ?? {};
        final usuarioJson = map['usuario'];
        final token = map['token']?.toString();

        if (usuarioJson is! Map) {
          throw Exception(
            map['mensaje']?.toString() ?? 'Login sin datos de usuario',
          );
        }

        if (token == null || token.isEmpty) {
          throw Exception('Login sin token de sesión');
        }

        AuthSession.setToken(token);
        return AppUser.fromJson(
          Map<String, dynamic>.from(usuarioJson),
        );
      },
    );

    return response.datos!;
  }
}
