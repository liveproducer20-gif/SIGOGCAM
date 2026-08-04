<?php

namespace App\Modules\Anuncios;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class AnunciosController
{
    public function index(?string $error = null, ?string $success = null): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $items = [];
        $personal = [];
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $response = $api->get('anuncios');
            $items = $response['datos'] ?? [];
            $personal = $api->get('personal/operativos')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $error ?? $exception->getMessage();
        }

        View::render('anuncios/index', [
            'items' => $items,
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

        $titulo = trim($_POST['titulo'] ?? '');
        $descripcion = trim($_POST['descripcion'] ?? '');

        if ($titulo === '' || $descripcion === '') {
            $this->index('Ingrese titulo y descripcion.');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $payload = [
                'titulo' => $titulo,
                'descripcion' => $descripcion,
                'prioridad' => trim($_POST['prioridad'] ?? 'Normal'),
                'publicado' => isset($_POST['publicado']),
                'notificar' => isset($_POST['notificar']),
                'fechaExpiracion' => trim($_POST['fecha_expiracion'] ?? '') ?: null,
                'personalIds' => array_map('intval', $_POST['personal_ids'] ?? []),
            ];
            $image = $this->fileAsDataUri('imagen');
            if ($image !== null) {
                $payload['imagenNombre'] = $image['name'];
                $payload['imagenUrl'] = $image['data'];
            }
            $id=(int)($_POST['id'] ?? 0);
            if ($id > 0) $api->put("anuncios/{$id}",$payload); else $api->post('anuncios', $payload);
            $this->index(null, $id > 0 ? 'Anuncio actualizado correctamente.' : 'Anuncio creado correctamente.');
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
            $this->index('Seleccione un anuncio válido.');
            return;
        }

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->delete("anuncios/{$id}");
            $this->index(null, 'Anuncio eliminado correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function publish(): void
    {
        $id=(int)($_POST['id'] ?? 0);
        try { (new ApiClient(Config::get('API_BASE_URL'),AuthSession::token()))->put("anuncios/{$id}/publicado",['publicado'=>($_POST['publicado'] ?? '0')==='1']); $this->index(null,'Publicación actualizada.'); }
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
