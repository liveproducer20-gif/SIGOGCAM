<?php

namespace App\Modules\Insignias;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class InsigniasController
{
    public function index(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $progress = ['insignias' => [], 'total_cartillas_generadas' => 0, 'desbloqueadas' => 0, 'pendientes' => 0];
        $ranking = [];
        $error = null;

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $progress = $api->get('insignias/progreso/me')['datos'] ?? $progress;
            $ranking = $api->get('insignias/ranking')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('insignias/index', [
            'progress' => $progress,
            'ranking' => $ranking,
            'error' => $error,
        ]);
    }
}
