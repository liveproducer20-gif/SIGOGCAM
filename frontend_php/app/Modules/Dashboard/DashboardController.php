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

        $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
        $errors = [];
        // Independent catalog calls run in parallel (curl_multi); a failure in
        // one call doesn't prevent the rest of the screen from loading.
        $responses = $api->getMany([
            'menu' => 'auth/mi-menu',
            'stats' => 'dashboard/resumen',
            'version' => 'configuracion/version',
        ]);
        foreach ($responses as $key => $response) {
            if (isset($response['error'])) {
                $errors[] = $key . ': ' . $response['error']->getMessage();
                continue;
            }
            ${$key} = $response['data']['datos'] ?? [];
        }
        $error = $errors ? implode(' | ', $errors) : null;

        View::render('dashboard/index', [
            'title' => 'Panel principal',
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
