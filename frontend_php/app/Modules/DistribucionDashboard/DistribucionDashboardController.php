<?php

namespace App\Modules\DistribucionDashboard;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class DistribucionDashboardController
{
    public function index(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $user = AuthSession::user() ?? [];
        $role = strtoupper((string)($user['rolNombre'] ?? $user['rol'] ?? ''));
        if (!str_contains($role, 'ADMINISTRADOR') && !in_array('tablero_distribucion.ver', $user['permisos'] ?? [], true)) {
            http_response_code(403);
            echo 'No tiene permiso para consultar el dashboard de distribuciones.';
            return;
        }

        $distributions = ['distribuciones' => []];
        $error = null;
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $distributions = $api->get('distribucion-tablero/dashboard')['datos'] ?? $distributions;
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('distribucion_dashboard/index', [
            'title' => 'Dashboard de Distribuciones',
            'usuario' => $user,
            'distributions' => $distributions,
            'error' => $error,
            'pageStyles' => [
                '/assets/css/distribucion-dashboard.css',
            ],
            'pageScripts' => [
                '/assets/js/distribucion-dashboard.js',
            ],
        ]);
    }

    public function proxy(): void
    {
        header('Content-Type: application/json; charset=utf-8');
        if (!AuthSession::check()) {
            http_response_code(401);
            echo json_encode(['ok' => false, 'mensaje' => 'Sesion no autorizada']);
            return;
        }

        $resource = ltrim((string)($_GET['resource'] ?? ''), '/');
        $allowed = preg_match('#^distribucion-tablero(/|\?|$)#', $resource) === 1;
        if (!$allowed || str_contains($resource, '..')) {
            http_response_code(400);
            echo json_encode(['ok' => false, 'mensaje' => 'Recurso no permitido']);
            return;
        }

        $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $body = json_decode(file_get_contents('php://input') ?: '{}', true);
        if (!is_array($body)) {
            $body = [];
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $response = match ($method) {
                'GET' => $api->get($resource),
                'POST' => $api->post($resource, $body),
                'PUT' => $api->put($resource, $body),
                'DELETE' => $api->delete($resource),
                default => throw new \RuntimeException('Metodo no permitido'),
            };
            echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        } catch (\Throwable $exception) {
            http_response_code(422);
            echo json_encode(['ok' => false, 'mensaje' => $exception->getMessage()], JSON_UNESCAPED_UNICODE);
        }
    }
}
