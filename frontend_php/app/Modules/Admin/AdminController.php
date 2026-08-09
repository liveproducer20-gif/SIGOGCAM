<?php

namespace App\Modules\Admin;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class AdminController
{
    private const TABS = ['resumen', 'catalogos', 'lugares', 'rutas', 'grados', 'eas', 'moviles', 'asignaciones', 'mantenimiento'];

    public function index(?string $message = null): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $user = AuthSession::user() ?? [];
        if (!$this->can('administracion.ver', $user)) {
            http_response_code(403);
            View::render('errors/forbidden', ['message' => 'No tiene permiso para acceder a Administración.']);
            return;
        }

        $tab = (string)($_GET['tab'] ?? 'resumen');
        if (!in_array($tab, self::TABS, true)) $tab = 'resumen';
        $catalogCode = strtoupper(trim((string)($_GET['catalogo'] ?? '')));
        $data = $this->emptyData();
        $error = null;

        try {
            $api = $this->api();
            $data['referencias'] = $api->get('admin/referencias')['datos'] ?? [];
            if ($this->can('eas.ver', $user)) $data['eas'] = $api->get('admin/eas')['datos'] ?? [];
            if ($this->can('moviles.ver', $user)) $data['moviles'] = $api->get('admin/moviles')['datos'] ?? [];
            if ($this->can('rutas.ver', $user)) $data['rutas'] = $api->get('admin/rutas')['datos'] ?? [];
            if ($this->can('lugares_servicio.ver', $user)) $data['lugares'] = $api->get('admin/lugares-servicio')['datos'] ?? [];
            if ($this->can('personal.ver', $user)) $data['grados'] = $api->get('admin/grados')['datos'] ?? [];
            if ($this->can('catalogos.ver', $user)) {
                $data['catalogos'] = $api->get('admin/catalogos')['datos'] ?? [];
                if ($catalogCode === '' && !empty($data['catalogos'])) $catalogCode = (string)$data['catalogos'][0]['codigo'];
                if ($catalogCode !== '') $data['detallesCatalogo'] = $api->get('admin/catalogos/' . rawurlencode($catalogCode))['datos'] ?? [];
            }
            if ($this->can('moviles.asignar', $user)) $data['asignaciones'] = $api->get('admin/movil-eas-asignaciones')['datos'] ?? [];
            if ($this->can('moviles.ver', $user)) $data['mantenimientos'] = $api->get('admin/dashboard/mantenimiento')['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('admin/index', [
            'title' => 'Administracion',
            'adminData' => $data,
            'tab' => $tab,
            'catalogCode' => $catalogCode,
            'permissions' => $user['permisos'] ?? [],
            'isAdministrator' => str_contains(strtoupper((string)($user['rolNombre'] ?? $user['rol'] ?? '')), 'ADMINISTRADOR'),
            'message' => $message,
            'error' => $error,
            'pageTitle' => 'Administración',
            'pageDescription' => 'Gestión integral de recursos y catálogos operativos',
        ]);
    }

    public function store(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $entity = (string)($_POST['entity'] ?? '');
        $id = (int)($_POST['id'] ?? 0);
        $tab = (string)($_POST['tab'] ?? 'resumen');
        $_GET['tab'] = $tab;
        if (!empty($_POST['catalogo_codigo'])) $_GET['catalogo'] = $_POST['catalogo_codigo'];
        try {
            $api = $this->api();
            if ($entity === 'mantenimiento') {
                [$path, $payload] = $this->payloadFor($entity);
                $api->post('admin/moviles/' . (int)$_POST['movil_id'] . '/mantenimientos', $payload);
            } elseif ($entity === 'lugar' && $id <= 0 && !empty($_POST['nombre'])) {
                $nombres = $_POST['nombre'];
                if (!is_array($nombres)) $nombres = [$nombres];
                $distritoId = (int)($_POST['distrito_id'] ?? 0);
                $rutaId = (int)($_POST['ruta_id'] ?? 0);
                $tipoServicioId = $this->nullableInt($_POST['tipo_servicio_id'] ?? null);
                $consignas = $this->text('consignas');
                $observacion = $this->text('observacion');
                $creados = 0;
                foreach ($nombres as $nombre) {
                    $nombre = trim((string)$nombre);
                    if ($nombre === '') continue;
                    $api->post('admin/lugares-servicio', [
                        'nombre' => $nombre,
                        'direccion' => $nombre,
                        'distritoId' => $distritoId,
                        'rutaId' => $rutaId,
                        'tipoServicioId' => $tipoServicioId,
                        'consignas' => $consignas,
                        'observacion' => $observacion,
                        'cantidadRequerida' => 1,
                        'estadoOperativo' => 'ACTIVO',
                        'activo' => true,
                    ]);
                    $creados++;
                }
                $this->index("{$creados} registro(s) creado(s) correctamente.");
            } elseif ($entity === 'catalogo_detalle') {
                [$path, $payload] = $this->payloadFor($entity);
                if ($id > 0) $api->put("admin/catalogos/detalles/{$id}", $payload);
                else $api->post('admin/catalogos/' . rawurlencode((string)$_POST['catalogo_codigo']), $payload);
            } else {
                [$path, $payload] = $this->payloadFor($entity);
                if ($id > 0) $api->put("admin/{$path}/{$id}", $payload);
                else $api->post("admin/{$path}", $payload);
            }
            $this->index($id > 0 ? 'Registro actualizado correctamente.' : 'Registro creado correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function destroy(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $entity = (string)($_POST['entity'] ?? '');
        $id = (int)($_POST['id'] ?? 0);
        $paths = [
            'eas'=>'eas','movil'=>'moviles','ruta'=>'rutas','lugar'=>'lugares-servicio',
            'grado'=>'grados','asignacion'=>'movil-eas-asignaciones','catalogo_detalle'=>'catalogos/detalles',
        ];
        $_GET['tab'] = (string)($_POST['tab'] ?? 'resumen');
        if (!empty($_POST['catalogo_codigo'])) $_GET['catalogo'] = $_POST['catalogo_codigo'];
        if ($id <= 0 || !isset($paths[$entity])) { $this->index('Seleccione un registro válido.'); return; }
        try {
            $this->api()->delete('admin/' . $paths[$entity] . '/' . $id);
            $this->index('Registro eliminado correctamente.');
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    private function payloadFor(string $entity): array
    {
        return match ($entity) {
            'eas' => ['eas', ['codigo'=>$this->text('codigo'),'nombre'=>$this->text('nombre'),'direccion'=>$this->text('direccion'),'ubicacion'=>$this->text('ubicacion'),'distritoId'=>$this->nullableInt($_POST['distrito_id'] ?? null),'activo'=>isset($_POST['activo'])]],
            'movil' => ['moviles', ['numeroMovil'=>$this->text('numero_movil'),'placa'=>$this->text('placa'),'tipoMovilId'=>(int)($_POST['tipo_movil_id'] ?? 0),'estadoMovilId'=>(int)($_POST['estado_movil_id'] ?? 0),'kilometrajeActual'=>(int)($_POST['kilometraje_actual'] ?? 0),'kilometrajeUltimoMantenimiento'=>(int)($_POST['kilometraje_ultimo_mantenimiento'] ?? 0),'proximoMantenimiento'=>$this->nullableInt($_POST['proximo_mantenimiento'] ?? null),'observacion'=>$this->text('observacion'),'activo'=>isset($_POST['activo'])]],
            'ruta' => ['rutas', ['nombre'=>$this->text('nombre'),'distritoId'=>$this->nullableInt($_POST['distrito_id'] ?? null),'turnoId'=>$this->nullableInt($_POST['turno_id'] ?? null),'horaInicio'=>$this->nullableText('hora_inicio'),'horaFin'=>$this->nullableText('hora_fin'),'activo'=>isset($_POST['activo'])]],
            'lugar' => ['lugares-servicio', ['nombre'=>$this->text('nombre'),'direccion'=>$this->text('direccion'),'ubicacionEspecifica'=>$this->text('ubicacion_especifica'),'distritoId'=>(int)($_POST['distrito_id'] ?? 0),'rutaId'=>(int)($_POST['ruta_id'] ?? 0),'tipoServicioId'=>$this->nullableInt($_POST['tipo_servicio_id'] ?? null),'turnoId'=>$this->nullableInt($_POST['turno_id'] ?? null),'cantidadRequerida'=>(int)($_POST['cantidad_requerida'] ?? 1),'estadoOperativo'=>$this->text('estado_operativo') ?: 'ACTIVO','consignas'=>$this->text('consignas'),'observacion'=>$this->text('observacion'),'latitud'=>$this->nullableFloat($_POST['latitud'] ?? null),'longitud'=>$this->nullableFloat($_POST['longitud'] ?? null),'activo'=>isset($_POST['activo'])]],
            'grado' => ['grados', ['nombre'=>$this->text('nombre'),'activo'=>isset($_POST['activo'])]],
            'asignacion' => ['movil-eas-asignaciones', ['easId'=>(int)($_POST['eas_id'] ?? 0),'movilId'=>(int)($_POST['movil_id'] ?? 0),'estadoAsignacionId'=>(int)($_POST['estado_asignacion_id'] ?? 0),'observacion'=>$this->text('observacion'),'activo'=>isset($_POST['activo'])]],
            'catalogo_detalle' => ['catalogos', ['codigo'=>$this->text('codigo'),'nombre'=>$this->text('nombre'),'descripcion'=>$this->text('descripcion'),'orden'=>(int)($_POST['orden'] ?? 0),'estado'=>isset($_POST['estado'])]],
            'mantenimiento' => ['mantenimiento', ['fechaMantenimiento'=>$this->text('fecha_mantenimiento'),'kilometraje'=>(int)($_POST['kilometraje'] ?? 0),'descripcion'=>$this->text('descripcion'),'tipoMantenimientoId'=>$this->nullableInt($_POST['tipo_mantenimiento_id'] ?? null)]],
            default => throw new \InvalidArgumentException('Entidad administrativa no válida.'),
        };
    }

    private function emptyData(): array
    {
        return ['eas'=>[],'moviles'=>[],'rutas'=>[],'lugares'=>[],'grados'=>[],'catalogos'=>[],'detallesCatalogo'=>[],'asignaciones'=>[],'mantenimientos'=>[],'referencias'=>[]];
    }

    private function api(): ApiClient { return new ApiClient(Config::get('API_BASE_URL'), AuthSession::token()); }
    private function text(string $key): string { return trim((string)($_POST[$key] ?? '')); }
    private function nullableText(string $key): ?string { $value=$this->text($key); return $value===''?null:$value; }
    private function nullableInt(mixed $value): ?int { $value=trim((string)$value); return $value===''?null:(int)$value; }
    private function nullableFloat(mixed $value): ?float { $value=trim((string)$value); return $value===''?null:(float)$value; }
    private function can(string $permission, array $user): bool
    {
        $role = strtoupper((string)($user['rolNombre'] ?? $user['rol'] ?? ''));
        return str_contains($role, 'ADMINISTRADOR') || in_array($permission, $user['permisos'] ?? [], true);
    }
}
