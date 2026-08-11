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
    <form class="form-panel admin-form" method="post" action="/admin" id="form-asignacion"><input type="hidden" name="entity" value="asignacion"><input type="hidden" name="tab" value="asignaciones"><input type="hidden" name="id"><div class="admin-form-title"><h3>Nueva asignación</h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div><div class="form-grid"><label>EAS<select name="eas_id" required><?php $optionList($adminData['eas']); ?></select></label><label>Móvil<select name="movil_id" required><?php foreach ($adminData['moviles'] as $m): ?><option value="<?= (int)$m['id'] ?>"><?= $e($m['numero_movil'] . ($m['placa'] ? ' · '.$m['placa'] : '')) ?></option><?php endforeach; ?></select></label><label>Estado<select name="estado_asignacion_id" required><?php $optionList($refs['estadosAsignacion'] ?? []); ?></select></label><label class="span-2">Observación<textarea name="observacion" rows="2"></textarea></label><label class="check-row"><input type="checkbox" name="activo" checked> Vigente</label></div><button type="submit">Guardar asignación</button></form>
    <section class="table-wrap"><table><thead><tr><th>Fecha</th><th>EAS</th><th>Móvil</th><th>Placa</th><th>Estado</th><th>Observación</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['asignaciones'] as $item): $payload=['id'=>$item['id'],'eas_id'=>$item['eas_id'],'movil_id'=>$item['movil_id'],'estado_asignacion_id'=>$item['estado_asignacion_id'],'observacion'=>$item['observacion'],'activo'=>(bool)$item['activo']]; ?><tr><td><?= $e(substr((string)$item['fecha_asignacion'],0,16)) ?></td><td><?= $e($item['eas_codigo'].' · '.$item['eas_nombre']) ?></td><td><strong><?= $e($item['numero_movil']) ?></strong></td><td><?= $e($item['placa'] ?: '—') ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $e($item['estado_asignacion']) ?></span></td><td><?= $e($item['observacion'] ?: '—') ?></td><td class="actions"><button type="button" class="secondary" data-edit-target="#form-asignacion" data-payload="<?= $json($payload) ?>">Editar</button><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="asignacion"><input type="hidden" name="tab" value="asignaciones"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Cerrar</button></form></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'rutas' && $can('rutas.ver')): ?>
    <header class="admin-section-heading"><div><h2>Rutas operativas</h2><p>Distrito, turno y franja horaria relacionada.</p></div><span><?= count($adminData['rutas']) ?> rutas</span></header>
    <?php if ($can('catalogos.crear') || $can('catalogos.editar')): ?><form class="form-panel admin-form" method="post" action="/admin" id="form-ruta"><input type="hidden" name="entity" value="ruta"><input type="hidden" name="tab" value="rutas"><input type="hidden" name="id"><div class="admin-form-title"><h3>Nueva ruta</h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div><div class="form-grid"><label>Nombre<input name="nombre" required></label><label>Distrito<select name="distrito_id"><?php $optionList($refs['distritos'] ?? []); ?></select></label><label>Turno<select name="turno_id"><?php $optionList($refs['turnos'] ?? []); ?></select></label><label>Hora inicio<input type="time" name="hora_inicio"></label><label>Hora fin<input type="time" name="hora_fin"></label><label class="check-row"><input type="checkbox" name="asignar_encargado"> Asignar encargado</label><label class="check-row"><input type="checkbox" name="activo" checked> Activa</label></div><button type="submit">Guardar ruta</button></form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Ruta</th><th>Distrito</th><th>Turno</th><th>Horario</th><th>Encargado</th><th>Estado</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['rutas'] as $item): $payload=['id'=>$item['id'],'nombre'=>$item['nombre'],'distrito_id'=>$item['distrito_id'],'turno_id'=>$item['turno_id'],'hora_inicio'=>$item['hora_inicio'],'hora_fin'=>$item['hora_fin'],'asignar_encargado'=>(bool)$item['asignar_encargado'],'activo'=>(bool)$item['activo']]; ?><tr><td><strong><?= $e($item['nombre']) ?></strong></td><td><?= $e($item['distrito'] ?? '—') ?></td><td><?= $e($item['turno'] ?? '—') ?></td><td><?= $e(($item['hora_inicio'] ?? '—').' – '.($item['hora_fin'] ?? '—')) ?></td><td><span class="status-pill <?= $item['asignar_encargado'] ? 'is-active' : '' ?>"><?= $item['asignar_encargado'] ? 'Permitido' : 'No requerido' ?></span></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $item['activo'] ? 'Activa' : 'Inactiva' ?></span></td><td class="actions"><?php if ($can('catalogos.editar')): ?><button type="button" class="secondary" data-edit-target="#form-ruta" data-payload="<?= $json($payload) ?>">Editar</button><?php endif; ?><?php if ($can('catalogos.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="ruta"><input type="hidden" name="tab" value="rutas"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Eliminar</button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
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
    <header class="admin-section-heading"><div><h2>Lugares de servicio</h2><p>Información operativa y geográfica de los puntos institucionales.</p></div><div class="admin-service-place-actions"><span><?= count($adminData['lugares']) ?> lugares</span><a class="admin-import-button" href="/admin/lugares-servicio/plantilla.csv">Descargar plantilla CSV</a><?php if ($can('lugares_servicio.crear')): ?><form method="post" action="/admin/lugares-servicio/importar" enctype="multipart/form-data"><input type="hidden" name="import_action" value="preview"><label class="admin-import-button" for="service-place-csv">Importar CSV</label><input id="service-place-csv" name="archivo_csv" type="file" accept=".csv,text/csv" hidden required onchange="this.form.submit()"></form><?php endif; ?></div></header>
    <?php if (!empty($importPreview)): ?>
    <section class="admin-import-preview" aria-labelledby="csv-preview-title">
        <header><div><span class="eyebrow">Validación previa</span><h3 id="csv-preview-title">Vista previa de importación</h3><p>Revise los resultados. Al confirmar se guardarán únicamente las filas válidas.</p></div><div class="admin-import-summary"><span class="is-valid"><?= (int)($importPreview['validos'] ?? 0) ?> válidos</span><span class="is-invalid"><?= (int)($importPreview['rechazados'] ?? 0) ?> rechazados</span></div></header>
        <div class="table-wrap"><table><thead><tr><th>Fila</th><th>Distrito</th><th>Ruta</th><th>Tipo</th><th>Cant.</th><th>Lugar de servicio</th><th>Consignas</th><th>Observación</th><th>Lugar de formación</th><th>Resultado</th></tr></thead><tbody>
        <?php foreach (($importPreview['filas'] ?? []) as $row): ?><tr class="<?= !empty($row['valida']) ? 'csv-row-valid' : 'csv-row-invalid' ?>"><td><?= (int)($row['fila'] ?? 0) ?></td><td><?= $e($row['distrito'] ?? '') ?></td><td><?= $e($row['ruta'] ?? '') ?></td><td><?= $e($row['tipo_servicio'] ?? '') ?></td><td><?= $e($row['cantidad_requerida'] ?? '') ?></td><td><strong><?= $e($row['nombre_lugar_servicio'] ?? '') ?></strong></td><td><?= $e($row['consignas'] ?? '') ?></td><td><?= $e($row['observacion'] ?? '') ?></td><td><?= $e($row['lugar_formacion'] ?? '') ?></td><td><?php if (!empty($row['valida'])): ?><span class="status-pill is-active">Válida</span><?php else: ?><span class="status-pill csv-error-pill">Inválida</span><ul class="csv-errors"><?php foreach (($row['errores'] ?? []) as $reason): ?><li><?= $e($reason) ?></li><?php endforeach; ?></ul><?php endif; ?></td></tr><?php endforeach; ?>
        </tbody></table></div>
        <footer><a class="admin-import-cancel" href="/admin?tab=lugares">Cancelar</a><?php if ((int)($importPreview['validos'] ?? 0) > 0): ?><form method="post" action="/admin/lugares-servicio/importar"><input type="hidden" name="import_action" value="confirm"><input type="hidden" name="import_token" value="<?= $e($importPreview['token'] ?? '') ?>"><button type="submit">Confirmar e importar <?= (int)$importPreview['validos'] ?> registro(s)</button></form><?php endif; ?></footer>
    </section>
    <?php endif; ?>
    <?php if ($can('lugares_servicio.crear') || $can('lugares_servicio.editar')): ?>
    <form class="form-panel admin-form" method="post" action="/admin" id="form-lugar">
        <input type="hidden" name="entity" value="lugar">
        <input type="hidden" name="tab" value="lugares">
        <input type="hidden" name="id">
        <div class="admin-form-title"><h3>Nuevo lugar</h3><button type="reset" class="secondary" data-admin-reset>Limpiar</button></div>
        <div class="form-grid">
            <label>Distrito<select name="distrito_id" id="lugar-distrito" required><?php $optionList($refs['distritos'] ?? []); ?></select></label>
            <label>Ruta<select name="ruta_id" id="lugar-ruta" required>
                <option value="">Seleccione</option>
                <?php foreach ($adminData['rutas'] as $r): ?><option value="<?= (int)$r['id'] ?>" data-distrito="<?= (int)($r['distrito_id'] ?? 0) ?>"><?= $e($r['nombre']) ?></option><?php endforeach; ?>
            </select></label>
            <label>Tipo de servicio<select name="tipo_servicio_id"><?php $optionList($refs['tiposServicio'] ?? []); ?></select></label>
            <label>Cantidad requerida<input type="number" name="cantidad_requerida" id="lugar-cantidad" min="1" value="1"></label>
        </div>
        <div id="lugares-list" class="form-grid" style="margin-top:1rem">
            <label class="span-2">Nombre del lugar de servicio
                <div style="display:flex;gap:0.5rem;align-items:center">
                    <input type="text" name="nombre[]" placeholder="Ingrese el nombre" required style="flex:1">
                    <button type="button" class="remove-lugar danger" style="padding:0.4rem 0.6rem;line-height:1" title="Quitar">&times;</button>
                </div>
            </label>
        </div>
        <button type="button" id="add-lugar" class="secondary" style="margin-bottom:1rem">+ Agregar otro lugar de servicio</button>
        <div class="form-grid">
            <label class="span-2">Consignas<textarea name="consignas" rows="2"></textarea></label>
            <label class="span-2">Observación<textarea name="observacion" rows="2"></textarea></label>
            <label class="span-2">Lugar de Formación<textarea name="lugar_formacion" rows="2"></textarea></label>
        </div>
        <button type="submit">Guardar lugares</button>
    </form>
    <script>
    (function(){
        var distritoSel = document.getElementById('lugar-distrito');
        var rutaSel = document.getElementById('lugar-ruta');
        var todasRutas = Array.from(rutaSel.options).filter(function(o){ return o.value !== ''; });

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
        });

        rutaSel.addEventListener('change', function(){});

        document.getElementById('add-lugar').addEventListener('click', function(){
            var list = document.getElementById('lugares-list');
            var label = document.createElement('label');
            label.className = 'span-2 lugar-row';
            label.innerHTML = 'Nombre del lugar de servicio <div style="display:flex;gap:0.5rem;align-items:center"><input type="text" name="nombre[]" placeholder="Ingrese el nombre" required style="flex:1"><button type="button" class="remove-lugar danger" style="padding:0.4rem 0.6rem;line-height:1" title="Quitar">&times;</button></div>';
            list.appendChild(label);
        });

        document.getElementById('lugares-list').addEventListener('click', function(e){
            if(e.target.classList.contains('remove-lugar')){
                var rows = document.querySelectorAll('.lugar-row');
                if(rows.length > 1) e.target.closest('.lugar-row').remove();
            }
        });
    })();
    </script>
    <?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Lugar</th><th>Distrito / Ruta</th><th>Servicio</th><th>Requeridos</th><th>Estado</th><th>Acciones</th></tr></thead><tbody><?php foreach ($adminData['lugares'] as $item): $payload=['id'=>$item['id'],'nombre'=>$item['nombre'],'direccion'=>$item['direccion'],'ubicacion_especifica'=>$item['ubicacion_especifica'],'distrito_id'=>$item['distrito_id'],'ruta_id'=>$item['ruta_id'],'tipo_servicio_id'=>$item['tipo_servicio_id'],'turno_id'=>$item['turno_id'],'cantidad_requerida'=>$item['cantidad_requerida'],'estado_operativo'=>$item['estado_operativo'],'consignas'=>$item['consignas'],'observacion'=>$item['observacion'],'lugar_formacion'=>$item['lugar_formacion'],'latitud'=>$item['latitud'],'longitud'=>$item['longitud'],'activo'=>(bool)$item['activo']]; ?><tr><td><strong><?= $e($item['nombre'] ?: $item['direccion']) ?></strong><small><?= $e($item['direccion']) ?></small></td><td><?= $e(($item['distrito'] ?? '—').' / '.($item['ruta'] ?? '—')) ?><?php if ($item['ruta_asignar_encargado']): ?><small class="status-pill is-active">Esta ruta permite asignar encargado</small><?php endif; ?></td><td><?= $e($item['tipo_servicio'] ?? '—') ?></td><td><?= (int)$item['cantidad_requerida'] ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $e($item['estado_operativo']) ?></span></td><td class="actions"><?php if ($can('lugares_servicio.editar')): ?><button type="button" class="secondary" data-edit-target="#form-lugar" data-payload="<?= $json($payload) ?>">Editar</button><?php endif; ?><?php if ($can('lugares_servicio.estado')): ?><form method="post" action="/admin/eliminar" class="inline-form"><input type="hidden" name="entity" value="lugar"><input type="hidden" name="tab" value="lugares"><input type="hidden" name="id" value="<?= (int)$item['id'] ?>"><button class="danger">Eliminar</button></form><?php endif; ?></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>

    <?php if ($tab === 'mantenimiento' && $can('moviles.ver')): ?>
    <header class="admin-section-heading"><div><h2>Mantenimiento de móviles</h2><p>Historial técnico y actualización del kilometraje de mantenimiento.</p></div><span><?= count($adminData['mantenimientos']) ?> registros</span></header>
    <?php if ($can('moviles.editar')): ?><form class="form-panel admin-form" method="post" action="/admin"><input type="hidden" name="entity" value="mantenimiento"><input type="hidden" name="tab" value="mantenimiento"><div class="admin-form-title"><h3>Registrar mantenimiento</h3></div><div class="form-grid"><label>Móvil<select name="movil_id" required><?php foreach ($adminData['moviles'] as $m): ?><option value="<?= (int)$m['id'] ?>"><?= $e($m['numero_movil'].' · '.($m['placa'] ?: 'Sin placa')) ?></option><?php endforeach; ?></select></label><label>Fecha<input type="datetime-local" name="fecha_mantenimiento" required value="<?= date('Y-m-d\TH:i') ?>"></label><label>Kilometraje<input type="number" min="0" name="kilometraje" required></label><label>Tipo<select name="tipo_mantenimiento_id"><?php $optionList($refs['tiposMantenimiento'] ?? []); ?></select></label><label class="span-2">Descripción<textarea name="descripcion" required rows="2"></textarea></label></div><button type="submit">Registrar mantenimiento</button></form><?php endif; ?>
    <section class="table-wrap"><table><thead><tr><th>Fecha</th><th>Móvil</th><th>Tipo</th><th>Kilometraje</th><th>Descripción</th><th>Estado</th></tr></thead><tbody><?php foreach ($adminData['mantenimientos'] as $item): ?><tr><td><?= $e(substr((string)$item['fecha_mantenimiento'],0,16)) ?></td><td><strong><?= $e($item['numero_movil']) ?></strong></td><td><?= $e($item['tipo_mantenimiento'] ?? '—') ?></td><td><?= number_format((int)$item['kilometraje'],0,',','.') ?> km</td><td><?= $e($item['descripcion'] ?: '—') ?></td><td><span class="status-pill <?= $item['activo'] ? 'is-active' : '' ?>"><?= $item['activo'] ? 'Vigente' : 'Anulado' ?></span></td></tr><?php endforeach; ?></tbody></table></section>
    <?php endif; ?>
</section>
