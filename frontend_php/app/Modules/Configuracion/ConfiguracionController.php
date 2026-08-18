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
        $tab = (string)($_GET['tab'] ?? 'resumen');
        $validTabs = ['resumen', 'permisos', 'menu', 'alcance', 'condiciones', 'campos', 'versiones', 'auditoria', 'cambios'];
        if (!in_array($tab, $validTabs, true)) {
            $tab = 'resumen';
        }
        $menu = [];
        $scopes = [];
        $conditions = [];
        $fields = [];
        $versions = [];
        $audit = [];
        $cambios = [];
        $message = $_GET['mensaje'] ?? null;
        $error = null;

        $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
        $errors = [];
        // Round 1: independent catalog calls in parallel (curl_multi). Each
        // resolves on its own so a failure doesn't break the rest of the screen.
        $round1 = $api->getMany([
            'roles' => 'configuracion/roles',
            'version' => 'configuracion/version',
            'permisos' => 'configuracion/permisos',
            'modulos' => 'configuracion/modulos',
            'cambios' => 'configuracion/cambios',
        ]);
        foreach ($round1 as $key => $response) {
            if (isset($response['error'])) {
                $errors[] = $key . ': ' . $response['error']->getMessage();
                continue;
            }
            ${$key} = $response['data']['datos'] ?? [];
        }
        if ($selectedRoleId <= 0 && isset($roles[0]['id'])) {
            $selectedRoleId = (int)$roles[0]['id'];
        }
        // Round 2: role-scoped calls in parallel, depend on the selected role.
        if ($selectedRoleId > 0) {
            $round2 = $api->getMany([
                'menu' => "configuracion/roles/{$selectedRoleId}/menu",
                'scopes' => "configuracion/roles/{$selectedRoleId}/alcance",
                'conditions' => "configuracion/roles/{$selectedRoleId}/condiciones",
                'fields' => "configuracion/roles/{$selectedRoleId}/campos",
                'versions' => "configuracion/roles/{$selectedRoleId}/versiones",
                'audit' => "configuracion/auditoria?rolId={$selectedRoleId}&limite=100",
            ]);
            foreach ($round2 as $key => $response) {
                if (isset($response['error'])) {
                    $errors[] = $key . ': ' . $response['error']->getMessage();
                    continue;
                }
                ${$key} = $response['data']['datos'] ?? [];
            }
        }
        $error = $errors ? implode(' | ', $errors) : null;

        View::render('configuracion/index', [
            'title' => 'Configuracion',
            'roles' => $roles,
            'version' => $version,
            'permissions' => $permissions,
            'modules' => $modules,
            'selectedRoleId' => $selectedRoleId,
            'tab' => $tab,
            'menu' => $menu,
            'scopes' => $scopes,
            'conditions' => $conditions,
            'fields' => $fields,
            'versions' => $versions,
            'audit' => $audit,
            'cambios' => $cambios,
            'message' => $message,
            'error' => $error,
            'pageScripts' => ['/assets/js/configuracion.js'],
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
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode('Registro eliminado correctamente.'));
        } catch (\Throwable $exception) {
            header('Location: /configuracion?rol_id=' . $roleId . '&mensaje=' . urlencode($exception->getMessage()));
        }
    }

    public function updateFields(): void
    {
        $roleId=(int)($_POST['rol_id'] ?? 0); $items=[];
        foreach($_POST['fields'] ?? [] as $fieldId=>$item) $items[]=['campoId'=>(int)$fieldId,'nivelAcceso'=>trim($item['nivel_acceso'] ?? 'ninguno'),'enmascarado'=>isset($item['enmascarado'])];
        $this->sendConfig("configuracion/roles/{$roleId}/campos",['items'=>$items],$roleId,'Permisos de campos actualizados.');
    }

    public function createVersion(): void
    {
        $roleId=(int)($_POST['rol_id'] ?? 0);
        $this->postConfig("configuracion/roles/{$roleId}/versiones",['comentario'=>trim($_POST['comentario'] ?? '')],$roleId,'Versión de configuración creada.');
    }

    public function storeCambio(): void
    {
        $payload = [
            'desarrollador' => trim($_POST['desarrollador'] ?? ''),
            'titulo' => trim($_POST['titulo'] ?? ''),
            'detalle' => trim($_POST['detalle'] ?? ''),
        ];
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->post('configuracion/cambios', $payload);
            header('Location: /configuracion?mensaje=' . urlencode('Cambio registrado correctamente.'));
        } catch (\Throwable $exception) {
            header('Location: /configuracion?mensaje=' . urlencode($exception->getMessage()));
        }
    }

    public function deleteCambio(): void
    {
        $cambioId = (int)($_POST['id'] ?? 0);
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $api->delete("configuracion/cambios/{$cambioId}");
            header('Location: /configuracion?mensaje=' . urlencode('Registro eliminado correctamente.'));
        } catch (\Throwable $exception) {
            header('Location: /configuracion?mensaje=' . urlencode($exception->getMessage()));
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
