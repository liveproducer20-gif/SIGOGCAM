<?php

namespace App\Modules\Admin;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class AdminController
{
    private const TABS = ['resumen', 'catalogos', 'lugares', 'rutas', 'circuitos', 'grados', 'eas', 'moviles', 'asignaciones', 'mantenimiento'];

    public function index(?string $message = null, ?array $importPreview = null): void
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
            if ($this->can('circuitos.ver', $user)) {
                $query = http_build_query([
                    'distrito_id' => $this->nullableInt($_GET['distrito_id'] ?? null),
                    'buscar' => trim((string)($_GET['buscar'] ?? '')),
                ]);
                $data['circuitos'] = $api->get('admin/circuitos' . ($query !== '' ? '?' . $query : ''))['datos'] ?? [];
            }
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
            'importPreview' => $importPreview,
            'pageStyles' => ['/assets/css/admin-circuitos.css?v=20260816-import-dialogs'],
            'pageScripts' => ['/assets/js/admin-circuitos.js?v=20260816-import-dialogs'],
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
            if ($entity === 'circuito_rutas') {
                $api->put('admin/circuitos/' . $id . '/rutas', [
                    'rutaIds' => array_values(array_map('intval', (array)($_POST['ruta_ids'] ?? []))),
                ]);
            } elseif ($entity === 'mantenimiento') {
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
                $lugarFormacion = $this->text('lugar_formacion');
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
                        'lugarFormacion' => $lugarFormacion,
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

    public function downloadServicePlaceTemplate(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $user = AuthSession::user() ?? [];
        if (!$this->can('lugares_servicio.ver', $user)) {
            http_response_code(403);
            echo 'No tiene permiso para descargar la plantilla.';
            return;
        }
        header('Content-Type: text/csv; charset=UTF-8');
        header('Content-Disposition: attachment; filename="plantilla-lugares-servicio.csv"');
        header('Cache-Control: no-store');
        $output = fopen('php://output', 'wb');
        fwrite($output, "\xEF\xBB\xBF");
        fputcsv($output, self::CSV_HEADERS);
        fputcsv($output, [
            'Ruta Plaza Bicentenario', 'Olmedo acera norte y Eloy Alfaro',
            '10:30 a 18:00', 'Club de la Unión | Olmedo y Malecón',
            'Ejecución operativa control del espacio y vía pública en apoyo a la seguridad ciudadana.',
            'El encargado se hará cargo del interior y exterior del Parque Olmedo',
        ]);
        fclose($output);
    }

    public function downloadRouteTemplate(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $user = AuthSession::user() ?? [];
        if (!$this->can('rutas.ver', $user)) { http_response_code(403); echo 'No tiene permiso para descargar la plantilla.'; return; }
        header('Content-Type: text/csv; charset=UTF-8');
        header('Content-Disposition: attachment; filename="plantilla-rutas.csv"');
        header('Cache-Control: no-store');
        $output = fopen('php://output', 'wb');
        fwrite($output, "\xEF\xBB\xBF");
        fputcsv($output, self::ROUTE_CSV_HEADERS);
        fputcsv($output, ['Ruta Plaza Bicentenario','9 de Octubre','Segundo Turno','10:30','18:00','SI','SI']);
        fclose($output);
    }

    public function importRoutes(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $user = AuthSession::user() ?? [];
        $_GET['tab'] = 'rutas';
        if (!$this->can('catalogos.crear', $user)) { http_response_code(403); $this->index('No tiene permiso para importar rutas.'); return; }
        try {
            $action = (string)($_POST['import_action'] ?? 'preview');
            if ($action === 'confirm') {
                $token = (string)($_POST['import_token'] ?? '');
                $stored = $_SESSION['rutas_csv_import'][$token] ?? null;
                if (!is_array($stored)) throw new \RuntimeException('La vista previa expiró. Seleccione nuevamente el archivo CSV.');
                unset($_SESSION['rutas_csv_import'][$token]);
                $result = $this->api()->post('admin/rutas/importar', [
                    'filas'=>$stored, 'confirmar'=>true,
                    'accionesExistentes'=>(array)($_POST['existing_action'] ?? []),
                ])['datos'] ?? [];
                $this->index(sprintf(
                    'Importación completada: %d ruta(s) creada(s), %d actualizada(s) y %d fila(s) omitida(s).',
                    (int)($result['creados'] ?? 0), (int)($result['actualizados'] ?? 0), (int)($result['omitidos'] ?? 0)
                ));
                return;
            }
            $rows = $this->readRouteCsv($_FILES['archivo_csv'] ?? []);
            $preview = $this->api()->post('admin/rutas/importar', ['filas'=>$rows, 'confirmar'=>false])['datos'] ?? [];
            $token = bin2hex(random_bytes(16));
            $_SESSION['rutas_csv_import'] = [$token=>$rows];
            $preview['token'] = $token;
            $preview['tipo'] = 'rutas';
            $this->index(null, $preview);
        } catch (\Throwable $exception) {
            $this->index($exception->getMessage());
        }
    }

    public function importServicePlaces(): void
    {
        if (!AuthSession::check()) { header('Location: /'); return; }
        $user = AuthSession::user() ?? [];
        $_GET['tab'] = 'lugares';
        if (!$this->can('lugares_servicio.crear', $user)) {
            http_response_code(403);
            $this->index('No tiene permiso para importar lugares de servicio.');
            return;
        }

        try {
            $action = (string)($_POST['import_action'] ?? 'preview');
            if ($action === 'confirm') {
                $token = (string)($_POST['import_token'] ?? '');
                $stored = $_SESSION['lugares_csv_import'][$token] ?? null;
                if (!is_array($stored)) throw new \RuntimeException('La vista previa expiró. Seleccione nuevamente el archivo CSV.');
                $result = $this->api()->post('admin/lugares-servicio/importar', [
                    'filas'=>$stored,
                    'confirmar'=>true,
                    'accionesExistentes'=>(array)($_POST['existing_action'] ?? []),
                ])['datos'] ?? [];
                unset($_SESSION['lugares_csv_import'][$token]);
                $this->index(sprintf(
                    'Importación finalizada: %d lugar(es) creado(s), %d actualizado(s) y %d fila(s) omitida(s).',
                    (int)($result['importados'] ?? 0),
                    (int)($result['actualizados'] ?? 0),
                    (int)($result['omitidos'] ?? 0)
                ));
                return;
            }

            $rows = $this->readServicePlaceCsv($_FILES['archivo_csv'] ?? []);
            $preview = $this->api()->post('admin/lugares-servicio/importar', ['filas'=>$rows, 'confirmar'=>false])['datos'] ?? [];
            $token = bin2hex(random_bytes(16));
            $_SESSION['lugares_csv_import'] = [$token => $rows];
            $preview['token'] = $token;
            $this->index(null, $preview);
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
            'grado'=>'grados','asignacion'=>'movil-eas-asignaciones','catalogo_detalle'=>'catalogos/detalles','circuito'=>'circuitos',
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
            'ruta' => ['rutas', ['nombre'=>$this->text('nombre'),'distritoId'=>$this->nullableInt($_POST['distrito_id'] ?? null),'turnoId'=>$this->nullableInt($_POST['turno_id'] ?? null),'horaInicio'=>$this->nullableText('hora_inicio'),'horaFin'=>$this->nullableText('hora_fin'),'asignarEncargado'=>isset($_POST['asignar_encargado']),'activo'=>isset($_POST['activo'])]],
            'circuito' => ['circuitos', ['distritoId'=>(int)($_POST['distrito_id'] ?? 0),'nombre'=>$this->text('nombre'),'horaInicio'=>$this->nullableText('hora_inicio'),'horaFin'=>$this->nullableText('hora_fin'),'lugarFormacion'=>$this->text('lugar_formacion'),'consignas'=>$this->text('consignas'),'observaciones'=>$this->text('observaciones'),'perimetro'=>$this->text('perimetro'),'rutaIds'=>array_values(array_map('intval',(array)($_POST['ruta_ids'] ?? [])))]],
            'lugar' => ['lugares-servicio', ['nombre'=>$this->text('nombre'),'direccion'=>$this->text('direccion'),'ubicacionEspecifica'=>$this->text('ubicacion_especifica'),'distritoId'=>(int)($_POST['distrito_id'] ?? 0),'rutaId'=>(int)($_POST['ruta_id'] ?? 0),'tipoServicioId'=>$this->nullableInt($_POST['tipo_servicio_id'] ?? null),'turnoId'=>$this->nullableInt($_POST['turno_id'] ?? null),'cantidadRequerida'=>(int)($_POST['cantidad_requerida'] ?? 1),'estadoOperativo'=>$this->text('estado_operativo') ?: 'ACTIVO','consignas'=>$this->text('consignas'),'observacion'=>$this->text('observacion'),'lugarFormacion'=>$this->text('lugar_formacion'),'latitud'=>$this->nullableFloat($_POST['latitud'] ?? null),'longitud'=>$this->nullableFloat($_POST['longitud'] ?? null),'activo'=>isset($_POST['activo'])]],
            'grado' => ['grados', ['nombre'=>$this->text('nombre'),'activo'=>isset($_POST['activo'])]],
            'asignacion' => ['movil-eas-asignaciones', ['easId'=>(int)($_POST['eas_id'] ?? 0),'movilId'=>(int)($_POST['movil_id'] ?? 0),'estadoAsignacionId'=>(int)($_POST['estado_asignacion_id'] ?? 0),'observacion'=>$this->text('observacion'),'activo'=>isset($_POST['activo'])]],
            'catalogo_detalle' => ['catalogos', ['codigo'=>$this->text('codigo'),'nombre'=>$this->text('nombre'),'descripcion'=>$this->text('descripcion'),'orden'=>(int)($_POST['orden'] ?? 0),'asignarEncargado'=>isset($_POST['asignar_encargado']),'estado'=>isset($_POST['estado'])]],
            'mantenimiento' => ['mantenimiento', ['fechaMantenimiento'=>$this->text('fecha_mantenimiento'),'kilometraje'=>(int)($_POST['kilometraje'] ?? 0),'descripcion'=>$this->text('descripcion'),'tipoMantenimientoId'=>$this->nullableInt($_POST['tipo_mantenimiento_id'] ?? null)]],
            default => throw new \InvalidArgumentException('Entidad administrativa no válida.'),
        };
    }

    private function emptyData(): array
    {
        return ['eas'=>[],'moviles'=>[],'rutas'=>[],'circuitos'=>[],'lugares'=>[],'grados'=>[],'catalogos'=>[],'detallesCatalogo'=>[],'asignaciones'=>[],'mantenimientos'=>[],'referencias'=>[]];
    }

    private const CSV_HEADERS = [
        'Ruta', 'Lugar de servicio', 'Horario', 'Lugar de formación',
        'Consignas / Base legal', 'Observación',
    ];

    private const CSV_DB_KEYS = [
        'ruta', 'lugar_servicio', 'horario', 'lugar_formacion',
        'consignas', 'observacion',
    ];

    private const ROUTE_CSV_HEADERS = [
        'Nombre', 'Distrito', 'Turno', 'Hora inicio', 'Hora fin', 'Asignar encargado', 'Activa',
    ];

    private function readRouteCsv(array $file): array
    {
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) throw new \RuntimeException('Seleccione un archivo CSV válido.');
        if ((int)($file['size'] ?? 0) > 2 * 1024 * 1024) throw new \RuntimeException('El archivo CSV no puede superar 2 MB.');
        if (strtolower(pathinfo((string)($file['name'] ?? ''), PATHINFO_EXTENSION)) !== 'csv') throw new \RuntimeException('El archivo seleccionado debe tener extensión .csv.');
        $content = file_get_contents((string)$file['tmp_name']);
        if ($content === false || trim($content) === '') throw new \RuntimeException('El archivo CSV está vacío.');
        if (substr($content, 0, 3) === "\xEF\xBB\xBF") $content = substr($content, 3);
        if (!preg_match('//u', $content)) { $converted=iconv('Windows-1252','UTF-8//IGNORE',$content); if ($converted !== false) $content=$converted; }
        $stream=fopen('php://temp','w+b');fwrite($stream,$content);rewind($stream);
        $headers=fgetcsv($stream);$headers=is_array($headers)?array_map(static fn($value)=>trim((string)$value),$headers):[];
        if ($headers !== self::ROUTE_CSV_HEADERS) throw new \RuntimeException('Las columnas del CSV no coinciden con la plantilla oficial o no están en el orden requerido.');
        $rows=[];$line=1;
        while (($values=fgetcsv($stream)) !== false) {
            $line++;if(count(array_filter($values,static fn($value)=>trim((string)$value)!==''))===0)continue;
            $parseError=count($values)===count(self::ROUTE_CSV_HEADERS)?null:'La fila no contiene exactamente 7 columnas';
            $values=array_slice(array_pad($values,count(self::ROUTE_CSV_HEADERS),''),0,count(self::ROUTE_CSV_HEADERS));
            $raw=array_combine(self::ROUTE_CSV_HEADERS,array_map(static fn($value)=>trim((string)$value),$values));
            $row=['nombre'=>$raw['Nombre'],'distrito'=>$raw['Distrito'],'turno'=>$raw['Turno'],'hora_inicio'=>$raw['Hora inicio'],
                  'hora_fin'=>$raw['Hora fin'],'asignar_encargado'=>$raw['Asignar encargado'],'activa'=>$raw['Activa'],'fila'=>$line];
            if($parseError!==null)$row['_parse_error']=$parseError;$rows[]=$row;
        }
        fclose($stream);if(!$rows)throw new \RuntimeException('El archivo CSV no contiene filas para importar.');return $rows;
    }

    private function readServicePlaceCsv(array $file): array
    {
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            throw new \RuntimeException('Seleccione un archivo CSV válido.');
        }
        if ((int)($file['size'] ?? 0) > 2 * 1024 * 1024) {
            throw new \RuntimeException('El archivo CSV no puede superar 2 MB.');
        }
        if (strtolower(pathinfo((string)($file['name'] ?? ''), PATHINFO_EXTENSION)) !== 'csv') {
            throw new \RuntimeException('El archivo seleccionado debe tener extensión .csv.');
        }
        $content = file_get_contents((string)$file['tmp_name']);
        if ($content === false || trim($content) === '') throw new \RuntimeException('El archivo CSV está vacío.');
        if (substr($content, 0, 3) === "\xEF\xBB\xBF") $content = substr($content, 3);
        if (!preg_match('//u', $content)) {
            $converted = iconv('Windows-1252', 'UTF-8//IGNORE', $content);
            if ($converted !== false) $content = $converted;
        }
        $stream = fopen('php://temp', 'w+b');
        fwrite($stream, $content);
        rewind($stream);
        $headers = fgetcsv($stream);
        $headers = is_array($headers) ? array_map(static fn($value) => trim((string)$value), $headers) : [];

        $normalized = array_map(static fn($h) => preg_replace('/\s+/u', ' ', trim($h)), $headers);
        $expectedNorm = array_map(static fn($h) => preg_replace('/\s+/u', ' ', trim($h)), self::CSV_HEADERS);
        if ($normalized !== $expectedNorm) {
            throw new \RuntimeException(
                'Las columnas del CSV no coinciden con la plantilla oficial. '
                . 'Se esperan: ' . implode(', ', self::CSV_HEADERS)
            );
        }

        $colCount = count(self::CSV_HEADERS);
        $rows = [];
        $line = 1;
        while (($values = fgetcsv($stream)) !== false) {
            $line++;
            if (count(array_filter($values, static fn($value) => trim((string)$value) !== '')) === 0) continue;
            $parseError = count($values) === $colCount ? null : 'La fila no contiene exactamente ' . $colCount . ' columnas';
            $values = array_slice(array_pad($values, $colCount, ''), 0, $colCount);
            $displayRow = array_combine(self::CSV_HEADERS, array_map(static fn($value) => trim((string)$value), $values));
            $dbRow = array_combine(self::CSV_DB_KEYS, array_map(static fn($value) => trim((string)$value), $values));
            $dbRow['fila'] = $line;
            if ($parseError !== null) $dbRow['_parse_error'] = $parseError;
            $rows[] = $dbRow;
        }
        fclose($stream);
        if (!$rows) throw new \RuntimeException('El archivo CSV no contiene filas para importar.');
        return $rows;
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
