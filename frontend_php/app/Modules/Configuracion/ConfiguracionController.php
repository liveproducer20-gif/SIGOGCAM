<?php

namespace App\Modules\Configuracion;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class ConfiguracionController
{
    public function index(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $roles = [];
        $version = [];
        $permissions = [];
        $modules = [];
        $selectedRoleId = (int)($_GET['rol_id'] ?? 0);
        $menu = [];
        $scopes = [];
        $conditions = [];
        $message = $_GET['mensaje'] ?? null;
        $error = null;

        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $roles = $api->get('configuracion/roles')['datos'] ?? [];
            $version = $api->get('configuracion/version')['datos'] ?? [];
            $permissions = $api->get('configuracion/permisos')['datos'] ?? [];
            $modules = $api->get('configuracion/modulos')['datos'] ?? [];
            if ($selectedRoleId <= 0 && isset($roles[0]['id'])) {
                $selectedRoleId = (int)$roles[0]['id'];
            }
            if ($selectedRoleId > 0) {
                $menu = $api->get("configuracion/roles/{$selectedRoleId}/menu")['datos'] ?? [];
                $scopes = $api->get("configuracion/roles/{$selectedRoleId}/alcance")['datos'] ?? [];
                $conditions = $api->get("configuracion/roles/{$selectedRoleId}/condiciones")['datos'] ?? [];
            }
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('configuracion/index', [
            'roles' => $roles,
            'version' => $version,
            'permissions' => $permissions,
            'modules' => $modules,
            'selectedRoleId' => $selectedRoleId,
            'menu' => $menu,
            'scopes' => $scopes,
            'conditions' => $conditions,
            'message' => $message,
            'error' => $error,
        ]);
    }

    public function updatePermissions(): void
    {
        $roleId = (int)($_POST['rol_id'] ?? 0);
        $permissionIds = array_map('intval', $_POST['permiso_ids'] ?? []);
        if ($roleId <= 0) {
            header('Location: /configuracion?mensaje=' . urlencode('Seleccione un rol válido.'));
            return;
        }
        $this->sendConfig("configuracion/roles/{$roleId}/permisos", ['permisoIds' => $permissionIds], $roleId, 'Permisos actualizados correctamente.');
    }

    public function updateMenu(): void
    {
        $roleId = (int)($_POST['rol_id'] ?? 0);
        $items = [];
        foreach ($_POST['items'] ?? [] as $item) {
            $items[] = [
                'id' => (int)($item['id'] ?? 0),
                'moduloId' => (int)($item['modulo_id'] ?? 0),
                'nombreVisual' => trim($item['nombre_visual'] ?? ''),
                'iconoVisual' => trim($item['icono_visual'] ?? ''),
                'grupo' => trim($item['grupo'] ?? ''),
                'orden' => (int)($item['orden'] ?? 0),
                'visible' => isset($item['visible']),
                'habilitado' => isset($item['habilitado']),
                'paginaInicial' => isset($item['pagina_inicial']),
                'mostrarBadge' => isset($item['mostrar_badge']),
                'colorBadge' => trim($item['color_badge'] ?? ''),
            ];
        }
        $this->sendConfig("configuracion/roles/{$roleId}/menu", ['items' => $items], $roleId, 'Menú actualizado correctamente.');
    }

    public function storeScope(): void
    {
        $roleId = (int)($_POST['rol_id'] ?? 0);
        $payload = [
            'id' => (int)($_POST['id'] ?? 0),
            'moduloId' => (int)($_POST['modulo_id'] ?? 0),
            'tipoAlcance' => trim($_POST['tipo_alcance'] ?? 'global'),
            'configuracionJson' => trim($_POST['configuracion_json'] ?? ''),
        ];
        $this->postConfig("configuracion/roles/{$roleId}/alcance", $payload, $roleId, 'Alcance guardado correctamente.');
    }

    public function storeCondition(): void
    {
        $roleId = (int)($_POST['rol_id'] ?? 0);
        $payload = [
            'id' => (int)($_POST['id'] ?? 0),
            'moduloId' => $this->nullableInt($_POST['modulo_id'] ?? null),
            'campo' => trim($_POST['campo'] ?? ''),
            'operador' => trim($_POST['operador'] ?? '='),
            'valor' => trim($_POST['valor'] ?? ''),
            'agrupador' => trim($_POST['agrupador'] ?? 'AND'),
            'estado' => isset($_POST['estado']),
        ];
        $this->postConfig("configuracion/roles/{$roleId}/condiciones", $payload, $roleId, 'Condición guardada correctamente.');
    }

    public function deleteCondition(): void
    {
        $roleId = (int)($_POST['rol_id'] ?? 0);
        $conditionId = (int)($_POST['id'] ?? 0);
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->delete("configuracion/roles/{$roleId}/condiciones/{$conditionId}");
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode('Condición desactivada correctamente.'));
        } catch (\Throwable $exception) {
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode($exception->getMessage()));
        }
    }

    private function sendConfig(string $path, array $payload, int $roleId, string $message): void
    {
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->put($path, $payload);
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode($message));
        } catch (\Throwable $exception) {
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode($exception->getMessage()));
        }
    }

    private function postConfig(string $path, array $payload, int $roleId, string $message): void
    {
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->post($path, $payload);
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode($message));
        } catch (\Throwable $exception) {
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode($exception->getMessage()));
        }
    }

    private function nullableInt(mixed $value): ?int
    {
        $value = trim((string)$value);
        return $value === '' ? null : (int)$value;
    }
}
