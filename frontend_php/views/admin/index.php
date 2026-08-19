<?php
$e = static fn(mixed $value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$can = static fn(string $permission): bool => !empty($isAdministrator) || in_array($permission, $permissions ?? [], true);
$json = static fn(array $value): string => htmlspecialchars((string)json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES), ENT_QUOTES, 'UTF-8');
$refs = $adminData['referencias'] ?? [];
$optionList = static function (array $items, string $placeholder = 'Seleccione'): void {
    echo '<option value="">' . htmlspecialchars($placeholder, ENT_QUOTES, 'UTF-8') . '</option>';
    foreach ($items as $item) echo '<option value="' . (int)$item['id'] . '">' . htmlspecialchars((string)($item['nombre'] ?? ''), ENT_QUOTES, 'UTF-8') . '</option>';
};
$tabUrl = static fn(string $name): string => '/admin?tab=' . rawurlencode($name);
?>
<section class="dashboard admin-workspace">
    <?php if (!empty($error)): ?><div class="alert"><?= $e($error) ?></div><?php endif; ?>
    <?php if (!empty($message)): ?><div class="success"><?= $e($message) ?></div><?php endif; ?>

    <nav class="admin-tabs" aria-label="Secciones de Administración">
        <a class="<?= $tab === 'resumen' ? 'is-active' : '' ?>" href="<?= $tabUrl('resumen') ?>">Resumen</a>
        <?php if ($can('personal.ver')): ?><a href="/personal">Personal</a><?php endif; ?>
        <?php if ($can('catalogos.ver')): ?><a class="<?= $tab === 'catalogos' ? 'is-active' : '' ?>" href="<?= $tabUrl('catalogos') ?>">Catálogos</a><?php endif; ?>
        <?php if ($can('roles.ver')): ?><a href="/configuracion">Roles</a><?php endif; ?>
        <?php if ($can('lugares_servicio.ver')): ?><a class="<?= $tab === 'lugares' ? 'is-active' : '' ?>" href="<?= $tabUrl('lugares') ?>">Lugares</a><?php endif; ?>
        <?php if ($can('rutas.ver')): ?><a class="<?= $tab === 'rutas' ? 'is-active' : '' ?>" href="<?= $tabUrl('rutas') ?>">Rutas</a><?php endif; ?>
        <?php if ($can('circuitos.ver')): ?><a class="<?= $tab === 'circuitos' ? 'is-active' : '' ?>" href="<?= $tabUrl('circuitos') ?>">Circuitos</a><?php endif; ?>
        <?php if ($can('personal.ver')): ?><a class="<?= $tab === 'grados' ? 'is-active' : '' ?>" href="<?= $tabUrl('grados') ?>">Grados</a><?php endif; ?>
        <?php if ($can('eas.ver')): ?><a class="<?= $tab === 'eas' ? 'is-active' : '' ?>" href="<?= $tabUrl('eas') ?>">EAS</a><?php endif; ?>
        <?php if ($can('moviles.ver')): ?><a class="<?= $tab === 'moviles' ? 'is-active' : '' ?>" href="<?= $tabUrl('moviles') ?>">Móviles</a><?php endif; ?>
        <?php if ($can('moviles.asignar')): ?><a class="<?= $tab === 'asignaciones' ? 'is-active' : '' ?>" href="<?= $tabUrl('asignaciones') ?>">Asignaciones</a><?php endif; ?>
        <?php if ($can('moviles.ver')): ?><a class="<?= $tab === 'mantenimiento' ? 'is-active' : '' ?>" href="<?= $tabUrl('mantenimiento') ?>">Mantenimiento</a><?php endif; ?>
    </nav>

    <?php if ($tab === 'resumen'): ?>
    <section class="admin-summary">
        <header><div><span class="eyebrow">Centro de control</span><h2>Administración operativa</h2><p>Información consolidada directamente desde la base de datos institucional.</p></div></header>
        <div class="admin-summary-grid">
            <?php foreach ([
                ['eas','EAS','Estaciones operativas','eas','⌂'],['moviles','Móviles','Unidades registradas','moviles','▣'],
                ['asignaciones','Asignaciones','Relaciones móvil–EAS','asignaciones','⇄'],['lugares','Lugares','Puntos de servicio','lugares','⌖'],
                ['rutas','Rutas','Recorridos configurados','rutas','↝'],['grados','Grados','Jerarquías registradas','grados','★'],
                ['catalogos','Catálogos','Catálogos maestros','catalogos','▤'],['mantenimientos','Mantenimientos','Historial de unidades','mantenimiento','⚙'],
            ] as [$key,$title,$description,$target,$icon]): ?>
            <a href="<?= $tabUrl($target) ?>"><i><?= $icon ?></i><span><strong><?= count($adminData[$key] ?? []) ?></strong><b><?= $title ?></b><small><?= $description ?></small></span></a>
            <?php endforeach; ?>
        </div>
    </section>
    <?php endif; ?>

    <?php if ($tab === 'eas' && $can('eas.ver')): ?>
    <header class="admin-section-heading"><div><h2>Estaciones de Atención y Servicio (EAS)</h2><p>Unidades operativas, ubicación, distrito y estado.</p></div><span><?= count($adminData['eas']) ?> registros</span></header>
    <?php if ($can('eas.crear') || $can('eas.editar')): ?>
    <form class="form-panel admin-form" method="post" action="/admin" id="form-eas"><input type="hidden" name="entity" value="eas"><input type="hidden" name="tab" value="eas"><input type="hidden" name="id">
        <div class="admin-form-title"><h3>Nueva EAS</h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div>
        <div class="form-grid"><label>Código<input name="codigo" required maxlength="30"></label><label>Nombre<input name="nombre" required maxlength="150"></label><label>Distrito<select name="distrito_id"><?php $optionList($refs['distritos'] ?? []); ?></select></label><label class="span-2">Dirección<input name="direccion" required maxlength="250"></label><label>Ubicación<input name="ubicacion" maxlength="150"></label><label class="check-row"><input type="checkbox" name="activo" checked> Activa</label></div><button type="submit">Guardar EAS</button>
    </form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Código</th><th>Nombre</th><th>Distrito</th><th>Dirección</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>
    <?php foreach ($adminData['eas'] as $item): $payload=['id'=>$item['id'],'codigo'=>$item['codigo'],'nombre'=>$item['nombre'],'distrito_id'=>$item['distrito_id'],'direccion'=>$item['direccion'],'ubicacion'=>$item['ubicacion'],'activo'=>(bool)$item['activo']]; ?>
    <tr><td><strong><?= $e($item['codigo']) ?></strong></td><td><?= $e($item['nombre']) ?></td><td><?= $e($item['distrito'] ?? '—') ?></td><td><?= $e($item['direccion']) ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $item['activo'] ? 'Activa' : 'Inactiva' ?></span></td><td class="actions"><?php if ($can('eas.editar')): ?><button type="button" class="secondary" data-edit-target="#form-eas" data-payload="<?= $json($payload) ?>">Editar</button><?php endif; ?><?php if ($can('eas.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="eas"><input type="hidden" name="tab" value="eas"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Eliminar</button></form><?php endif; ?></td></tr><?php endforeach; ?>
    </tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'moviles' && $can('moviles.ver')): ?>
    <header class="admin-section-heading"><div><h2>Parque automotor</h2><p>Datos técnicos, kilometraje, estado y EAS asignada.</p></div><span><?= count($adminData['moviles']) ?> unidades</span></header>
    <?php if ($can('moviles.crear') || $can('moviles.editar')): ?><form class="form-panel admin-form" method="post" action="/admin" id="form-movil"><input type="hidden" name="entity" value="movil"><input type="hidden" name="tab" value="moviles"><input type="hidden" name="id"><div class="admin-form-title"><h3>Nueva unidad</h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div><div class="form-grid"><label>Número móvil<input name="numero_movil" required></label><label>Placa<input name="placa"></label><label>Tipo<select name="tipo_movil_id" required><?php $optionList($refs['tiposMovil'] ?? []); ?></select></label><label>Estado<select name="estado_movil_id" required><?php $optionList($refs['estadosMovil'] ?? []); ?></select></label><label>Kilometraje actual<input type="number" min="0" name="kilometraje_actual" value="0"></label><label>Último mantenimiento<input type="number" min="0" name="kilometraje_ultimo_mantenimiento" value="0"></label><label>Próximo mantenimiento<input type="number" min="0" name="proximo_mantenimiento"></label><label class="span-2">Observación<textarea name="observacion" rows="2"></textarea></label><label class="check-row"><input type="checkbox" name="activo" checked> Activo</label></div><button type="submit">Guardar móvil</button></form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Unidad</th><th>Placa</th><th>Tipo</th><th>Estado</th><th>Kilometraje</th><th>EAS asignada</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['moviles'] as $item): $payload=['id'=>$item['id'],'numero_movil'=>$item['numero_movil'],'placa'=>$item['placa'],'tipo_movil_id'=>$item['tipo_movil_id'],'estado_movil_id'=>$item['estado_movil_id'],'kilometraje_actual'=>$item['kilometraje_actual'],'kilometraje_ultimo_mantenimiento'=>$item['kilometraje_ultimo_mantenimiento'],'proximo_mantenimiento'=>$item['proximo_mantenimiento'],'observacion'=>$item['observacion'],'activo'=>(bool)$item['activo']]; ?><tr><td><strong><?= $e($item['numero_movil']) ?></strong></td><td><?= $e($item['placa'] ?: '—') ?></td><td><?= $e($item['tipo_movil']) ?></td><td><?= $e($item['estado_movil']) ?></td><td><?= number_format((int)$item['kilometraje_actual'],0,',','.') ?> km</td><td><?= $e($item['eas_nombre'] ?? 'Sin asignación') ?></td><td class="actions"><?php if ($can('moviles.editar')): ?><button type="button" class="secondary" data-edit-target="#form-movil" data-payload="<?= $json($payload) ?>">Editar</button><?php endif; ?><?php if ($can('moviles.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="movil"><input type="hidden" name="tab" value="moviles"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Eliminar</button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'asignaciones' && $can('moviles.asignar')): ?>
    <header class="admin-section-heading"><div><h2>Asignaciones móvil–EAS</h2><p>Vinculación vigente e historial de unidades por estación.</p></div><span><?= count($adminData['asignaciones']) ?> asignaciones</span></header>
    <form class="form-panel admin-form" method="post" action="/admin" id="form-asignacion"><input type="hidden" name="entity" value="asignacion"><input type="hidden" name="tab" value="asignaciones"><input type="hidden" name="id"><div class="admin-form-title"><h3>Nueva asignación</h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div><div class="form-grid"><label>Ruta (EAS)<select name="ruta_id" id="asign-ruta" required><option value="">Seleccione ruta</option><?php foreach (($adminData['rutas'] ?? []) as $r): if ((int)($r['distrito_id'] ?? 0) !== 1143) continue; ?><option value="<?= (int)$r['id'] ?>"><?= $e($r['nombre']) ?></option><?php endforeach; ?></select></label><label>Lugar de servicio<select name="lugar_id" id="asign-lugar" required><option value="">Seleccione ruta primero</option></select></label><label>Móvil<select name="movil_id" required><?php foreach ($adminData['moviles'] as $m): ?><option value="<?= (int)$m['id'] ?>"><?= $e($m['numero_movil'] . ($m['placa'] ? ' · '.$m['placa'] : '')) ?></option><?php endforeach; ?></select></label><label>Estado<select name="estado_asignacion_id" required><?php $optionList($refs['estadosAsignacion'] ?? []); ?></select></label><label class="span-2">Observación<textarea name="observacion" rows="2"></textarea></label><label class="check-row"><input type="checkbox" name="activo" checked> Vigente</label></div><button type="submit">Guardar asignación</button></form>

    <script>
    (function(){
        var rutaSel = document.getElementById('asign-ruta');
        var lugarSel = document.getElementById('asign-lugar');
        if (!rutaSel || !lugarSel) return;
        function loadLugares(rutaId) {
            lugarSel.innerHTML = '<option value="">Cargando...</option>';
            if (!rutaId) { lugarSel.innerHTML = '<option value="">Seleccione ruta primero</option>'; return; }
            fetch('/api/admin/movil-eas-asignaciones/lugares-por-ruta?ruta_id=' + rutaId, {headers: {'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''}})
                .then(function(r){ return r.json(); })
                .then(function(d){
                    var lugares = d.datos || [];
                    lugarSel.innerHTML = '<option value="">Seleccione lugar</option>' + lugares.map(function(l){
                        return '<option value="' + l.id + '">' + l.nombre + '</option>';
                    }).join('');
                })
                .catch(function(){ lugarSel.innerHTML = '<option value="">Error al cargar</option>'; });
        }
        rutaSel.addEventListener('change', function(){ loadLugares(this.value); });
        // On edit, preload lugares for the current ruta
        var editBtns = document.querySelectorAll('[data-edit-target="#form-asignacion"]');
        editBtns.forEach(function(btn){
            btn.addEventListener('click', function(){
                var payload = JSON.parse(this.dataset.payload || '{}');
                if (payload.ruta_id) {
                    rutaSel.value = payload.ruta_id;
                    loadLugares(payload.ruta_id);
                    setTimeout(function(){ lugarSel.value = payload.lugar_id || ''; }, 300);
                }
            });
        });

        // CSV Import for Asignaciones
        var asignCsvInput = document.getElementById('asign-csv-input');
        var asignCsvReplace = document.getElementById('asign-csv-replace');
        var asignDialog = document.getElementById('asignImportDialog');
        var asignBody = document.getElementById('asignImportBody');
        var asignSummary = document.getElementById('asignImportSummary');
        var asignConfirm = document.getElementById('asignImportConfirm');
        var asignTotal = document.getElementById('asignTotal');
        var asignValid = document.getElementById('asignValid');
        var asignErrors = document.getElementById('asignErrors');
        var asignPreviewData = [];

        function parseAsignCsv(text) {
            var lines = text.replace(//g, '').split('
').filter(function(l){ return l.trim(); });
            if (lines.length < 2) return [];
            var headers = lines[0].split(',').map(function(h){ return h.trim().replace(/^"|"$/g, ''); });
            var rows = [];
            for (var i = 1; i < lines.length; i++) {
                var vals = lines[i].split(',').map(function(v){ return v.trim().replace(/^"|"$/g, ''); });
                var obj = {};
                headers.forEach(function(h, idx){ obj[h] = vals[idx] || ''; });
                rows.push(obj);
            }
            return rows;
        }

        function loadAsignCsv(file) {
            var reader = new FileReader();
            reader.onload = function(e) {
                var rows = parseAsignCsv(e.target.result);
                if (!rows.length) { alert('Archivo CSV vacio o formato incorrecto.'); return; }
                fetch('/api/admin/movil-eas-asignaciones/importar-preview', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                    body: JSON.stringify({rows: rows})
                })
                .then(function(r){ return r.json(); })
                .then(function(d) {
                    if (d.ok !== true) { alert(d.mensaje || 'Error al validar'); return; }
                    var datos = d.datos;
                    asignPreviewData = datos.filas;
                    asignTotal.textContent = datos.total;
                    asignValid.textContent = datos.validos;
                    asignErrors.textContent = datos.rechazados;
                    asignSummary.hidden = false;
                    asignConfirm.disabled = false;
                    asignConfirm.textContent = datos.rechazados > 0
                        ? 'Importar validos (' + datos.validos + '/' + datos.total + ')'
                        : 'Confirmar importacion (' + datos.validos + ')';
                    asignBody.innerHTML = datos.filas.map(function(f) {
                        var cls = f.valido ? 'is-valid' : 'is-invalid';
                        var icon = f.valido ? '✓' : '✗';
                        return '<tr class="' + cls + '"><td>' + f.fila + '</td><td>' + esc(f.ruta) + '</td><td>' + esc(f.lugar) + '</td><td>' + esc(f.movil) + '</td><td>' + esc(f.placa) + '</td><td>' + esc(f.estado) + '</td><td><span class="route-import-status">' + icon + ' ' + esc(f.resultado) + '</span></td></tr>';
                    }).join('');
                    asignDialog.showModal();
                })
                .catch(function(err){ alert('Error: ' + err.message); });
            };
            reader.readAsText(file);
        }

        if (asignCsvInput) asignCsvInput.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });
        if (asignCsvReplace) asignCsvReplace.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });

        if (asignConfirm) asignConfirm.addEventListener('click', function() {
            var validRows = asignPreviewData.filter(function(f){ return f.valido; });
            if (!validRows.length) { alert('No hay registros validos para importar.'); return; }
            this.disabled = true;
            this.textContent = 'Importando...';
            var self = this;
            fetch('/api/admin/movil-eas-asignaciones/importar-confirm', {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                body: JSON.stringify({rows: validRows})
            })
            .then(function(r){ return r.json(); })
            .then(function(d) {
                if (d.ok !== true) { alert(d.mensaje || 'Error al importar'); self.disabled = false; self.textContent = 'Confirmar importacion'; return; }
                asignDialog.close();
                alert('Importacion completada.
' + d.datos.creados + ' asignaciones creadas.');
                location.reload();
            })
            .catch(function(err){ alert('Error: ' + err.message); self.disabled = false; self.textContent = 'Confirmar importacion'; });
        });

        document.querySelectorAll('[data-asign-close]').forEach(function(btn) {
            btn.addEventListener('click', function() { asignDialog.close(); });
        });

    })();
    </script>
    <section class="table-wrap"><table><thead><tr><th>EAS / Ruta</th><th>Lugar de servicio</th><th>Móvil</th><th>Placa</th><th>Estado</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['asignaciones'] as $item): $payload=['id'=>$item['id'],'eas_id'=>$item['eas_id'],'movil_id'=>$item['movil_id'],'estado_asignacion_id'=>$item['estado_asignacion_id'],'lugar_id'=>$item['lugar_id'] ?? null,'ruta_id'=>$item['ruta_id'] ?? null,'observacion'=>$item['observacion'],'activo'=>(bool)$item['activo']]; ?><tr><td><strong><?= $e($item['eas_nombre'] ?? $item['eas_codigo']) ?></strong><br><small><?= $e($item['ruta_nombre'] ?? '—') ?></small></td><td><?= $e($item['lugar_nombre'] ?? '—') ?></td><td><strong><?= $e($item['numero_movil']) ?></strong></td><td><?= $e($item['placa'] ?: '—') ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>\"><?= $e($item['estado_asignacion']) ?></span></td><td class="actions"><button type="button" class="secondary" data-edit-target="#form-asignacion" data-payload="<?= $json($payload) ?>">Editar</button><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="asignacion"><input type="hidden" name="tab" value="asignaciones"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Cerrar</button></form></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'rutas' && $can('rutas.ver')): ?>
    <header class="admin-section-heading"><div><h2>Rutas operativas</h2><p>Gestiona las rutas operativas por distrito, circuito, turno y horario.</p></div><div class="admin-route-actions"><span class="admin-badge-count"><?= count($adminData['rutas']) ?> rutas registradas</span><a class="admin-action-btn admin-action-btn--ghost" href="/admin/rutas/plantilla.csv" title="Descargar plantilla CSV"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg> Plantilla</a><?php if ($can('catalogos.crear')): ?><form method="post" action="/admin/rutas/importar" enctype="multipart/form-data" style="display:inline"><input type="hidden" name="import_action" value="preview"><label class="admin-action-btn admin-action-btn--primary" for="route-csv" title="Importar rutas desde CSV"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg> Importar</label><input id="route-csv" name="archivo_csv" type="file" accept=".csv,text/csv" hidden required onchange="this.form.submit()"></form><?php endif; ?><?php if ($can('catalogos.crear') || $can('catalogos.editar')): ?><button type="button" class="admin-action-btn admin-action-btn--primary" id="btnCreateRoute" title="Crear nueva ruta"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg> Nueva ruta</button><?php endif; ?></div></header>
    <?php if (!empty($importPreview) && ($importPreview['tipo'] ?? '') === 'rutas'): ?>
    <dialog class="admin-route-import-dialog" id="routeImportDialog">
        <form method="post" action="/admin/rutas/importar"><input type="hidden" name="import_action" value="confirm"><input type="hidden" name="import_token" value="<?= $e($importPreview['token'] ?? '') ?>">
            <header><div><span class="eyebrow">Validación previa</span><h3>Importar rutas desde CSV</h3><p>Revise cada fila. Las rutas existentes se omiten salvo que seleccione actualizar.</p></div><button type="button" aria-label="Cerrar modal" data-import-close>&times;</button></header>
            <div class="admin-route-import-summary"><span>Total: <b><?= (int)($importPreview['total'] ?? 0) ?></b></span><span class="is-valid">Válidas: <b><?= (int)($importPreview['validos'] ?? 0) ?></b></span><span class="is-warning">Existentes: <b><?= (int)($importPreview['existentes'] ?? 0) ?></b></span><span class="is-invalid">Con errores: <b><?= (int)($importPreview['rechazados'] ?? 0) ?></b></span></div>
            <div class="admin-route-import-table"><table><thead><tr><th>Estado</th><th>Nombre</th><th>Distrito</th><th>Turno</th><th>Hora inicio</th><th>Hora fin</th><th>Encargado</th><th>Activa</th><th>Acción</th></tr></thead><tbody>
            <?php foreach (($importPreview['filas'] ?? []) as $row): $status=(string)($row['estado'] ?? 'ERROR'); ?><tr class="route-import-<?= strtolower($status) ?>"><td><span class="route-import-status"><?= $status === 'VALIDA' ? '✓ Válida' : ($status === 'EXISTENTE' ? '⚠ Existente' : '✕ Error') ?></span><?php if (!empty($row['errores'])): ?><ul class="csv-errors"><?php foreach ($row['errores'] as $reason): ?><li><?= $e($reason) ?></li><?php endforeach; ?></ul><?php endif; ?></td><td><strong><?= $e($row['nombre'] ?? '...') ?></strong></td><td><?= $e($row['distrito'] ?? '...') ?></td><td><?= $e($row['turno'] ?? '...') ?></td><td><?= $e($row['hora_inicio'] ?? '...') ?></td><td><?= $e($row['hora_fin'] ?? '...') ?></td><td><?= !empty($row['asignar_encargado']) ? 'Sí' : 'No' ?></td><td><?= !empty($row['activa']) ? 'Sí' : 'No' ?></td><td><?php if ($status === 'EXISTENTE'): ?><select name="existing_action[<?= (int)$row['fila'] ?>]"><option value="OMITIR">Omitir</option><option value="ACTUALIZAR">Actualizar existente</option></select><?php else: ?>—<?php endif; ?></td></tr><?php endforeach; ?>
            </tbody></table></div>
            <footer><a class="admin-import-cancel" href="/admin?tab=rutas">Cancelar</a><?php if ((int)($importPreview['validos'] ?? 0)+(int)($importPreview['existentes'] ?? 0)>0): ?><button type="submit">Confirmar importación</button><?php endif; ?></footer>
        </form>
    </dialog>
    <?php endif; ?>
    <?php $routeCircuits=[];foreach ($adminData['rutas'] as $route) { if (!empty($route['circuito_id'])) $routeCircuits[(int)$route['circuito_id']]=$route['circuito']; } asort($routeCircuits, SORT_NATURAL | SORT_FLAG_CASE); ?>
    <div class="admin-filter-carousel-card">
    <section class="admin-filter-bar" aria-label="Filtros de rutas">
        <div class="admin-filter-bar-inner">
            <div class="admin-filter-group">
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg> Distrito</span>
                    <select data-table-filter="admin-routes-table" data-filter-attribute="district"><option value="">Todos</option><?php foreach (($refs['distritos'] ?? []) as $district): ?><option value="<?= (int)$district['id'] ?>"><?= $e($district['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/></svg> Circuito</span>
                    <select data-table-filter="admin-routes-table" data-filter-attribute="circuit"><option value="">Todos</option><option value="__empty__">Sin circuito</option><?php foreach ($routeCircuits as $circuitId=>$circuitName): ?><option value="<?= (int)$circuitId ?>"><?= $e($circuitName) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg> Turno</span>
                    <select data-table-filter="admin-routes-table" data-filter-attribute="turno" data-filter-mode="contains"><option value="">Todos</option><?php foreach (($refs['turnos'] ?? []) as $turno): ?><option value="<?= (int)$turno['id'] ?>"><?= $e($turno['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field admin-filter-field--search">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg> Buscar ruta</span>
                    <input type="search" data-table-search="admin-routes-table" placeholder="Nombre de ruta...">
                </label>
            </div>
            <button type="button" class="admin-filter-clear" data-clear-table-filters="admin-routes-table" title="Limpiar filtros"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg> Limpiar filtros</button>
        </div>
    </section>
    <div id="routesCarousel" class="rc-slider"></div>
    </div>
    <script src="/assets/js/admin-carousel.js"></script>
    <script>
    (function(){
        var routeCounts = {};
        <?= json_encode(array_map(function($l) { return $l['ruta_id']; }, $adminData['lugares'] ?? [])) ?>.forEach(function(rid){ routeCounts[rid] = (routeCounts[rid] || 0) + 1; });
        var routes = <?= json_encode(array_map(function($r){ return ['id'=>$r['id'],'nombre'=>$r['nombre']]; }, $adminData['rutas']), JSON_UNESCAPED_UNICODE) ?>.map(function(r){ return { nombre: r.nombre, lugares: routeCounts[r.id] || 0 }; });
        if (routes.length) new RandomRouteInfoSlider(document.getElementById('routesCarousel'), { routes: routes, title: 'Lugares de servicio por ruta', subtitle: 'Orden aleatorio' });

        // CSV Import for Asignaciones
        var asignCsvInput = document.getElementById('asign-csv-input');
        var asignCsvReplace = document.getElementById('asign-csv-replace');
        var asignDialog = document.getElementById('asignImportDialog');
        var asignBody = document.getElementById('asignImportBody');
        var asignSummary = document.getElementById('asignImportSummary');
        var asignConfirm = document.getElementById('asignImportConfirm');
        var asignTotal = document.getElementById('asignTotal');
        var asignValid = document.getElementById('asignValid');
        var asignErrors = document.getElementById('asignErrors');
        var asignPreviewData = [];

        function parseAsignCsv(text) {
            var lines = text.replace(//g, '').split('
').filter(function(l){ return l.trim(); });
            if (lines.length < 2) return [];
            var headers = lines[0].split(',').map(function(h){ return h.trim().replace(/^"|"$/g, ''); });
            var rows = [];
            for (var i = 1; i < lines.length; i++) {
                var vals = lines[i].split(',').map(function(v){ return v.trim().replace(/^"|"$/g, ''); });
                var obj = {};
                headers.forEach(function(h, idx){ obj[h] = vals[idx] || ''; });
                rows.push(obj);
            }
            return rows;
        }

        function loadAsignCsv(file) {
            var reader = new FileReader();
            reader.onload = function(e) {
                var rows = parseAsignCsv(e.target.result);
                if (!rows.length) { alert('Archivo CSV vacio o formato incorrecto.'); return; }
                fetch('/api/admin/movil-eas-asignaciones/importar-preview', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                    body: JSON.stringify({rows: rows})
                })
                .then(function(r){ return r.json(); })
                .then(function(d) {
                    if (d.ok !== true) { alert(d.mensaje || 'Error al validar'); return; }
                    var datos = d.datos;
                    asignPreviewData = datos.filas;
                    asignTotal.textContent = datos.total;
                    asignValid.textContent = datos.validos;
                    asignErrors.textContent = datos.rechazados;
                    asignSummary.hidden = false;
                    asignConfirm.disabled = false;
                    asignConfirm.textContent = datos.rechazados > 0
                        ? 'Importar validos (' + datos.validos + '/' + datos.total + ')'
                        : 'Confirmar importacion (' + datos.validos + ')';
                    asignBody.innerHTML = datos.filas.map(function(f) {
                        var cls = f.valido ? 'is-valid' : 'is-invalid';
                        var icon = f.valido ? '✓' : '✗';
                        return '<tr class="' + cls + '"><td>' + f.fila + '</td><td>' + esc(f.ruta) + '</td><td>' + esc(f.lugar) + '</td><td>' + esc(f.movil) + '</td><td>' + esc(f.placa) + '</td><td>' + esc(f.estado) + '</td><td><span class="route-import-status">' + icon + ' ' + esc(f.resultado) + '</span></td></tr>';
                    }).join('');
                    asignDialog.showModal();
                })
                .catch(function(err){ alert('Error: ' + err.message); });
            };
            reader.readAsText(file);
        }

        if (asignCsvInput) asignCsvInput.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });
        if (asignCsvReplace) asignCsvReplace.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });

        if (asignConfirm) asignConfirm.addEventListener('click', function() {
            var validRows = asignPreviewData.filter(function(f){ return f.valido; });
            if (!validRows.length) { alert('No hay registros validos para importar.'); return; }
            this.disabled = true;
            this.textContent = 'Importando...';
            var self = this;
            fetch('/api/admin/movil-eas-asignaciones/importar-confirm', {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                body: JSON.stringify({rows: validRows})
            })
            .then(function(r){ return r.json(); })
            .then(function(d) {
                if (d.ok !== true) { alert(d.mensaje || 'Error al importar'); self.disabled = false; self.textContent = 'Confirmar importacion'; return; }
                asignDialog.close();
                alert('Importacion completada.
' + d.datos.creados + ' asignaciones creadas.');
                location.reload();
            })
            .catch(function(err){ alert('Error: ' + err.message); self.disabled = false; self.textContent = 'Confirmar importacion'; });
        });

        document.querySelectorAll('[data-asign-close]').forEach(function(btn) {
            btn.addEventListener('click', function() { asignDialog.close(); });
        });

    })();
    </script>
    <section class="table-wrap admin-table-modern"><table id="admin-routes-table"><thead><tr><th>Ruta</th><th>Distrito</th><th>Circuito</th><th>Turno</th><th>Horario</th><th>Encargado</th><th>Estado</th><th class="th-actions">Acciones</th></tr></thead><tbody><?php foreach ($adminData['rutas'] as $item): $payload=['id'=>$item['id'],'nombre'=>$item['nombre'],'distrito_id'=>$item['distrito_id'],'turnos_ids'=>array_map('intval',array_column($item['turnos'] ?? [],'turno_id')),'hora_inicio'=>$item['hora_inicio'],'hora_fin'=>$item['hora_fin'],'asignar_encargado'=>(bool)$item['asignar_encargado'],'activo'=>(bool)$item['activo']]; ?><tr data-district="<?= (int)($item['distrito_id'] ?? 0) ?>" data-circuit="<?= !empty($item['circuito_id']) ? (int)$item['circuito_id'] : '' ?>" data-turno="<?= $e(implode(',', array_column($item['turnos'] ?? [], 'turno_id'))) ?>"><td class="td-route-name"><strong><?= $e($item['nombre']) ?></strong></td><td><?= $e($item['distrito'] ?? '—') ?></td><td><?= $e($item['circuito'] ?? 'Sin circuito') ?></td><td><?php $turnos=$item['turnos'] ?? []; if($turnos): foreach($turnos as $t): ?><span class="admin-chip admin-chip--turno"><?= $e($t['turno']) ?></span> <?php endforeach; else: ?><span class="admin-chip">—</span><?php endif; ?></td><td class="td-schedule"><?= $e(($item['hora_inicio'] ?? '—').' – '.($item['hora_fin'] ?? '—')) ?></td><td><span class="status-pill <?= $item['asignar_encargado'] ? 'is-active' : '' ?>"><?= $item['asignar_encargado'] ? 'Permitido' : 'No requerido' ?></span></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $item['activo'] ? 'Activa' : 'Inactiva' ?></span></td><td class="actions admin-icon-actions"><?php if ($can('catalogos.editar')): ?><button type="button" class="admin-icon-btn admin-icon-btn--edit" data-edit-target="#form-ruta" data-payload="<?= $json($payload) ?>" title="Editar ruta"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button><?php endif; ?><?php if ($can('catalogos.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form" style="display:inline"><input type="hidden" name="entity" value="ruta"><input type="hidden" name="tab" value="rutas"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button type="submit" class="admin-icon-btn admin-icon-btn--delete" title="Eliminar ruta" onclick="return confirm('¿Eliminar esta ruta?')"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg></button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
    <?php if ($can('catalogos.crear') || $can('catalogos.editar')): ?>
    <dialog class="admin-route-dialog" id="routeDialog">
        <form method="post" action="/admin" id="form-ruta">
            <input type="hidden" name="entity" value="ruta">
            <input type="hidden" name="tab" value="rutas">
            <input type="hidden" name="id" id="routeFormId">
            <header class="admin-route-dialog-header">
                <div><span class="eyebrow" id="routeFormEyebrow">Nueva ruta</span><h3 id="routeFormTitle">Crear ruta operativa</h3><p id="routeFormSubtitle">Complete los datos de la ruta para registrarla en el sistema.</p></div>
                <button type="button" class="admin-route-dialog-close" id="closeRouteDialog" aria-label="Cerrar">&times;</button>
            </header>
            <div class="admin-route-dialog-body">
                <div class="admin-route-form-grid">
                    <label class="admin-route-field admin-route-field--full">Nombre de la ruta<input name="nombre" maxlength="180" required placeholder="Ej: Ruta Col\u00f3n | Primer Turno"></label>
                    <label class="admin-route-field">Distrito<select name="distrito_id" required><?php $optionList($refs['distritos'] ?? []); ?></select></label>
                    <fieldset class="admin-route-field admin-route-field--full" style="border:1px solid #dce4ef;border-radius:8px;padding:12px 14px;background:#fafcfd"><legend style="color:var(--sigo-navy);font-size:10px;font-weight:800;padding:0 6px">Turnos habilitados</legend><div style="display:flex;gap:16px;flex-wrap:wrap;margin-top:4px"><?php foreach (($refs['turnos'] ?? []) as $turno): ?><label style="display:flex;align-items:center;gap:6px;font-size:12px;cursor:pointer"><input type="checkbox" name="turnos_ids[]" value="<?= (int)$turno['id'] ?>" class="route-turno-checkbox" style="width:auto" data-turno-id="<?= (int)$turno['id'] ?>" data-turno-nombre="<?= $e($turno['nombre']) ?>"> <?= $e($turno['nombre']) ?></label><?php endforeach; ?></div>                    </fieldset>
                    <label class="admin-route-field route-static-time">Hora inicio<input type="time" name="hora_inicio"></label>
                    <label class="admin-route-field route-static-time">Hora fin<input type="time" name="hora_fin"></label>
                    <div class="admin-route-field admin-route-field--full" id="turnoHorariosContainer" style="display:none;border:1px solid #dce4ef;border-radius:8px;padding:12px 14px;background:#fafcfd"><legend style="color:var(--sigo-navy);font-size:10px;font-weight:800;padding:0 6px">Horarios por turno</legend><div id="turnoHorariosList" style="display:flex;flex-direction:column;gap:10px;margin-top:8px"></div></div>
                    <label class="admin-route-check"><input type="checkbox" name="asignar_encargado"><span>Asignar encargado</span></label>
                    <label class="admin-route-check"><input type="checkbox" name="activo" checked><span>Activa</span></label>
                </div>
            </div>
            <footer class="admin-route-dialog-footer">
                <button type="button" class="admin-action-btn" id="cancelRouteDialog">Cancelar</button>
                <button type="submit" class="admin-action-btn admin-action-btn--primary"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Guardar ruta</button>
            </footer>
        </form>
    </dialog>

    <dialog class="admin-route-dialog turn-disable-warning-modal" id="turnDisableWarningModal">
        <header class="admin-route-dialog-header">
            <div>
                <span class="eyebrow">Advertencia</span>
                <h3 id="turnWarningTitle">Deshabilitar turno</h3>
                <p id="turnWarningSubtitle">Existen lugares de servicio vinculados a este turno.</p>
            </div>
            <button type="button" class="admin-route-dialog-close" id="closeTurnWarning" aria-label="Cerrar">&times;</button>
        </header>
        <div class="admin-route-dialog-body">
            <div class="turn-warning-content">
                <div class="turn-warning-icon">⚠</div>
                <p id="turnWarningMessage">Existen <strong id="turnWarningCount">0</strong> lugar(es) de servicio vinculado(s) a este turno.</p>
                <p class="turn-warning-detail" id="turnWarningDetail">Si deshabilita este turno, estos lugares no estarán disponibles para distribución en este turno.</p>
            </div>
        </div>
        <footer class="admin-route-dialog-footer">
            <button type="button" class="admin-action-btn" id="cancelTurnWarning">Revisar lugares</button>
            <button type="button" class="admin-action-btn admin-action-btn--primary" id="confirmTurnDisable">Entendido, deshabilitar</button>
        </footer>
    </dialog>

    <?php endif; ?>
    <?php endif; ?>

    <?php if ($tab === 'circuitos' && $can('circuitos.ver')): ?>
    <?php
    $circuitos = $adminData['circuitos'] ?? [];
    $circuitPayload = static function (array $item): array {
        return [
            'id'=>(int)$item['id'],'distrito_id'=>(int)$item['distrito_id'],'nombre'=>$item['nombre'],
            'hora_inicio'=>$item['hora_inicio'],'hora_fin'=>$item['hora_fin'],'lugar_formacion'=>$item['lugar_formacion'],
            'consignas'=>$item['consignas'],'observaciones'=>$item['observaciones'],'perimetro'=>$item['perimetro'],
            'ruta_ids'=>$item['ruta_ids'] ?? [],
            'eas_ids'=>array_map('intval',array_column($item['eas_list'] ?? [],'eas_id')),
        ];
    };
    $estacionDistrictId = 1143;
    ?>
    <header class="admin-section-heading circuit-heading">
        <div><h2>Circuitos</h2><p>Organice las rutas de cada distrito y su equipo operativo.</p></div>
        <div class="admin-route-actions"><span class="admin-badge-count"><?= count($circuitos) ?> circuitos</span><a class="admin-action-btn admin-action-btn--ghost" href="/admin/rutas/plantilla.csv" title="Descargar plantilla CSV"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg> Plantilla</a><?php if ($can('circuitos.rutas')): ?><button type="button" class="admin-action-btn" data-circuit-import-open title="Importar rutas a circuito"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg> Importar</button><?php endif; ?><?php if ($can('circuitos.crear')): ?><button type="button" class="admin-action-btn admin-action-btn--primary" data-circuit-create title="Crear nuevo circuito"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg> Nuevo circuito</button><?php endif; ?></div>
    </header>
    <?php if ($can('circuitos.rutas')): ?><dialog class="circuit-dialog circuit-import-start" id="circuitRouteImportStartDialog"><form method="post" action="/admin/circuitos/rutas/importar" enctype="multipart/form-data"><input type="hidden" name="import_action" value="preview"><div class="dialog-title"><div><span class="eyebrow">Importación de rutas</span><h3>Importar rutas a un circuito</h3><p>Utilice la misma plantilla oficial del módulo Rutas.</p></div><button type="button" data-circuit-import-close aria-label="Cerrar">×</button></div><label>Circuito<select name="circuito_id" required><option value="">Seleccione circuito</option><?php foreach ($circuitos as $circuit): ?><option value="<?= (int)$circuit['id'] ?>"><?= $e($circuit['distrito'].' · '.$circuit['nombre']) ?></option><?php endforeach; ?></select></label><label>Archivo CSV<input name="archivo_csv" type="file" accept=".csv,text/csv" required></label><footer><button type="button" class="secondary" data-circuit-import-close>Cancelar</button><button type="submit">Validar archivo</button></footer></form></dialog><?php endif; ?>

    <?php if (!empty($importPreview) && ($importPreview['tipo'] ?? '') === 'circuito-rutas'): $importCircuit=$importPreview['circuito'] ?? []; ?>
    <dialog class="admin-route-import-dialog" id="circuitRouteImportPreviewDialog"><form method="post" action="/admin/circuitos/rutas/importar"><input type="hidden" name="import_action" value="confirm"><input type="hidden" name="import_token" value="<?= $e($importPreview['token'] ?? '') ?>"><header><div><span class="eyebrow">Validación previa</span><h3>Importar rutas · <?= $e($importCircuit['nombre'] ?? 'Circuito') ?></h3><p>Las rutas válidas quedarán vinculadas al circuito seleccionado.</p></div><button type="button" aria-label="Cerrar modal" data-import-close>&times;</button></header><div class="admin-route-import-summary"><span>Total: <b><?= (int)($importPreview['total'] ?? 0) ?></b></span><span class="is-valid">Válidas: <b><?= (int)($importPreview['validos'] ?? 0) ?></b></span><span class="is-warning">Existentes: <b><?= (int)($importPreview['existentes'] ?? 0) ?></b></span><span class="is-invalid">Con errores: <b><?= (int)($importPreview['rechazados'] ?? 0) ?></b></span></div><div class="admin-route-import-table"><table><thead><tr><th>Estado</th><th>Nombre</th><th>Distrito</th><th>Turno</th><th>Hora inicio</th><th>Hora fin</th><th>Encargado</th><th>Activa</th><th>Acción</th></tr></thead><tbody><?php foreach (($importPreview['filas'] ?? []) as $row): $status=(string)($row['estado'] ?? 'ERROR'); ?><tr class="route-import-<?= strtolower($status) ?>"><td><span class="route-import-status"><?= $status === 'VALIDA' ? '✓ Válida' : ($status === 'EXISTENTE' ? '⚠ Existente' : '✕ Error') ?></span><?php if (!empty($row['errores'])): ?><ul class="csv-errors"><?php foreach ($row['errores'] as $reason): ?><li><?= $e($reason) ?></li><?php endforeach; ?></ul><?php endif; ?></td><td><strong><?= $e($row['nombre'] ?? '...') ?></strong></td><td><?= $e($row['distrito'] ?? '...') ?></td><td><?= $e($row['turno'] ?? '...') ?></td><td><?= $e($row['hora_inicio'] ?? '...') ?></td><td><?= $e($row['hora_fin'] ?? '...') ?></td><td><?= !empty($row['asignar_encargado']) ? 'Sí' : 'No' ?></td><td><?= !empty($row['activa']) ? 'Sí' : 'No' ?></td><td><?php if ($status === 'EXISTENTE'): ?><select name="existing_action[<?= (int)$row['fila'] ?>]"><option value="VINCULAR">Vincular sin actualizar</option><option value="ACTUALIZAR">Actualizar y vincular</option><option value="OMITIR">Omitir</option></select><?php else: ?>—<?php endif; ?></td></tr><?php endforeach; ?></tbody></table></div><footer><a class="admin-import-cancel" href="/admin?tab=circuitos">Cancelar</a><?php if ((int)($importPreview['validos'] ?? 0)+(int)($importPreview['existentes'] ?? 0)>0): ?><button type="submit">Confirmar importación</button><?php endif; ?></footer></form></dialog>
    <?php endif; ?>
    <section class="admin-filter-bar" aria-label="Filtros de circuitos">
        <div class="admin-filter-bar-inner">
            <div class="admin-filter-group">
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg> Distrito</span>
                    <select data-table-filter="admin-circuits-table" data-filter-attribute="district"><option value="">Todos</option><?php foreach (($refs['distritos'] ?? []) as $district): ?><option value="<?= (int)$district['id'] ?>"><?= $e($district['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field admin-filter-field--search">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg> Buscar</span>
                    <input type="search" data-table-search="admin-circuits-table" placeholder="Nombre de circuito...">
                </label>
            </div>
            <button type="button" class="admin-filter-clear" data-clear-table-filters="admin-circuits-table" title="Limpiar filtros"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg></button>
        </div>
    </section>

    <?php if ($can('circuitos.crear') || $can('circuitos.editar')): ?>
    <?php $routeToCircuit = []; foreach (($adminData['circuitos'] ?? []) as $circ) { foreach (($circ['ruta_ids'] ?? []) as $rid) { $routeToCircuit[(int)$rid] = (int)$circ['id']; } } ?>
    <dialog class="admin-route-dialog circuit-dialog-modal" id="circuitDialog">
        <form method="post" action="/admin" id="form-circuito" data-estacion-district-id="<?= (int)$estacionDistrictId ?>">
            <input type="hidden" name="entity" value="circuito"><input type="hidden" name="tab" value="circuitos"><input type="hidden" name="id" id="circuitFormId">
            <header class="admin-route-dialog-header">
                <div><span class="eyebrow" id="circuitFormEyebrow">Nuevo circuito</span><h3 id="circuitFormTitle">Crear circuito</h3><p id="circuitFormSubtitle">Organice las rutas y recursos de un circuito operativo.</p></div>
                <button type="button" class="admin-route-dialog-close" id="closeCircuitDialog" aria-label="Cerrar">&times;</button>
            </header>
            <div class="admin-route-dialog-body">
                <div class="admin-route-form-grid">
                    <label class="admin-route-field">Distrito<select name="distrito_id" required><?php $optionList($refs['distritos'] ?? []); ?></select></label>
                    <label class="admin-route-field">Nombre del circuito<input name="nombre" maxlength="180" required id="circuitFormNombre"></label>
                    <label class="admin-route-field">Hora inicio<input type="time" name="hora_inicio"></label>
                    <label class="admin-route-field">Hora fin<input type="time" name="hora_fin"></label>
                    <label class="admin-route-field admin-route-field--full">Lugar de formación<input name="lugar_formacion" maxlength="300"></label>
                    <fieldset class="admin-route-field admin-route-field--full" style="border:1px solid #dce4ef;border-radius:8px;padding:14px;background:#fafcfd"><legend style="color:var(--sigo-navy);font-size:10px;font-weight:800;padding:0 6px">Rutas asignadas</legend><p style="margin:0 0 10px;color:var(--sigo-muted);font-size:10px" id="circuitRouteHint">Solo se habilitan rutas del distrito seleccionado.</p><div data-circuit-route-options style="display:grid;grid-template-columns:repeat(2,1fr);gap:6px"><?php foreach (($adminData['easEstacion'] ?? []) as $eas): ?><label class="circuit-route-option circuit-eas-option" data-eas-id="<?= (int)$eas['id'] ?>" hidden><input type="checkbox" name="eas_ids[]" value="<?= (int)$eas['id'] ?>"> <?= $e($eas['codigo'] . ' - ' . $eas['nombre']) ?></label><?php endforeach; ?><?php foreach (($refs['rutas'] ?? []) as $route): ?><label class="circuit-route-option" data-district-id="<?= (int)$route['distrito_id'] ?>" data-circuit-id="<?= (int)($routeToCircuit[(int)$route['id']] ?? 0) ?>" hidden><input type="checkbox" name="ruta_ids[]" value="<?= (int)$route['id'] ?>"> <?= $e($route['nombre']) ?></label><?php endforeach; ?></div></fieldset>
                    <label class="admin-route-field admin-route-field--full">Consignas<textarea name="consignas" rows="2"></textarea></label>
                    <label class="admin-route-field admin-route-field--full">Observaciones<textarea name="observaciones" rows="2"></textarea></label>
                    <label class="admin-route-field admin-route-field--full">Perímetro<textarea name="perimetro" rows="2" placeholder="Describa calles, límites y referencias"></textarea></label>
                </div>
            </div>
            <footer class="admin-route-dialog-footer">
                <button type="button" class="admin-action-btn" id="cancelCircuitDialog">Cancelar</button>
                <button type="submit" class="admin-action-btn admin-action-btn--primary"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Guardar circuito</button>
            </footer>
        </form>
    </dialog>
    <?php endif; ?>

    <section class="table-wrap admin-table-modern circuit-table"><table id="admin-circuits-table" data-search-cols="0,1,3"><thead><tr><th>Circuito</th><th>Distrito</th><th>Horario</th><th>Lugar de formación</th><th>Rutas / EAS</th><th class="th-actions">Acciones</th></tr></thead><tbody>
    <?php foreach ($circuitos as $item): $payload=$circuitPayload($item); ?>
        <tr data-district="<?= (int)$item['distrito_id'] ?>"><td><strong><?= $e($item['nombre']) ?></strong></td><td><?= $e($item['distrito']) ?></td><td><span class="admin-chip"><?= $e(($item['hora_inicio'] ?: '—').' – '.($item['hora_fin'] ?: '—')) ?></span></td><td><?= $e($item['lugar_formacion'] ?: '—') ?></td><td><?php if ((int)$item['distrito_id'] === (int)$estacionDistrictId): ?><strong><?= count($item['eas_list'] ?? []) ?></strong><small><?= $e(implode(', ', array_map(fn($e) => $e['eas_codigo'], $item['eas_list'] ?? [])) ?: 'Sin EAS') ?></small><?php else: ?><strong><?= (int)$item['total_rutas'] ?></strong><small><?= $e($item['rutas'] ?: 'Sin rutas') ?></small><?php endif; ?></td>
        <td class="actions admin-icon-actions">
            <button type="button" class="admin-icon-btn" data-circuit-view data-payload="<?= $json(array_merge($payload,['distrito'=>$item['distrito'],'rutas'=>$item['rutas']])) ?>" title="Ver detalles"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg></button>
            <?php if ($can('circuitos.editar')): ?><button type="button" class="admin-icon-btn admin-icon-btn--edit" data-edit-target="#form-circuito" data-circuit-edit data-payload="<?= $json($payload) ?>" title="Editar circuito"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg></button><?php endif; ?>
            <?php if ($can('circuitos.rutas') && (int)$item['distrito_id'] !== (int)$estacionDistrictId): ?><button type="button" class="admin-icon-btn" data-circuit-routes data-id="<?= (int)$item['id'] ?>" data-name="<?= $e($item['nombre']) ?>" data-district="<?= (int)$item['distrito_id'] ?>" data-routes="<?= $e(implode(',',array_map('intval',$item['ruta_ids'] ?? []))) ?>" title="Gestionar rutas"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/></svg></button><?php endif; ?>
            <?php if ($can('circuitos.eliminar')): ?><form method="post" action="/admin/eliminar" class="inline-form" style="display:inline"><input type="hidden" name="entity" value="circuito"><input type="hidden" name="tab" value="circuitos"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button type="submit" class="admin-icon-btn admin-icon-btn--delete" title="Eliminar circuito" onclick="return confirm('¿Eliminar este circuito?')"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg></button></form><?php endif; ?>
        </td></tr>
    <?php endforeach; ?></tbody></table></section>

    <dialog class="circuit-dialog" id="circuitViewDialog"><form method="dialog"><button aria-label="Cerrar">×</button></form><h3 data-view-name></h3><dl data-circuit-view-content></dl></dialog>
    <dialog class="circuit-dialog" id="circuitRoutesDialog"><form method="post" action="/admin" id="circuitRoutesForm"><input type="hidden" name="entity" value="circuito_rutas"><input type="hidden" name="tab" value="circuitos"><input type="hidden" name="id"><div class="dialog-title"><h3>Gestionar rutas · <span data-routes-name></span></h3><button type="button" data-dialog-close>×</button></div><div class="dialog-route-list"><?php foreach (($refs['rutas'] ?? []) as $route): ?><label data-district-id="<?= (int)$route['distrito_id'] ?>" data-circuit-id="<?= (int)($routeToCircuit[(int)$route['id']] ?? 0) ?>"><input type="checkbox" name="ruta_ids[]" value="<?= (int)$route['id'] ?>"> <?= $e($route['nombre']) ?></label><?php endforeach; ?></div><button type="submit">Guardar rutas</button></form></dialog>
    <?php endif; ?>

    <?php if ($tab === 'grados' && $can('personal.ver')): ?>
    <header class="admin-section-heading"><div><h2>Grados institucionales</h2><p>Jerarquías disponibles para el personal.</p></div><span><?= count($adminData['grados']) ?> grados</span></header>
    <?php if ($can('catalogos.crear') || $can('catalogos.editar')): ?><form class="form-panel admin-form admin-form-compact" method="post" action="/admin" id="form-grado"><input type="hidden" name="entity" value="grado"><input type="hidden" name="tab" value="grados"><input type="hidden" name="id"><label>Nombre del grado<input name="nombre" required></label><label class="check-row"><input type="checkbox" name="activo" checked> Activo</label><button type="submit">Guardar grado</button><button type="reset" class="secondary" data-admin-reset>Limpiar</button></form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>ID</th><th>Grado</th><th>Estado</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['grados'] as $item): $payload=['id'=>$item['id'],'nombre'=>$item['nombre'],'activo'=>(bool)$item['activo']]; ?><tr><td><?= (int)$item['id'] ?></td><td><strong><?= $e($item['nombre']) ?></strong></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $item['activo'] ? 'Activo' : 'Inactivo' ?></span></td><td class="actions"><?php if ($can('catalogos.editar')): ?><button type="button" class="secondary" data-edit-target="#form-grado" data-payload="<?= $json($payload) ?>">Editar</button><?php endif; ?><?php if ($can('catalogos.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="grado"><input type="hidden" name="tab" value="grados"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Eliminar</button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'catalogos' && $can('catalogos.ver')): ?>
    <header class="admin-section-heading"><div><h2>Catálogos maestros</h2><p>Valores compartidos por los módulos del sistema.</p></div><span><?= count($adminData['catalogos']) ?> catálogos</span></header>
    <form class="admin-catalog-picker" method="get" action="/admin"><input type="hidden" name="tab" value="catalogos"><label>Catálogo<select name="catalogo" onchange="this.form.submit()"><?php foreach ($adminData['catalogos'] as $catalog): ?><option value="<?= $e($catalog['codigo']) ?>" <?= $catalogCode === $catalog['codigo'] ? 'selected' : '' ?>><?= $e($catalog['nombre'].' ('.$catalog['total_detalles'].')') ?></option><?php endforeach; ?></select></label><noscript><button>Consultar</button></noscript></form>
    <?php if ($can('catalogos.crear') || $can('catalogos.editar')): ?><form class="form-panel admin-form" method="post" action="/admin" id="form-catalogo"><input type="hidden" name="entity" value="catalogo_detalle"><input type="hidden" name="tab" value="catalogos"><input type="hidden" name="catalogo_codigo" value="<?= $e($catalogCode) ?>"><input type="hidden" name="id"><div class="admin-form-title"><h3>Detalle de <?= $e($catalogCode) ?></h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div><div class="form-grid"><label>Código<input name="codigo" required></label><label>Nombre<input name="nombre" required></label><label>Orden<input type="number" name="orden" value="0"></label><label class="span-2">Descripción<input name="descripcion"></label><?php if ($catalogCode === 'DISTRITOS'): ?><label class="check-row"><input type="checkbox" name="asignar_encargado"> Asignar encargado</label><?php endif; ?><label class="check-row"><input type="checkbox" name="estado" checked> Activo</label></div><button type="submit">Guardar detalle</button></form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Orden</th><th>Código</th><th>Nombre</th><th>Descripción</th><?php if ($catalogCode === 'DISTRITOS'): ?><th>Encargado</th><?php endif; ?><th>Estado</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['detallesCatalogo'] as $item): $payload=['id'=>$item['id'],'codigo'=>$item['codigo'],'nombre'=>$item['nombre'],'descripcion'=>$item['descripcion'],'orden'=>$item['orden'],'asignar_encargado'=>(bool)$item['asignar_encargado'],'estado'=>(bool)$item['estado']]; ?><tr><td><?= (int)$item['orden'] ?></td><td><strong><?= $e($item['codigo']) ?></strong></td><td><?= $e($item['nombre']) ?></td><td><?= $e($item['descripcion'] ?: '—') ?></td><?php if ($catalogCode === 'DISTRITOS'): ?><td><span class="status-pill <?= $item['asignar_encargado'] ? 'is-active' : '' ?>"><?= $item['asignar_encargado'] ? 'Requerido' : 'No requerido' ?></span></td><?php endif; ?><td><span class="status-pill <?= $item['estado'] ? 'is-active' : '' ?>"><?= $item['estado'] ? 'Activo' : 'Inactivo' ?></span></td><td class="actions"><?php if ($can('catalogos.editar')): ?><button type="button" class="secondary" data-edit-target="#form-catalogo" data-payload="<?= $json($payload) ?>">Editar</button><?php endif; ?><?php if ($can('catalogos.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="catalogo_detalle"><input type="hidden" name="tab" value="catalogos"><input type="hidden" name="catalogo_codigo" value="<?= $e($catalogCode) ?>"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Eliminar</button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'lugares' && $can('lugares_servicio.ver')): ?>
    <header class="admin-section-heading"><div><h2>Lugares de servicio</h2><p>Gestiona los puntos operativos asociados a distritos, circuitos y rutas.</p></div><div class="admin-route-actions"><span class="admin-badge-count"><?= count($adminData['lugares']) ?> lugares registrados</span><a class="admin-action-btn admin-action-btn--ghost" href="/admin/lugares-servicio/plantilla.csv" title="Descargar plantilla CSV"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg> Plantilla</a><?php if ($can('lugares_servicio.crear')): ?><form method="post" action="/admin/lugares-servicio/importar" enctype="multipart/form-data" style="display:inline"><input type="hidden" name="import_action" value="preview"><label class="admin-action-btn admin-action-btn--primary" for="service-place-csv" title="Importar lugares desde CSV"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg> Importar</label><input id="service-place-csv" name="archivo_csv" type="file" accept=".csv,text/csv" hidden required onchange="this.form.submit()"></form><?php endif; ?><?php if ($can('lugares_servicio.crear') || $can('lugares_servicio.editar')): ?><button type="button" class="admin-action-btn admin-action-btn--primary" id="btnCreatePlace" title="Crear nuevo lugar de servicio"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg> Nuevo lugar</button><?php endif; ?></div></header>
    <?php if (!empty($importPreview)): ?>
    <dialog class="admin-route-import-dialog admin-service-place-import-dialog" id="servicePlaceImportDialog" aria-labelledby="service-place-csv-title">
        <form method="post" action="/admin/lugares-servicio/importar">
            <input type="hidden" name="import_action" value="confirm"><input type="hidden" name="import_token" value="<?= $e($importPreview['token'] ?? '') ?>">
            <header><div><span class="eyebrow">Validación previa</span><h3 id="service-place-csv-title">Importar lugares de servicio</h3><p>Revise cada fila. Al confirmar se guardarán únicamente los registros válidos.</p></div><button type="button" aria-label="Cerrar modal" data-import-close>&times;</button></header>
            <div class="admin-route-import-summary"><span>Total: <b><?= (int)($importPreview['total'] ?? 0) ?></b></span><span class="is-valid">Válidos: <b><?= (int)($importPreview['validos'] ?? 0) ?></b></span><span class="is-invalid">Errores: <b><?= (int)($importPreview['rechazados'] ?? 0) ?></b></span><span class="is-warning">Duplicados: <b><?= (int)($importPreview['duplicados'] ?? 0) ?></b></span></div>
            <div class="admin-route-import-table"><table><thead><tr><th>Estado</th><th>Ruta</th><th>Lugar de servicio</th><th>Horario</th><th>Tipo de servicio</th><th>Acción</th><th>Detalle</th></tr></thead><tbody>
            <?php foreach (($importPreview['filas'] ?? []) as $idx => $row): $isValid=!empty($row['valida']);$isDup=!empty($row['duplicado']);$rowClass=$isValid&&!$isDup?'route-import-valida':($isDup?'route-import-existente':'route-import-error');$detailId='csv-detail-'.$idx; ?>
                <tr class="<?= $rowClass ?>"><td><?php if ($isValid && !$isDup): ?><span class="route-import-status">✓ Válido</span><?php elseif ($isDup): ?><span class="route-import-status">⚠ Duplicado</span><?php else: ?><span class="route-import-status">✕ Error</span><?php endif; ?><?php if (!empty($row['errores'])): ?><ul class="csv-errors"><?php foreach ($row['errores'] as $reason): ?><li><?= $e($reason) ?></li><?php endforeach; ?></ul><?php endif; ?></td><td><?= $e($row['ruta'] ?? '') ?></td><td><strong><?= $e($row['lugar_servicio'] ?? '') ?></strong></td><td><?= $e($row['horario'] ?: '...') ?></td><td><?= $e($row['tipo_servicio'] ?: '...') ?></td><td><?php if (($row['tipo_duplicado'] ?? '') === 'BASE_DATOS'): ?><select name="existing_action[<?= (int)$row['fila'] ?>]"><option value="OMITIR">Omitir</option><option value="ACTUALIZAR">Actualizar</option></select><?php elseif (($row['tipo_duplicado'] ?? '') === 'ARCHIVO'): ?><select disabled><option>Omitir</option></select><?php else: ?>—<?php endif; ?></td><td><button type="button" class="csv-toggle-detail" data-toggle-text data-target="<?= $detailId ?>" aria-expanded="false" aria-controls="<?= $detailId ?>">Detalle</button></td></tr>
                <tr class="csv-detail-row" id="<?= $detailId ?>" hidden><td colspan="7"><div class="csv-detail-content"><div class="csv-detail-pair"><span class="csv-detail-label">Lugar de formación:</span><span class="csv-detail-value"><?= $e($row['lugar_formacion'] ?: '...') ?></span></div><div class="csv-detail-pair"><span class="csv-detail-label">Consignas / Base legal:</span><span class="csv-detail-value"><?= $e($row['consignas'] ?: '...') ?></span></div><div class="csv-detail-pair"><span class="csv-detail-label">Observación:</span><span class="csv-detail-value"><?= $e($row['observacion'] ?: '...') ?></span></div></div></td></tr>
            <?php endforeach; ?>
            </tbody></table></div>
            <footer><a class="admin-import-cancel" href="/admin?tab=lugares">Cancelar</a><?php if ((int)($importPreview['validos'] ?? 0)+(int)($importPreview['existentes'] ?? 0)>0): ?><button type="submit">Confirmar importación</button><?php endif; ?></footer>
        </form>
    </dialog>
    <?php endif; ?>
    <?php if ($can('lugares_servicio.crear') || $can('lugares_servicio.editar')): ?>
    <dialog class="admin-route-dialog place-dialog-modal" id="placeDialog">
        <form method="post" action="/admin" id="form-lugar">
            <input type="hidden" name="entity" value="lugar">
            <input type="hidden" name="tab" value="lugares">
            <input type="hidden" name="id" id="placeFormId">
            <input type="hidden" name="direccion">
            <!-- turno_id replaced by turnos_ids[] checkboxes -->
            <input type="hidden" name="estado_operativo" value="ACTIVO">
            <input type="hidden" name="latitud">
            <input type="hidden" name="longitud">
            <input type="hidden" name="activo" value="1">
            <header class="admin-route-dialog-header">
                <div><span class="eyebrow" id="placeFormEyebrow">Nuevo lugar</span><h3 id="placeFormTitle">Crear lugar de servicio</h3><p id="placeFormSubtitle">Registre un punto operativo asociado a una ruta.</p></div>
                <button type="button" class="admin-route-dialog-close" id="closePlaceDialog" aria-label="Cerrar">&times;</button>
            </header>
            <div class="admin-route-dialog-body">
                <div class="admin-route-form-grid">
                    <label class="admin-route-field">Distrito<select name="distrito_id" id="lugar-distrito" required><?php $optionList($refs['distritos'] ?? []); ?></select></label>
                    <label class="admin-route-field">Ruta<select name="ruta_id" id="lugar-ruta" required><option value="">Seleccione</option><?php foreach ($adminData['rutas'] as $r): ?><option value="<?= (int)$r['id'] ?>" data-distrito="<?= (int)($r['distrito_id'] ?? 0) ?>"><?= $e($r['nombre']) ?></option><?php endforeach; ?></select></label>
                    <label class="admin-route-field">Tipo de servicio<select name="tipo_servicio_id"><?php $optionList($refs['tiposServicio'] ?? []); ?></select></label>
                    <div class="admin-route-field admin-route-field--full" id="lugar-turnos-container" style="display:none"><fieldset style="border:1px solid #dce4ef;border-radius:8px;padding:12px 14px;background:#fafcfd"><legend style="color:var(--sigo-navy);font-size:10px;font-weight:800;padding:0 6px">Turnos en los que opera este lugar</legend><div id="lugar-turnos-checks" style="display:flex;gap:16px;flex-wrap:wrap;margin-top:4px"></div></fieldset></div>
                    <label class="admin-route-field">Cantidad requerida<input type="number" name="cantidad_requerida" id="lugar-cantidad" min="1" value="1"></label>
                    <label class="admin-route-field admin-route-field--full">Horario<input type="text" name="ubicacion_especifica" placeholder="Ej. 09:30 a 17:00"></label>
                </div>
                <div id="lugares-list" class="admin-route-form-grid" style="margin-top:14px">
                    <label class="admin-route-field admin-route-field--full lugar-row">Nombre del lugar de servicio<div style="display:flex;gap:8px;align-items:center"><input type="text" name="nombre[]" placeholder="Ingrese el nombre" required style="flex:1"><button type="button" class="remove-lugar admin-icon-btn admin-icon-btn--delete" title="Quitar"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg></button></div></label>
                </div>
                <button type="button" id="add-lugar" class="admin-action-btn" style="margin:12px 0"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg> Agregar otro lugar</button>
                <div class="admin-route-form-grid">
                    <label class="admin-route-field admin-route-field--full">Consignas<textarea name="consignas" rows="2"></textarea></label>
                    <label class="admin-route-field admin-route-field--full">Observación<textarea name="observacion" rows="2"></textarea></label>
                    <label class="admin-route-field admin-route-field--full">Lugar de Formación<textarea name="lugar_formacion" rows="2"></textarea></label>
                </div>
            </div>
            <footer class="admin-route-dialog-footer">
                <button type="button" class="admin-action-btn" id="cancelPlaceDialog">Cancelar</button>
                <button type="submit" class="admin-action-btn admin-action-btn--primary"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> Guardar lugares</button>
            </footer>
        </form>
    </dialog>
    <script>
    (function(){
        var distritoSel = document.getElementById('lugar-distrito');
        var rutaSel = document.getElementById('lugar-ruta');
        var todasRutas = Array.from(rutaSel.options).filter(function(o){ return o.value !== ''; });
        var placeDialog = document.getElementById('placeDialog');
        var placeForm = document.getElementById('form-lugar');

        var rutaTurnosMap = <?= json_encode(array_reduce($adminData['rutas'] ?? [], function(array $acc, array $r) { $acc[(int)$r['id']] = $r['turnos'] ?? []; return $acc; }, []), JSON_UNESCAPED_UNICODE) ?>;
        var turnoNombres = <?= json_encode(array_column($refs['turnos'] ?? [], 'nombre', 'id'), JSON_UNESCAPED_UNICODE) ?>;

        function renderPlaceTurnos(routeId, selectedIds) {
            var container = document.getElementById('lugar-turnos-container');
            var checks = document.getElementById('lugar-turnos-checks');
            checks.innerHTML = '';
            if (!routeId || !rutaTurnosMap[routeId]) { container.style.display = 'none'; return; }
            container.style.display = '';
            var turns = rutaTurnosMap[routeId];
            turns.forEach(function(t) {
                var label = document.createElement('label');
                label.style.cssText = 'display:flex;align-items:center;gap:6px;font-size:12px;cursor:pointer';
                var cb = document.createElement('input');
                cb.type = 'checkbox';
                cb.name = 'turnos_ids[]';
                cb.value = t.turno_id;
                cb.style.width = 'auto';
                if (selectedIds && selectedIds.indexOf(t.turno_id) !== -1) cb.checked = true;
                label.appendChild(cb);
                label.appendChild(document.createTextNode(' ' + t.turno));
                checks.appendChild(label);
            });
        }

        rutaSel.addEventListener('change', function(){
            renderPlaceTurnos(Number(this.value), []);
        });

        distritoSel.addEventListener('change', function(){
            var dId = this.value;
            rutaSel.innerHTML = '';
            var defaultOpt = document.createElement('option');
            defaultOpt.value = '';
            defaultOpt.textContent = 'Seleccione';
            rutaSel.appendChild(defaultOpt);
            todasRutas.forEach(function(o){
                if(!dId || o.getAttribute('data-distrito') === dId){
                    rutaSel.appendChild(o.cloneNode(true));
                }
            });
            document.getElementById('lugar-turnos-container').style.display = 'none';
        });

        document.getElementById('add-lugar').addEventListener('click', function(){
            var list = document.getElementById('lugares-list');
            var label = document.createElement('label');
            label.className = 'admin-route-field admin-route-field--full lugar-row';
            label.innerHTML = 'Nombre del lugar de servicio <div style="display:flex;gap:8px;align-items:center"><input type="text" name="nombre[]" placeholder="Ingrese el nombre" required style="flex:1"><button type="button" class="remove-lugar admin-icon-btn admin-icon-btn--delete" title="Quitar"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg></button></div>';
            list.appendChild(label);
        });

        document.getElementById('lugares-list').addEventListener('click', function(e){
            if(e.target.closest('.remove-lugar')){
                var rows = document.querySelectorAll('.lugar-row');
                if(rows.length > 1) e.target.closest('.lugar-row').remove();
            }
        });

        document.getElementById('btnCreatePlace')?.addEventListener('click', function(){
            placeForm.reset();
            document.getElementById('placeFormId').value = '';
            document.getElementById('placeFormTitle').textContent = 'Crear lugar de servicio';
            document.getElementById('placeFormEyebrow').textContent = 'Nuevo lugar';
            document.getElementById('placeFormSubtitle').textContent = 'Registre un punto operativo asociado a una ruta.';
            placeDialog.showModal();
        });
        document.getElementById('closePlaceDialog')?.addEventListener('click', function(){ placeDialog.close(); });
        document.getElementById('cancelPlaceDialog')?.addEventListener('click', function(){ placeDialog.close(); });
        placeDialog?.addEventListener('click', function(e){ if(e.target === placeDialog) placeDialog.close(); });

        function attachPlaceEditHandlers(){
            document.querySelectorAll('[data-edit-service-place]').forEach(function(btn){
                btn.addEventListener('click', function(){
                    var payload = JSON.parse(btn.dataset.payload || '{}');
                    placeForm.reset();
                    document.querySelectorAll('#lugar-turnos-checks input[type=checkbox]').forEach(function(cb){ cb.checked = false; });
                    Object.keys(payload).forEach(function(key){
                        if (key === 'turnos_ids') return;
                        if (key === 'nombre') {
                            var nombreInput = placeForm.querySelector('input[name="nombre[]"]');
                            if (nombreInput) nombreInput.value = payload[key] ?? '';
                            return;
                        }
                        var field = placeForm.querySelector('[name="' + key + '"]');
                        if(!field) return;
                        if(field.type === 'checkbox') field.checked = Boolean(payload[key]);
                        else field.value = payload[key] ?? '';
                    });
                    document.getElementById('placeFormId').value = payload.id || '';
                    document.getElementById('placeFormTitle').textContent = 'Editar lugar de servicio';
                    document.getElementById('placeFormEyebrow').textContent = 'Editar';
                    document.getElementById('placeFormSubtitle').textContent = 'Actualice la informacion del lugar.';
                    var turnosIds = payload.turnos_ids || [];
                    setTimeout(function(){ renderPlaceTurnos(Number(rutaSel.value), turnosIds); }, 0);
                    placeDialog.showModal();
                });
            });
        }
        // La tabla con los botones se renderiza DESPUÉS de este script: esperar el DOM completo.
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', attachPlaceEditHandlers);
        } else {
            attachPlaceEditHandlers();
        }

        // CSV Import for Asignaciones
        var asignCsvInput = document.getElementById('asign-csv-input');
        var asignCsvReplace = document.getElementById('asign-csv-replace');
        var asignDialog = document.getElementById('asignImportDialog');
        var asignBody = document.getElementById('asignImportBody');
        var asignSummary = document.getElementById('asignImportSummary');
        var asignConfirm = document.getElementById('asignImportConfirm');
        var asignTotal = document.getElementById('asignTotal');
        var asignValid = document.getElementById('asignValid');
        var asignErrors = document.getElementById('asignErrors');
        var asignPreviewData = [];

        function parseAsignCsv(text) {
            var lines = text.replace(//g, '').split('
').filter(function(l){ return l.trim(); });
            if (lines.length < 2) return [];
            var headers = lines[0].split(',').map(function(h){ return h.trim().replace(/^"|"$/g, ''); });
            var rows = [];
            for (var i = 1; i < lines.length; i++) {
                var vals = lines[i].split(',').map(function(v){ return v.trim().replace(/^"|"$/g, ''); });
                var obj = {};
                headers.forEach(function(h, idx){ obj[h] = vals[idx] || ''; });
                rows.push(obj);
            }
            return rows;
        }

        function loadAsignCsv(file) {
            var reader = new FileReader();
            reader.onload = function(e) {
                var rows = parseAsignCsv(e.target.result);
                if (!rows.length) { alert('Archivo CSV vacio o formato incorrecto.'); return; }
                fetch('/api/admin/movil-eas-asignaciones/importar-preview', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                    body: JSON.stringify({rows: rows})
                })
                .then(function(r){ return r.json(); })
                .then(function(d) {
                    if (d.ok !== true) { alert(d.mensaje || 'Error al validar'); return; }
                    var datos = d.datos;
                    asignPreviewData = datos.filas;
                    asignTotal.textContent = datos.total;
                    asignValid.textContent = datos.validos;
                    asignErrors.textContent = datos.rechazados;
                    asignSummary.hidden = false;
                    asignConfirm.disabled = false;
                    asignConfirm.textContent = datos.rechazados > 0
                        ? 'Importar validos (' + datos.validos + '/' + datos.total + ')'
                        : 'Confirmar importacion (' + datos.validos + ')';
                    asignBody.innerHTML = datos.filas.map(function(f) {
                        var cls = f.valido ? 'is-valid' : 'is-invalid';
                        var icon = f.valido ? '✓' : '✗';
                        return '<tr class="' + cls + '"><td>' + f.fila + '</td><td>' + esc(f.ruta) + '</td><td>' + esc(f.lugar) + '</td><td>' + esc(f.movil) + '</td><td>' + esc(f.placa) + '</td><td>' + esc(f.estado) + '</td><td><span class="route-import-status">' + icon + ' ' + esc(f.resultado) + '</span></td></tr>';
                    }).join('');
                    asignDialog.showModal();
                })
                .catch(function(err){ alert('Error: ' + err.message); });
            };
            reader.readAsText(file);
        }

        if (asignCsvInput) asignCsvInput.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });
        if (asignCsvReplace) asignCsvReplace.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });

        if (asignConfirm) asignConfirm.addEventListener('click', function() {
            var validRows = asignPreviewData.filter(function(f){ return f.valido; });
            if (!validRows.length) { alert('No hay registros validos para importar.'); return; }
            this.disabled = true;
            this.textContent = 'Importando...';
            var self = this;
            fetch('/api/admin/movil-eas-asignaciones/importar-confirm', {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                body: JSON.stringify({rows: validRows})
            })
            .then(function(r){ return r.json(); })
            .then(function(d) {
                if (d.ok !== true) { alert(d.mensaje || 'Error al importar'); self.disabled = false; self.textContent = 'Confirmar importacion'; return; }
                asignDialog.close();
                alert('Importacion completada.
' + d.datos.creados + ' asignaciones creadas.');
                location.reload();
            })
            .catch(function(err){ alert('Error: ' + err.message); self.disabled = false; self.textContent = 'Confirmar importacion'; });
        });

        document.querySelectorAll('[data-asign-close]').forEach(function(btn) {
            btn.addEventListener('click', function() { asignDialog.close(); });
        });

    })();
    </script>
    <?php endif; ?>
    <?php $placeRouteCircuits=[];$placeCircuits=[];foreach ($adminData['rutas'] as $route) { $circuitId=(int)($route['circuito_id'] ?? 0);$placeRouteCircuits[(int)$route['id']]=$circuitId ?: '' ;if ($circuitId) $placeCircuits[$circuitId]=$route['circuito']; } asort($placeCircuits, SORT_NATURAL | SORT_FLAG_CASE); ?>
    <div class="admin-filter-carousel-card">
    <section class="admin-filter-bar" aria-label="Filtros de lugares de servicio">
        <div class="admin-filter-bar-inner">
            <div class="admin-filter-group">
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg> Distrito</span>
                    <select data-table-filter="admin-places-table" data-filter-attribute="district"><option value="">Todos</option><?php foreach (($refs['distritos'] ?? []) as $district): ?><option value="<?= (int)$district['id'] ?>"><?= $e($district['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/></svg> Circuito</span>
                    <select data-table-filter="admin-places-table" data-filter-attribute="circuit"><option value="">Todos</option><option value="__empty__">Sin circuito</option><?php foreach ($placeCircuits as $circuitId=>$circuitName): ?><option value="<?= (int)$circuitId ?>"><?= $e($circuitName) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/></svg> Ruta</span>
                    <select data-table-filter="admin-places-table" data-filter-attribute="route"><option value="">Todas</option><?php foreach ($adminData['rutas'] as $route): ?><option value="<?= (int)$route['id'] ?>"><?= $e($route['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg> Turno</span>
                    <select data-table-filter="admin-places-table" data-filter-attribute="turno" data-filter-mode="contains"><option value="">Todos</option><?php foreach (($refs['turnos'] ?? []) as $turno): ?><option value="<?= (int)$turno['id'] ?>"><?= $e($turno['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="admin-filter-field admin-filter-field--search">
                    <span class="admin-filter-label"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg> Buscar lugar</span>
                    <input type="search" data-table-search="admin-places-table" placeholder="Nombre de lugar...">
                </label>
            </div>
            <div style="display:flex;gap:8px;align-items:center">
                <button type="button" class="admin-filter-clear" data-clear-table-filters="admin-places-table" title="Limpiar filtros"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg> Limpiar filtros</button>
                <?php if ($can('lugares_servicio.estado')): ?><button type="button" class="admin-icon-btn admin-icon-btn--delete" data-bulk-delete-places title="Eliminar lugares seleccionados"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg></button><?php endif; ?>
            </div>
        </div>
    </section>
    <div id="placesCarousel" class="rc-slider"></div>
    </div>
    <script src="/assets/js/admin-carousel.js"></script>
    <script>
    (function(){
        var routeCounts = {};
        <?= json_encode(array_map(function($l) { return $l['ruta_id']; }, $adminData['lugares'] ?? [])) ?>.forEach(function(rid){ routeCounts[rid] = (routeCounts[rid] || 0) + 1; });
        var routes = <?= json_encode(array_map(function($r){ return ['id'=>$r['id'],'nombre'=>$r['nombre']]; }, $adminData['rutas']), JSON_UNESCAPED_UNICODE) ?>.map(function(r){ return { nombre: r.nombre, lugares: routeCounts[r.id] || 0 }; });
        if (routes.length && typeof RandomRouteInfoSlider !== 'undefined') new RandomRouteInfoSlider(document.getElementById('placesCarousel'), { routes: routes, title: 'Lugares por ruta', subtitle: 'Resumen aleatorio' });

        // CSV Import for Asignaciones
        var asignCsvInput = document.getElementById('asign-csv-input');
        var asignCsvReplace = document.getElementById('asign-csv-replace');
        var asignDialog = document.getElementById('asignImportDialog');
        var asignBody = document.getElementById('asignImportBody');
        var asignSummary = document.getElementById('asignImportSummary');
        var asignConfirm = document.getElementById('asignImportConfirm');
        var asignTotal = document.getElementById('asignTotal');
        var asignValid = document.getElementById('asignValid');
        var asignErrors = document.getElementById('asignErrors');
        var asignPreviewData = [];

        function parseAsignCsv(text) {
            var lines = text.replace(//g, '').split('
').filter(function(l){ return l.trim(); });
            if (lines.length < 2) return [];
            var headers = lines[0].split(',').map(function(h){ return h.trim().replace(/^"|"$/g, ''); });
            var rows = [];
            for (var i = 1; i < lines.length; i++) {
                var vals = lines[i].split(',').map(function(v){ return v.trim().replace(/^"|"$/g, ''); });
                var obj = {};
                headers.forEach(function(h, idx){ obj[h] = vals[idx] || ''; });
                rows.push(obj);
            }
            return rows;
        }

        function loadAsignCsv(file) {
            var reader = new FileReader();
            reader.onload = function(e) {
                var rows = parseAsignCsv(e.target.result);
                if (!rows.length) { alert('Archivo CSV vacio o formato incorrecto.'); return; }
                fetch('/api/admin/movil-eas-asignaciones/importar-preview', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                    body: JSON.stringify({rows: rows})
                })
                .then(function(r){ return r.json(); })
                .then(function(d) {
                    if (d.ok !== true) { alert(d.mensaje || 'Error al validar'); return; }
                    var datos = d.datos;
                    asignPreviewData = datos.filas;
                    asignTotal.textContent = datos.total;
                    asignValid.textContent = datos.validos;
                    asignErrors.textContent = datos.rechazados;
                    asignSummary.hidden = false;
                    asignConfirm.disabled = false;
                    asignConfirm.textContent = datos.rechazados > 0
                        ? 'Importar validos (' + datos.validos + '/' + datos.total + ')'
                        : 'Confirmar importacion (' + datos.validos + ')';
                    asignBody.innerHTML = datos.filas.map(function(f) {
                        var cls = f.valido ? 'is-valid' : 'is-invalid';
                        var icon = f.valido ? '✓' : '✗';
                        return '<tr class="' + cls + '"><td>' + f.fila + '</td><td>' + esc(f.ruta) + '</td><td>' + esc(f.lugar) + '</td><td>' + esc(f.movil) + '</td><td>' + esc(f.placa) + '</td><td>' + esc(f.estado) + '</td><td><span class="route-import-status">' + icon + ' ' + esc(f.resultado) + '</span></td></tr>';
                    }).join('');
                    asignDialog.showModal();
                })
                .catch(function(err){ alert('Error: ' + err.message); });
            };
            reader.readAsText(file);
        }

        if (asignCsvInput) asignCsvInput.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });
        if (asignCsvReplace) asignCsvReplace.addEventListener('change', function(){ if(this.files[0]) loadAsignCsv(this.files[0]); this.value=''; });

        if (asignConfirm) asignConfirm.addEventListener('click', function() {
            var validRows = asignPreviewData.filter(function(f){ return f.valido; });
            if (!validRows.length) { alert('No hay registros validos para importar.'); return; }
            this.disabled = true;
            this.textContent = 'Importando...';
            var self = this;
            fetch('/api/admin/movil-eas-asignaciones/importar-confirm', {
                method: 'POST',
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (document.cookie.match(/token=([^;]+)/)||[])[1] || ''},
                body: JSON.stringify({rows: validRows})
            })
            .then(function(r){ return r.json(); })
            .then(function(d) {
                if (d.ok !== true) { alert(d.mensaje || 'Error al importar'); self.disabled = false; self.textContent = 'Confirmar importacion'; return; }
                asignDialog.close();
                alert('Importacion completada.
' + d.datos.creados + ' asignaciones creadas.');
                location.reload();
            })
            .catch(function(err){ alert('Error: ' + err.message); self.disabled = false; self.textContent = 'Confirmar importacion'; });
        });

        document.querySelectorAll('[data-asign-close]').forEach(function(btn) {
            btn.addEventListener('click', function() { asignDialog.close(); });
        });

    })();
    </script>
    <section class="table-wrap"><table id="admin-places-table" data-search-cols="0,1,2"><thead><tr><th>Lugar</th><th>Distrito / Ruta</th><th>Servicio</th><th>Requeridos</th><th>Estado</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['lugares'] as $item): $payload=['id'=>$item['id'],'nombre'=>$item['nombre'],'direccion'=>$item['direccion'],'ubicacion_especifica'=>$item['ubicacion_especifica'],'distrito_id'=>$item['distrito_id'],'ruta_id'=>$item['ruta_id'],'tipo_servicio_id'=>$item['tipo_servicio_id'],'turnos_ids'=>array_map('intval',array_column($item['turnos'] ?? [],'turno_id')),'cantidad_requerida'=>$item['cantidad_requerida'],'estado_operativo'=>$item['estado_operativo'],'consignas'=>$item['consignas'],'observacion'=>$item['observacion'],'lugar_formacion'=>$item['lugar_formacion'],'latitud'=>$item['latitud'],'longitud'=>$item['longitud'],'activo'=>(bool)$item['activo']]; ?><tr data-district="<?= (int)($item['distrito_id'] ?? 0) ?>" data-route="<?= (int)($item['ruta_id'] ?? 0) ?>" data-circuit="<?= $e($placeRouteCircuits[(int)($item['ruta_id'] ?? 0)] ?? '') ?>" data-place="<?= $e($item['nombre'] ?: $item['direccion']) ?>" data-turno="<?= $e(implode(',', array_column($item['turnos'] ?? [], 'turno_id'))) ?>"><td><strong><?= $e($item['nombre'] ?: $item['direccion']) ?></strong><small><?= $e($item['direccion']) ?></small></td><td><?= $e(($item['distrito'] ?? '—').' / '.($item['ruta'] ?? '—')) ?><?php if ($item['ruta_asignar_encargado']): ?><small class="status-pill is-active">Esta ruta permite asignar encargado</small><?php endif; ?></td><td><?= $e($item['tipo_servicio'] ?? '—') ?></td><td><?= (int)$item['cantidad_requerida'] ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $e($item['estado_operativo']) ?></span></td><td class="actions admin-place-actions"><?php if ($can('lugares_servicio.editar')): ?><button type="button" class="admin-place-action admin-place-action-edit" data-edit-service-place data-payload="<?= $json($payload) ?>" title="Editar" aria-label="Editar lugar de servicio"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"/></svg></button><?php endif; ?><?php if ($can('lugares_servicio.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="lugar"><input type="hidden" name="tab" value="lugares"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="admin-place-action admin-place-action-delete" title="Eliminar" aria-label="Eliminar lugar de servicio"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v5M14 11v5"/></svg></button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
    <?php if ($can('lugares_servicio.estado')): ?><dialog class="admin-bulk-delete-dialog" id="bulkDeletePlacesDialog" aria-labelledby="bulk-delete-places-title"><form method="post" action="/admin/lugares-servicio/eliminar-por-alcance"><input type="hidden" name="ruta_id"><input type="hidden" name="circuito_id"><header><div><span class="eyebrow">Confirmar eliminación</span><h3 id="bulk-delete-places-title">Eliminar lugares de servicio</h3></div><button type="button" aria-label="Cerrar" data-bulk-delete-close>&times;</button></header><div class="admin-bulk-delete-body"><p>Se eliminarán <strong data-bulk-delete-count>0</strong> lugar(es) de <strong data-bulk-delete-scope>la selección</strong>, junto con sus registros relacionados.</p><p class="admin-bulk-delete-warning">Esta acción no se puede deshacer.</p></div><footer><button type="button" class="secondary" data-bulk-delete-close>Cancelar</button><button type="submit" class="danger" data-bulk-delete-confirm>Eliminar lugares</button></footer></form></dialog><?php endif; ?>
    <?php endif; ?>

    <?php if ($tab === 'mantenimiento' && $can('moviles.ver')): ?>
    <header class="admin-section-heading"><div><h2>Mantenimiento de móviles</h2><p>Historial técnico y actualización del kilometraje de mantenimiento.</p></div><span><?= count($adminData['mantenimientos']) ?> registros</span></header>
    <?php if ($can('moviles.editar')): ?><form class="form-panel admin-form" method="post" action="/admin"><input type="hidden" name="entity" value="mantenimiento"><input type="hidden" name="tab" value="mantenimiento"><div class="admin-form-title"><h3>Registrar mantenimiento</h3></div><div class="form-grid"><label>Móvil<select name="movil_id" required><?php foreach ($adminData['moviles'] as $m): ?><option value="<?= (int)$m['id'] ?>"><?= $e($m['numero_movil'].' · '.($m['placa'] ?: 'Sin placa')) ?></option><?php endforeach; ?></select></label><label>Fecha<input type="datetime-local" name="fecha_mantenimiento" required value="<?= date('Y-m-d\TH:i') ?>"></label><label>Kilometraje<input type="number" min="0" name="kilometraje" required></label><label>Tipo<select name="tipo_mantenimiento_id"><?php $optionList($refs['tiposMantenimiento'] ?? []); ?></select></label><label class="span-2">Descripción<textarea name="descripcion" required rows="2"></textarea></label></div><button type="submit">Registrar mantenimiento</button></form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Fecha</th><th>Móvil</th><th>Tipo</th><th>Kilometraje</th><th>Descripción</th><th>Estado</th></tr></thead><tbody><?php foreach ($adminData['mantenimientos'] as $item): ?><tr><td><?= $e(substr((string)$item['fecha_mantenimiento'],0,16)) ?></td><td><strong><?= $e($item['numero_movil']) ?></strong></td><td><?= $e($item['tipo_mantenimiento'] ?? '—') ?></td><td><?= number_format((int)$item['kilometraje'],0,',','.') ?> km</td><td><?= $e($item['descripcion'] ?: '—') ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $item['activo'] ? 'Vigente' : 'Anulado' ?></span></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>
</section>
