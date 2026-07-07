import '../../core/api/api_client.dart';
import '../../core/auth/app_user.dart';

class ProfileApi {
  final ApiClient _client;

  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AppUser> getMe() async {
    final response = await _client.get<AppUser>(
      'personal/perfil/me',
      (value) => AppUser.fromJson(Map<String, dynamic>.from(value as Map)),
    );

    return response.datos!;
  }

  Future<AppUser> updateMe({
    required String cedula,
    required String correo,
    String? telefono,
    String? fechaNacimiento,
    String? fotoPerfilUrl,
  }) async {
    final response = await _client.put<AppUser>(
      'personal/perfil/me',
      {
        'cedula': cedula,
        'correoInstitucional': correo,
        'telefono': telefono,
        'fechaNacimiento': fechaNacimiento,
        'fotoPerfilUrl': fotoPerfilUrl,
      },
      (value) => AppUser.fromJson(Map<String, dynamic>.from(value as Map)),
    );

    return response.datos!;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post<bool>(
      'auth/change-password',
      {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      (_) => true,
    );
  }
}
