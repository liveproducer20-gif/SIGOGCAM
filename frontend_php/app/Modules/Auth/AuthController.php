<?php

namespace App\Modules\Auth;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class AuthController
{
    public function showLogin(?string $error = null): void
    {
        View::render('auth/login', ['error' => $error]);
    }

    public function login(): void
    {
        $correo = trim($_POST['correo'] ?? '');
        $password = trim($_POST['password'] ?? '');

        if ($correo === '' || $password === '') {
            $this->showLogin('Ingrese correo y contraseña.');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'));
            $response = $api->post('auth/login', [
                'correo' => $correo,
                'password' => $password,
            ]);

            $datos = $response['datos'] ?? [];
            AuthSession::login($datos['usuario'] ?? [], $datos['token'] ?? '');
            header('Location: /dashboard');
        } catch (\Throwable $error) {
            $this->showLogin($error->getMessage());
        }
    }

    public function logout(): void
    {
        AuthSession::logout();
        header('Location: /');
    }
}
