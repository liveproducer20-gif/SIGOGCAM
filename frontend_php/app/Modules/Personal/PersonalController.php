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
        $items = [];
        $catalogs = [];
        $error = null;
        try {
            $api = $this->api();
            $items = $api->get('personal')['datos'] ?? [];
            $catalogs = $api->get('personal/catalogos')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('personal/index', [
            'items' => $items,
            'catalogs' => $catalogs,
            'error' => $error,
            'message' => $message,
            'permissions' => $user['permisos'] ?? [],
            'isAdministrator' => str_contains(strtoupper((string)($user['rolNombre'] ?? $user['rol'] ?? '')), 'ADMINISTRADOR'),
            'pageStyles' => ['/assets/css/personal.css'],
        ]);
    }

    public function store(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $id = (int)($_POST['id'] ?? 0);
        try {
            $api = $this->api();
            $payload = [
                'cedula' => $this->text('cedula'),
                'nombres' => $this->text('nombres'),
                'apellidos' => $this->text('apellidos'),
                'correo_institucional' => $this->text('correo_institucional'),
                'telefono' => $this->nullableText('telefono'),
                'cargo_id' => $this->nullableInt($_POST['cargo_id'] ?? null),
                'area_id' => $this->nullableInt($_POST['area_id'] ?? null),
                'grupo_id' => $this->nullableInt($_POST['grupo_id'] ?? null),
                'jornada_id' => $this->nullableInt($_POST['jornada_id'] ?? null),
                'rol_id' => $this->nullableInt($_POST['rol_id'] ?? null),
                'grado_id' => $this->nullableInt($_POST['grado_id'] ?? null),
                'estado_personal_id' => $this->nullableInt($_POST['estado_personal_id'] ?? null),
                'activo' => isset($_POST['activo']),
            ];
            $password = $this->nullableText('password');
            if ($password !== null) $payload['password'] = $password;

            if ($id > 0) {
                $api->put("personal/{$id}", $payload);
                $this->index('Personal actualizado correctamente.');
            } else {
                if (empty($payload['password'])) {
                    $this->index('La contraseña es requerida para nuevo personal.');
                    return;
                }
                $api->post('personal', $payload);
                $this->index('Personal creado correctamente.');
            }
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function destroy(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $id = (int)($_POST['id'] ?? 0);
        if ($id <= 0) { $this->index('Seleccione un registro válido.'); return; }
        try {
            $this->api()->delete("personal/{$id}");
            $this->index('Personal eliminado correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    private function api(): ApiClient { return new ApiClient(Config::get('API_BASE_URL'), AuthSession::token()); }
    private function text(string $key): string { return trim((string)($_POST[$key] ?? '')); }
    private function nullableText(string $key): ?string { $v = $this->text($key); return $v === '' ? null : $v; }
    private function nullableInt(mixed $v): ?int { $v = trim((string)$v); return $v === '' ? null : (int)$v; }
}
