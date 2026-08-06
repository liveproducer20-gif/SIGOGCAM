<?php

namespace App\Modules\Personal;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class PersonalController
{
    public function index(?string $message = null): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $user = AuthSession::user() ?? [];
        $catalogs = [];
        $error = null;
        try {
            $api = $this->api();
            $catalogs = $api->get('personal/catalogos')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('personal/index', [
            'catalogs' => $catalogs,
            'error' => $error,
            'message' => $message,
            'permissions' => $user['permisos'] ?? [],
            'isAdministrator' => str_contains(strtoupper((string)($user['rolNombre'] ?? $user['rol'] ?? '')), 'ADMINISTRADOR'),
            'pageStyles' => ['/assets/css/personal.css'],
        ]);
    }

    public function proxy(): void
    {
        header('Content-Type: application/json; charset=utf-8');
        if (!AuthSession::check()) {
            http_response_code(401);
            echo json_encode(['ok' => false, 'mensaje' => 'Sesión no autorizada']);
            return;
        }

        $path = parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?: '';
        $query = $_SERVER['QUERY_STRING'] ?? '';
        $resource = ltrim(str_replace('/personal/api', '', $path), '/');
        if ($resource === '' || $resource === false) {
            $resource = 'personal';
        } elseif (!str_starts_with($resource, 'personal')) {
            $resource = 'personal/' . $resource;
        }
        if ($query !== '') {
            $resource .= '?' . $query;
        }
        $allowed = preg_match('#^(personal(/|\?|$))#', $resource) === 1;
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
                default => throw new \RuntimeException('Método no permitido'),
            };
            echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        } catch (\Throwable $exception) {
            http_response_code(422);
            echo json_encode(['ok' => false, 'mensaje' => $exception->getMessage()], JSON_UNESCAPED_UNICODE);
        }
    }

    private function api(): ApiClient { return new ApiClient(Config::get('API_BASE_URL'), AuthSession::token()); }
}
