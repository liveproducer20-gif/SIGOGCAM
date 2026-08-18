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
        $selected = null;
        $user = AuthSession::user() ?? [];
        $isManager = in_array('soporte.listar', $user['permisos'] ?? [], true) || str_contains(strtoupper((string)($user['rolNombre'] ?? $user['rol'] ?? '')), 'ADMINISTRADOR');
        $error = null;

        $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
        $errors = [];
        // Independent catalog calls run in parallel (curl_multi); a failure in
        // one call doesn't prevent the rest of the screen from loading.
        $responses = $api->getMany([
            'stats' => 'soporte/stats',
            'tickets' => 'soporte/tickets',
        ]);
        foreach ($responses as $key => $response) {
            if (isset($response['error'])) {
                $errors[] = $key . ': ' . $response['error']->getMessage();
                continue;
            }
            $datos = $response['data']['datos'] ?? [];
            ${$key} = $key === 'stats' ? ($datos + $stats) : $datos;
        }
        $ticketId = (int)($_GET['id'] ?? 0);
        if ($ticketId > 0) {
            try { $selected = $api->get("soporte/tickets/{$ticketId}")['datos'] ?? null; } catch (\Throwable $e) { $errors[] = 'ticket: ' . $e->getMessage(); }
        }
        $error = $errors ? implode(' | ', $errors) : null;

        View::render('soporte/index', [
            'title' => 'Soporte',
            'stats' => $stats,
            'tickets' => $tickets,
            'selected' => $selected,
            'isManager' => $isManager,
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
                'imagen' => $this->fileAsDataUri('imagen'),
            ]);
            $this->index('Alerta registrada correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function update(): void
    {
        $id=(int)($_POST['id'] ?? 0);
        try {
            $this->api()->put("soporte/tickets/{$id}",['estado'=>trim($_POST['estado'] ?? ''),'prioridad'=>trim($_POST['prioridad'] ?? ''),'asignado_a'=>$this->nullableInt($_POST['asignado_a'] ?? null),'asignado_nombre'=>trim($_POST['asignado_nombre'] ?? '') ?: null]);
            $_GET['id']=$id; $this->index('Alerta actualizada correctamente.');
        } catch (\Throwable $exception) { $_GET['id']=$id; $this->index($exception->getMessage()); }
    }

    public function comment(): void
    {
        $id=(int)($_POST['id'] ?? 0);
        try {
            $this->api()->post("soporte/tickets/{$id}/comentarios",['comentario'=>trim($_POST['comentario'] ?? ''),'es_interno'=>isset($_POST['es_interno'])]);
            $_GET['id']=$id; $this->index('Comentario registrado correctamente.');
        } catch (\Throwable $exception) { $_GET['id']=$id; $this->index($exception->getMessage()); }
    }

    private function api(): ApiClient { return new ApiClient(Config::get('API_BASE_URL'), AuthSession::token()); }
    private function nullableInt(mixed $value): ?int { $value=trim((string)$value); return $value===''?null:(int)$value; }
    private function fileAsDataUri(string $field): ?string
    {
        if (empty($_FILES[$field]) || ($_FILES[$field]['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) return null;
        $content=file_get_contents($_FILES[$field]['tmp_name']);
        if ($content === false) return null;
        return 'data:' . ($_FILES[$field]['type'] ?? 'application/octet-stream') . ';base64,' . base64_encode($content);
    }
}
