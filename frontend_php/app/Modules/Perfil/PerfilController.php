<?php

namespace App\Modules\Perfil;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class PerfilController
{
    public function index(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $profile = AuthSession::user();
        $error = null;

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $profile = $api->get('personal/perfil/me')['datos'] ?? $profile;
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('perfil/index', [
            'title' => 'Mi Perfil',
            'profile' => $profile,
            'error' => $error,
        ]);
    }
}
