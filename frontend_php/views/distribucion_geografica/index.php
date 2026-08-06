<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$canCreate = in_array('distribucion.crear', $permissions, true);
$canEdit = in_array('distribucion.editar', $permissions, true);
$canAssign = in_array('distribucion.asignar', $permissions, true);
$canCatalogs = in_array('distribucion.catalogos', $permissions, true);
$initials = strtoupper(substr((string)($usuario['nombres'] ?? 'U'), 0, 1) . substr((string)($usuario['apellidos'] ?? ''), 0, 1));
?>
<div class="geo-app" data-can-create="<?= $canCreate ? '1' : '0' ?>" data-can-edit="<?= $canEdit ? '1' : '0' ?>" data-can-assign="<?= $canAssign ? '1' : '0' ?>" data-can-catalogs="<?= $canCatalogs ? '1' : '0' ?>">
    <aside class="geo-sidebar" aria-label="Navegación principal">
        <a class="geo-brand" href="/dashboard" aria-label="SIGO inicio">
            <span class="geo-brand-shield">S</span>
            <span><strong>SIGO</strong><small>Sistema Integral de<br>Gestión Operativa</small></span>
        </a>
        <nav class="geo-nav">
            <a href="/dashboard"><span>⌂</span> Dashboard</a>
            <a href="/eventos"><span>▣</span> Eventos</a>
            <a href="#"><span>◇</span> Novedades <b>⌄</b></a>
            <a href="/personal"><span>♙</span> Personal <b>⌄</b></a>
            <a href="#"><span>▤</span> Servicios <b>⌄</b></a>
            <section class="geo-nav-group is-open">
                <div><span>▧</span> Distribución <b>⌃</b></div>
                <a class="is-active" href="/distribucion-geografica">Distribución geográfica</a>
                <a href="/distribucion-tablero">Tablero de distribución</a>
            </section>
            <a href="#"><span>✥</span> Comunicación <b>›</b></a>
            <a href="#"><span>▥</span> Reportes <b>›</b></a>
            <a href="/admin"><span>▦</span> Catálogos <b>›</b></a>
            <a href="/configuracion"><span>⚙</span> Configuración <b>›</b></a>
        </nav>
        <div class="geo-sidebar-footer"><span class="geo-footer-shield">S</span><span><strong>SEGURA EP</strong><small>Lealtad, Valor y Orden</small></span></div>
    </aside>

    <div class="geo-content">
        <header class="geo-header">
            <button class="geo-menu-toggle" type="button" id="geoMenuToggle" aria-label="Abrir menú">☰</button>
            <div class="geo-title"><h1>DISTRIBUCIÓN GEOGRÁFICA</h1><p>Personal asignado por puntos de servicio</p></div>
            <?php if ($canCreate): ?>
                <button class="geo-primary geo-create-header" type="button" data-open-wizard>＋ Crear punto georreferenciado</button>
            <?php endif; ?>
            <div class="geo-user"><span class="geo-bell">♧<b>8</b></span><span><strong><?= $esc($usuario['nombreCompleto'] ?? 'Usuario SIGO') ?></strong><small>Rol: <?= $esc($usuario['rolNombre'] ?? $usuario['rol'] ?? '') ?></small></span><i><?= $esc($initials ?: 'U') ?></i></div>
        </header>

        <main class="geo-main">
            <?php if (!empty($error)): ?><div class="geo-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>
            <?php if ($canCreate): ?><div class="geo-page-actions"><button class="geo-primary" type="button" data-open-wizard>＋ Crear punto georreferenciado</button></div><?php endif; ?>
            <button class="geo-filter-toggle" type="button" id="geoFilterToggle">☷ Mostrar filtros</button>
            <form class="geo-filters" id="geoFilters">
                <label>Distrito<select name="distrito_id" id="filterDistrict"><option value="">Todos los distritos</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
                <label>Ruta<select name="ruta_id" id="filterRoute" disabled><option value="">Todas las rutas</option></select></label>
                <label>Turno<select name="turno_id"><option value="">Todos los turnos</option><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?> (<?= $esc(substr((string)$item['hora_inicio'], 0, 5)) ?> - <?= $esc(substr((string)$item['hora_fin'], 0, 5)) ?>)</option><?php endforeach; ?></select></label>
                <label>Estado<select name="estado"><option value="">Todos</option><option value="CUBIERTO">Punto cubierto</option><option value="SIN_ASIGNACION">Sin asignación</option><option value="FUERA_TURNO">Fuera de turno</option><option value="INACTIVO">Inactivo</option><option value="NOVEDAD">Con novedad</option></select></label>
                <label>Buscar agente<input name="agente" type="search" placeholder="Nombre, cédula o código"></label>
                <div class="geo-filter-actions"><button class="geo-primary" type="submit">Aplicar filtros</button><button class="geo-secondary" type="reset">↻ Limpiar filtros</button></div>
            </form>

            <section class="geo-workspace">
                <div class="geo-map-wrap">
                    <div id="geoMap" aria-label="Mapa de puntos de servicio"></div>
                    <div class="geo-map-tools"><span><b id="visiblePointCount">0</b> puntos visibles</span><button type="button" id="centerGeoMap" title="Centrar mapa">⌖</button><button type="button" id="fullscreenGeoMap" title="Pantalla completa">⛶</button></div>
                    <div class="geo-legend"><strong>Leyenda de estados</strong><span><i class="covered"></i> Punto cubierto</span><span><i class="unassigned"></i> Sin asignación</span><span><i class="offshift"></i> Fuera de turno</span><span><i class="incident"></i> Novedad / incidencia</span><span><i class="selected"></i> Punto seleccionado</span></div>
                    <div class="geo-map-empty" id="geoMapEmpty" hidden>No hay puntos georreferenciados para los filtros seleccionados.</div>
                </div>
                <aside class="geo-detail" id="geoDetail" aria-live="polite">
                    <header><h2>Información del punto</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header>
                    <div class="geo-detail-empty"><span>⌖</span><strong>Seleccione un punto en el mapa</strong><p>Aquí verá su ubicación, horario y personal asignado.</p></div>
                </aside>
            </section>

            <section class="geo-stats" aria-label="Resumen de distribución">
                <article><i class="purple">⌖</i><span>Puntos registrados<strong id="statRegistered">0</strong></span></article>
                <article><i class="green">♙</i><span>Puntos cubiertos<strong id="statCovered">0</strong></span></article>
                <article><i class="gray">●</i><span>Sin asignación<strong id="statUnassigned">0</strong></span></article>
                <article><i class="blue">♙</i><span>Personal asignado<strong id="statPersonnel">0</strong></span></article>
                <article><i class="blue">▧</i><span>Rutas activas<strong id="statRoutes">0</strong></span></article>
            </section>
        </main>
    </div>

    <div class="geo-toast" id="geoToast" role="status" aria-live="polite"></div>

    <?php if ($canCreate || $canEdit || $canAssign): ?>
    <div class="geo-modal" id="pointWizard" hidden>
        <div class="geo-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="wizardTitle">
            <header class="geo-modal-header"><div><p id="wizardEyebrow">Nuevo punto de servicio</p><h2 id="wizardTitle">Crear punto georreferenciado</h2></div><button type="button" data-close-wizard aria-label="Cerrar">×</button></header>
            <ol class="geo-steps" id="wizardSteps"><li class="is-active"><b>1</b><span>Selección</span></li><li><b>2</b><span>Personal</span></li><li><b>3</b><span>Confirmación</span></li></ol>
            <form id="pointForm" novalidate>
                <input type="hidden" name="point_id">
                <section class="geo-step-panel is-active" data-step="1">
                    <div class="geo-step-heading"><div><h3>Seleccione el punto de servicio</h3><p>Distrito, ruta y lugar de servicio. Los datos se completarán automáticamente.</p></div></div>
                    <div class="geo-form-grid">
                        <label>Distrito<select name="distrito_id" id="formDistrict" required><option value="">Seleccione</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
                        <label>Ruta<select name="ruta_id" id="formRoute" required disabled><option value="">Seleccione un distrito</option></select></label>
                        <label>Lugar de servicio<select name="lugar_servicio_id" id="formServicePlace" required disabled><option value="">Seleccione una ruta</option></select></label>
                    </div>
                    <div class="geo-form-grid" id="autoFilledFields" hidden>
                        <label>Nombre del punto<input name="nombre" id="formNombre" maxlength="180" readonly class="geo-readonly"></label>
                        <label>Ubicación específica<input name="ubicacion_especifica" id="formUbicacion" maxlength="220" readonly class="geo-readonly"></label>
                        <label>Dirección<textarea name="direccion" id="formDireccion" rows="2" readonly class="geo-readonly"></textarea></label>
                        <label>Tipo de servicio<input name="tipo_servicio_id" id="formTipoServicio" readonly class="geo-readonly"></label>
                        <label>Turno<input name="turno_id" id="formTurno" readonly class="geo-readonly"></label>
                        <label>Hora de inicio<input name="hora_inicio" id="formHoraInicio" type="time" readonly class="geo-readonly"></label><label>Hora de finalización<input name="hora_fin" id="formHoraFin" type="time" readonly class="geo-readonly"></label>
                        <label>Cantidad requerida de agentes<input name="cantidad_requerida" id="formCantidad" type="number" min="1" max="100" readonly class="geo-readonly"></label>
                    </div>
                    <div class="geo-location-grid" id="mapSection" hidden><div id="wizardMap" aria-label="Mapa para seleccionar coordenadas"></div><div class="geo-location-fields"><label>Latitud<input name="latitud" id="formLatitud" inputmode="decimal" placeholder="-2.189875" required></label><label>Longitud<input name="longitud" id="formLongitud" inputmode="decimal" placeholder="-79.884521" required></label><button class="geo-secondary" id="locateCoordinates" type="button">⌖ Ubicar en el mapa</button></div></div>
                    <input type="hidden" name="tipo_servicio_id_hidden" id="formTipoServicioId">
                    <input type="hidden" name="turno_id_hidden" id="formTurnoId">
                    <input type="hidden" name="estado" value="SIN_ASIGNACION">
                    <input type="hidden" name="observaciones" value="">
                </section>
                <section class="geo-step-panel" data-step="2">
                    <div class="geo-step-heading"><div><h3>Asignación de personal</h3><p>Busque y agregue uno o varios agentes. También puede registrar el punto sin cobertura.</p></div></div>
                    <div class="geo-agent-search"><label>Buscar agente<input id="agentSearch" type="search" placeholder="Nombres, apellidos, cédula o código institucional"></label><div id="agentResults" class="geo-agent-results"></div></div>
                    <div class="geo-assignment-editor" id="assignmentEditor" hidden>
                        <div class="geo-selected-agent" id="selectedAgent"></div>
                        <div class="geo-form-grid compact"><label>Tipo de asignación<select id="assignType"><option value="FIJA">Fija</option><option value="TEMPORAL">Temporal</option><option value="RELEVO">Relevo</option></select></label><label>Fecha de inicio<input id="assignStartDate" type="date"></label><label>Fecha de finalización<input id="assignEndDate" type="date"></label><label>Turno<select id="assignShift"><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label><label>Hora de inicio<input id="assignStartTime" type="time"></label><label>Hora de finalización<input id="assignEndTime" type="time"></label><label>Función en el punto<input id="assignRole" placeholder="Ej. Vigilancia pedestre"></label><label>Observaciones<input id="assignNotes"></label></div>
                        <button class="geo-primary geo-add-agent" id="addAgent" type="button">＋ Agregar agente</button>
                    </div>
                    <div class="geo-assignment-table"><table><thead><tr><th>Agente</th><th>Código</th><th>Turno</th><th>Función</th><th>Estado</th><th>Acción</th></tr></thead><tbody id="assignmentRows"><tr class="empty"><td colspan="6">Aún no se ha agregado personal.</td></tr></tbody></table></div>
                </section>
                <section class="geo-step-panel" data-step="3"><div class="geo-step-heading"><div><h3>Resumen del punto georreferenciado</h3><p>Revise la información antes de guardar.</p></div></div><div class="geo-confirm-grid"><dl id="pointSummary"></dl><div id="previewMap" aria-label="Vista previa del punto"></div></div></section>
                <footer class="geo-modal-footer"><button class="geo-ghost" id="cancelWizard" type="button">Cancelar</button><button class="geo-secondary" id="prevStep" type="button" hidden>← Volver</button><button class="geo-primary" id="nextStep" type="button">Continuar →</button><button class="geo-primary" id="savePoint" type="submit" hidden>Guardar punto georreferenciado</button></footer>
            </form>
        </div>
    </div>
    <?php endif; ?>

    <script id="geoCatalogs" type="application/json"><?= json_encode($catalogos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?></script>
</div>
