<?php

namespace App\Modules\Dashboard;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class DashboardController
{
    public function index(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $menu = [];
        $stats = [];
        $version = [];
        $error = null;

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $response = $api->get('auth/mi-menu');
            $menu = $response['datos'] ?? [];
            $stats = $api->get('dashboard/resumen')['datos'] ?? [];
            $version = $api->get('configuracion/version')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('dashboard/index', [
            'usuario' => AuthSession::user(),
            'menu' => $menu,
            'stats' => $stats,
            'version' => $version,
            'error' => $error,
            'pageTitle' => 'Panel principal',
            'pageDescription' => 'Bienvenido, ' . (AuthSession::user()['nombreCompleto'] ?? 'usuario'),
        ]);
    }
}
