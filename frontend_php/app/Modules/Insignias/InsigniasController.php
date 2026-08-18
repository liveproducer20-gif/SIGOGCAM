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

        $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
        $errors = [];
        // Cada llamada es independiente: una falla no debe romper el resto de la pantalla.
        try { $progress = $api->get('insignias/progreso/me')['datos'] ?? $progress; } catch (\Throwable $e) { $errors[] = 'progreso: ' . $e->getMessage(); }
        try { $ranking = $api->get('insignias/ranking')['datos'] ?? []; } catch (\Throwable $e) { $errors[] = 'ranking: ' . $e->getMessage(); }
        $error = $errors ? implode(' | ', $errors) : null;

        View::render('insignias/index', [
            'title' => 'Insignias',
            'progress' => $progress,
            'ranking' => $ranking,
            'error' => $error,
        ]);
    }
}
