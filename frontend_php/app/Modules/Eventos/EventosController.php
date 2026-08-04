<?php

namespace App\Modules\Eventos;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class EventosController
{
    public function index(?string $error = null, ?string $success = null): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $items = [];
        $tipos = [];
        $personal = [];
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $response = $api->get('eventos');
            $items = $response['datos'] ?? [];
            $tipos = $api->get('catalogos/TIPOS_EVENTO')['datos'] ?? [];
            $personal = $api->get('personal/operativos')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $error ?? $exception->getMessage();
        }

        View::render('eventos/index', [
            'items' => $items,
            'tipos' => $tipos,
            'personal' => $personal,
            'error' => $error,
            'success' => $success,
        ]);
    }

    public function store(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $payload = [
            'titulo' => trim($_POST['titulo'] ?? ''),
            'tipoEventoId' => (int) ($_POST['tipo_evento_id'] ?? 0),
            'fechaInicio' => trim($_POST['fecha_inicio'] ?? ''),
            'fechaFin' => trim($_POST['fecha_fin'] ?? ''),
            'lugar' => trim($_POST['lugar'] ?? ''),
            'descripcion' => trim($_POST['descripcion'] ?? ''),
            'prioridad' => trim($_POST['prioridad'] ?? ''),
            'notificar' => isset($_POST['notificar']),
            'personalIds' => array_map('intval', $_POST['personal_ids'] ?? []),
        ];

        $image = $this->fileAsDataUri('imagen');
        if ($image !== null) {
            $payload['imagenUrl'] = $image['data'];
        }
        $pdf = $this->fileAsDataUri('pdf');
        if ($pdf !== null) {
            $payload['pdfNombre'] = $pdf['name'];
            $payload['pdfUrl'] = $pdf['data'];
        }

        if ($payload['titulo'] === '' || $payload['tipoEventoId'] <= 0 || $payload['fechaInicio'] === '' || $payload['fechaFin'] === '' || $payload['lugar'] === '') {
            $this->index('Complete titulo, tipo, fecha, hora y lugar.');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $id=(int)($_POST['id'] ?? 0);
            if ($id > 0) $api->put("eventos/{$id}", $payload); else $api->post('eventos', $payload);
            $this->index(null, $id > 0 ? 'Evento actualizado correctamente.' : 'Evento creado correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function destroy(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $id = (int) ($_POST['id'] ?? 0);
        if ($id <= 0) {
            $this->index('Seleccione un evento válido.');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->delete("eventos/{$id}");
            $this->index(null, 'Evento eliminado exitosamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function status(): void
    {
        $id=(int)($_POST['id'] ?? 0);
        try { (new ApiClient(Config::get('API_BASE_URL'),AuthSession::token()))->put("eventos/{$id}/estado",['estado'=>trim($_POST['estado'] ?? 'NUEVO')]); $this->index(null,'Estado actualizado correctamente.'); }
        catch (\Throwable $exception) { $this->index($exception->getMessage()); }
    }

    private function fileAsDataUri(string $field): ?array
    {
        if (empty($_FILES[$field]) || ($_FILES[$field]['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            return null;
        }
        $tmp = $_FILES[$field]['tmp_name'];
        $name = $_FILES[$field]['name'] ?? 'archivo';
        $type = $_FILES[$field]['type'] ?? 'application/octet-stream';
        $content = file_get_contents($tmp);
        if ($content === false) {
            return null;
        }
        return ['name' => $name, 'data' => 'data:' . $type . ';base64,' . base64_encode($content)];
    }
}
