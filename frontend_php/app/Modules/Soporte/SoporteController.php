<?php

namespace App\Modules\Soporte;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class SoporteController
{
    public function index(?string $message = null): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $stats = ['total' => 0, 'nuevos' => 0, 'en_proceso' => 0, 'resueltos' => 0, 'urgentes' => 0];
        $tickets = [];
        $error = null;

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $stats = $api->get('soporte/stats')['datos'] ?? $stats;
            $tickets = $api->get('soporte/tickets')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('soporte/index', [
            'stats' => $stats,
            'tickets' => $tickets,
            'message' => $message,
            'error' => $error,
        ]);
    }

    public function store(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->post('soporte/tickets', [
                'titulo' => trim($_POST['titulo'] ?? ''),
                'descripcion' => trim($_POST['descripcion'] ?? ''),
                'modulo' => trim($_POST['modulo'] ?? 'Plataforma'),
                'prioridad' => trim($_POST['prioridad'] ?? 'Media'),
            ]);
            $this->index('Alerta registrada correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }
}
