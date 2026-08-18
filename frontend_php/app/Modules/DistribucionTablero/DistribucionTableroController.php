<?php

namespace App\Modules\DistribucionTablero;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class DistribucionTableroController
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
            echo 'No tiene permiso para consultar el tablero de distribucion.';
            return;
        }

        $catalogs = ['distritos' => [], 'turnos' => []];
        $error = null;
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $catalogs = $api->get('distribucion-geografica/catalogos')['datos'] ?? $catalogs;
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('distribucion_tablero/index', [
            'title' => 'Tablero de Distribución',
            'usuario' => $user,
            'catalogos' => $catalogs,
            'error' => $error,
            'pageStyles' => [
                '/assets/css/distribucion-tablero.css?v=20260818-eas-mode',
            ],
            'pageScripts' => [
                '/assets/js/distribucion-tablero.js?v=20260818-eas-mode',
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
        $allowed = preg_match('#^(distribucion-tablero|distribucion-geografica|distritos|rutas|personal)(/|\?|$)#', $resource) === 1;
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
