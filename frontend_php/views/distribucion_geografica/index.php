<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canCreate = $isAdmin || in_array('distribucion.crear', $permissions, true);
$canEdit = $isAdmin || in_array('distribucion.editar', $permissions, true);
$canAssign = $isAdmin || in_array('distribucion.asignar', $permissions, true);
$canTrace = $isAdmin || in_array('rutas_geograficas.gestionar', $permissions, true);
?>
<div class="geo-app" data-can-create="<?= $canCreate ? '1' : '0' ?>" data-can-edit="<?= $canEdit ? '1' : '0' ?>" data-can-assign="<?= $canAssign ? '1' : '0' ?>" data-can-trace="<?= $canTrace ? '1' : '0' ?>">
    <main class="geo-main">
        <?php if (!empty($error)): ?><div class="geo-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

        <button class="geo-filter-toggle" type="button" id="geoFilterToggle">☷ Mostrar filtros</button>
        <form class="geo-filters" id="geoFilters">
            <label>Distrito<select name="distrito_id" id="filterDistrict" required><option value="">Seleccione un distrito</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Circuito<select name="circuito_id" id="filterCircuito" disabled><option value="">Seleccione un distrito primero</option></select></label>
            <label>Ruta<select name="ruta_id" id="filterRoute" disabled><option value="">Seleccione un circuito primero</option></select></label>
            <label>Turno<select name="turno_id" id="filterShift"><option value="">Todos los turnos</option><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Fecha distribución<input type="date" id="filterDate" value="<?= date('Y-m-d') ?>"></label>
            <div class="geo-service-group">
                <div class="geo-service-filter geo-service-filter--layers" id="geoLayerFilter">
                    <span class="geo-filter-label">Visualización de trazado</span>
                    <button class="geo-service-toggle" type="button" id="geoLayerToggle" aria-expanded="false">
                        <svg class="geo-control-icon" aria-hidden="true" viewBox="0 0 24 24"><path d="m12 3 9 5-9 5-9-5 9-5Zm-7.5 9L12 16.2l7.5-4.2M4.5 16 12 20.2l7.5-4.2"/></svg>
                        <span class="geo-toggle-label">0 capas visibles</span><span class="geo-chevron" aria-hidden="true">▾</span>
                    </button>
                <div class="geo-service-menu" id="geoLayerMenu" hidden><div class="geo-service-options" id="geoLayerOptions">
                    <label><input type="checkbox" value="district"> <span>Distrito</span></label>
                    <label><input type="checkbox" value="circuit"> <span>Circuito</span></label>
                    <label><input type="checkbox" value="route"> <span>Ruta</span></label>
                </div></div>
                </div>
                <div class="geo-service-filter" id="geoServiceFilter">
                    <span class="geo-filter-label">Tipos de servicio</span>
                    <button class="geo-service-toggle" type="button" id="geoServiceToggle" aria-expanded="false">
                        <svg class="geo-control-icon" aria-hidden="true" viewBox="0 0 24 24"><path d="M20 13 13 20l-9-9V4h7l9 9Z"/><circle cx="8.5" cy="8.5" r="1.5"/></svg>
                        <span class="geo-toggle-label">Sin tipos</span><span class="geo-chevron" aria-hidden="true">▾</span>
                    </button>
                    <div class="geo-service-menu" id="geoServiceMenu" hidden>
                        <div class="geo-service-options" id="geoServiceOptions">
                            <?php foreach (($catalogos['tiposServicio'] ?? []) as $item): ?><label><input type="checkbox" value="<?= $esc($item['nombre']) ?>"> <span><?= $esc($item['nombre']) ?></span></label><?php endforeach; ?>
                        </div>
                        <div class="geo-service-actions"><button type="button" id="geoSelectAllTypes">Seleccionar todos</button><button type="button" id="geoClearTypes">Limpiar selección</button></div>
                    </div>
                </div>
            </div>
        </form>

        <section class="geo-workspace">
            <div class="geo-map-wrap">
                <div id="geoMap" aria-label="Mapa de distribución geográfica"></div>
                <div class="geo-map-tools">
                    <?php if ($canTrace): ?>
                    <div class="geo-trace-dropdown" id="traceDropdown">
                        <button class="geo-primary geo-map-tool--label" type="button" id="btnTrace" disabled>
                            <svg class="geo-map-tool-icon" aria-hidden="true" viewBox="0 0 24 24"><path d="m12 3 9 5-9 5-9-5 9-5Zm-7.5 9L12 16.2l7.5-4.2M4.5 16 12 20.2l7.5-4.2"/></svg>
                            Trazados <span aria-hidden="true">▾</span>
                        </button>
                        <div class="geo-trace-menu" id="traceMenu" hidden>
                            <button type="button" id="btnDistrictTrace">⌁ Distrito</button>
                            <button type="button" id="btnCircuitTrace">⌁ Circuito</button>
                            <button type="button" data-trace-target="RUTA">⌁ Ruta</button>
                        </div>
                    </div>
                    <?php endif; ?>
                    <?php if ($canEdit): ?>
                    <button class="geo-map-tool--label" type="button" id="btnLocation" disabled>
                        <svg class="geo-map-tool-icon" aria-hidden="true" viewBox="0 0 24 24"><path d="M12 21s7-5.2 7-12a7 7 0 1 0-14 0c0 6.8 7 12 7 12Z"/><circle cx="12" cy="9" r="2.5"/></svg>
                        Marcador
                    </button>
                    <?php endif; ?>
                    <span><b id="visiblePointCount">0</b> registros visibles</span>
                    <button type="button" id="centerGeoMap" title="Ubicación" aria-label="Centrar el mapa en la ubicación visible">
                        <svg class="geo-map-tool-icon" aria-hidden="true" viewBox="0 0 24 24"><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/><path d="M12 2v3m0 14v3M2 12h3m14 0h3"/></svg>
                    </button>
                    <button type="button" id="fullscreenGeoMap" title="Pantalla completa" aria-label="Ver mapa en pantalla completa">
                        <svg class="geo-map-tool-icon" aria-hidden="true" viewBox="0 0 24 24"><path d="M8 3H3v5m13-5h5v5M8 21H3v-5m13 5h5v-5"/></svg>
                    </button>
                </div>
                <div class="geo-edit-tools" id="traceTools" hidden><strong>Dibuje el recorrido haciendo clic en el mapa</strong><button class="geo-secondary" type="button" id="undoTrace">↶ Deshacer</button><button class="geo-ghost" type="button" id="cancelTrace">Cancelar</button><button class="geo-primary" type="button" id="saveTrace">Guardar trazado</button></div>
                <aside class="geo-trace-options" id="traceOptions" hidden aria-label="Opciones del trazado">
                    <header><span>⌁</span><div><strong>Estilo del trazado</strong><small>Configure la geometría</small></div></header>
                    <label>Tipo de trazado<select id="traceType"><option value="lineal">Lineal (recorrido)</option><option value="area">Área (polígono)</option></select></label>
                    <label>Color<div class="geo-color-control"><input type="color" id="traceColor" value="#f8f8f8"><output id="traceColorValue">#2563EB</output></div></label>
                    <label>Grosor <output id="traceWidthValue">6 px</output><input type="range" id="traceWidth" min="1" max="20" value="6"></label>
                    <p id="traceTypeHelp">Marque al menos dos puntos para formar el recorrido.</p>
                </aside>
                <div class="geo-edit-hint" id="locationHint" hidden>Seleccione en el mapa la ubicación del lugar de servicio. <button type="button" id="cancelLocation">Cancelar</button></div>
                <div class="geo-legend"><strong>Leyenda</strong><span><i class="covered"></i> Cubierto</span><span><i class="unassigned"></i> Sin asignación</span><span><i class="district-trace"></i> Distrito</span><span><i class="circuit-trace"></i> Circuito</span><span><i class="route"></i> Ruta</span></div>
                <div class="geo-map-empty" id="geoMapEmpty" hidden>Seleccione un distrito y una ruta para visualizar el trazado y los lugares de servicio.</div>
            </div>
            <aside class="geo-detail is-open" id="geoDetail" aria-live="polite" aria-hidden="false">
                <header><h2>Información del lugar</h2><button type="button" id="closeDetail" aria-label="Cerrar">×</button></header>
                <div class="geo-detail-empty"><span>📍</span><strong>Seleccione un lugar de servicio</strong><p>Aquí verá la información, ubicación y personal asignado.</p></div>
            </aside>
        </section>

        <section class="geo-stats" aria-label="Resumen de distribución">
            <article><i class="purple">📍</i><span>Lugares registrados<strong id="statRegistered">0</strong></span></article>
            <article><i class="green">♟</i><span>Con personal<strong id="statCovered">0</strong></span></article>
            <article><i class="gray">○</i><span>Sin asignación<strong id="statUnassigned">0</strong></span></article>
            <article><i class="blue">♙</i><span>Agentes asignados<strong id="statPersonnel">0</strong></span></article>
            <article><i class="blue">▧</i><span>Rutas activas<strong id="statRoutes">0</strong></span></article>
        </section>
    </main>

    <div class="geo-toast" id="geoToast" role="status" aria-live="polite"></div>

    <?php if ($canEdit): ?>
    <div class="geo-modal" id="locationModal" hidden>
        <div class="geo-modal-dialog geo-location-dialog" role="dialog" aria-modal="true" aria-labelledby="locationTitle">
            <header class="geo-modal-header"><div><p>Georreferenciación</p><h2 id="locationTitle">Asignar ubicación</h2></div><button type="button" id="closeLocation" aria-label="Cerrar">×</button></header>
            <form class="geo-step-panel is-active" id="locationForm">
                <div class="geo-location-summary"><p><span>Distrito</span><strong id="locationDistrict">—</strong></p><p><span>Ruta</span><strong id="locationRoute">—</strong></p><p><span>Latitud</span><strong id="locationLat">—</strong></p><p><span>Longitud</span><strong id="locationLng">—</strong></p></div>
                <label class="geo-location-select">Lugar de servicio<select id="locationPlace" required><option value="">Seleccione un lugar de servicio</option></select></label>
                <div class="geo-replace-warning" id="replaceWarning" hidden>Este lugar de servicio ya posee una ubicación asignada. Al continuar se reemplazará y quedará registrada en auditoría.</div>
                <div class="geo-modal-actions"><button class="geo-ghost" type="button" id="cancelLocationModal">Cancelar</button><button class="geo-primary" type="submit" id="saveLocation">Guardar ubicación</button></div>
            </form>
        </div>
    </div>
    <?php endif; ?>

    <?php if ($canCreate): ?>
    <!-- WIZARD: DIBUJAR NUEVA RUTA -->
    <div class="geo-modal" id="drawWizard" hidden>
        <div class="geo-modal-dialog" role="dialog" aria-modal="true">
            <header class="geo-modal-header"><div><p>Nueva ruta</p><h2 id="drawRouteTitle">Dibujar ruta geográfica</h2></div><button type="button" id="cancelDraw" aria-label="Cerrar">×</button></header>
            <div class="geo-step-panel is-active">
                <div class="geo-step-heading"><div><h3>Información de la ruta</h3><p>Nombre, estilo visual y tipo de geometría del trazado.</p></div></div>
                <div class="geo-form-grid">
                    <label>Nombre de la ruta<input id="drawRouteName" maxlength="150" required placeholder="Ej: Boulevard 9 de Octubre"></label>
                    <label>Descripción<textarea id="drawRouteDesc" rows="2" maxlength="500" placeholder="Opcional"></textarea></label>
                    <label>Tipo de geometría<select id="drawRouteGeometry"><option value="lineal">Recorrido lineal</option><option value="area">Área geográfica</option></select></label>
                    <label>Color<input id="drawRouteColor" type="color" value="#2563EB"></label>
                    <label>Grosor<input id="drawRouteWidth" type="range" min="1" max="20" value="6"></label>
                    <label>Opacidad<input id="drawRouteOpacity" type="range" min="0.1" max="1" step="0.05" value="0.55"></label>
                    <label>Estado<select id="drawRouteState"><option value="ACTIVA">Activa</option><option value="BORRADOR">Borrador</option><option value="INACTIVA">Inactiva</option></select></label>
                </div>
                <div class="geo-draw-actions">
                    <button class="geo-primary" type="button" id="startDraw">✏ Dibujar en el mapa</button>
                </div>
                <div class="geo-draw-tools" id="drawTools" hidden>
                    <span>Haga clic en el mapa para dibujar. Use las herramientas para controlar.</span>
                    <button class="geo-secondary" type="button" id="undoPoint">↩ Deshacer punto</button>
                    <button class="geo-secondary" type="button" id="clearDrawing">✕ Limpiar</button>
                </div>
                <div id="drawMap" style="height:350px;border:1px solid #dce4ef;border-radius:8px;margin-top:12px"></div>
                <div style="margin-top:14px;display:flex;gap:8px;justify-content:flex-end">
                    <button class="geo-ghost" type="button" id="cancelDraw2">Cancelar</button>
                    <button class="geo-primary" type="button" id="saveRoute">Guardar ruta</button>
                </div>
            </div>
        </div>
    </div>

    <!-- WIZARD: AGREGAR LUGAR DE SERVICIO -->
    <div class="geo-modal" id="placeWizard" hidden>
        <div class="geo-modal-dialog" role="dialog" aria-modal="true">
            <header class="geo-modal-header"><div><p>Lugar de servicio</p><h2 id="placeWizardTitle">Agregar lugar de servicio</h2></div><button type="button" id="cancelPlace" aria-label="Cerrar">×</button></header>
            <div class="geo-step-panel is-active">
                <form id="placeForm" novalidate>
                    <input type="hidden" name="id" id="place_id">
                    <div class="geo-form-grid">
                        <label>Nombre<input name="nombre" maxlength="180" required placeholder="Ej: 9 de Octubre y Chimborazo"></label>
                        <label>Descripción<textarea name="descripcion" rows="2" maxlength="500" placeholder="Opcional"></textarea></label>
                        <label>Dirección referencial<input name="direccion_referencial" maxlength="300" placeholder="Ej: Frente al parque"></label>
                        <label>Estado<select name="estado"><option value="ACTIVO">Activo</option><option value="INACTIVO">Inactivo</option></select></label>
                    </div>
                    <div class="geo-location-grid"><div id="placeMap" style="height:300px;border:1px solid #dce4ef;border-radius:8px"></div><div class="geo-location-fields"><label>Latitud<input name="latitud" inputmode="decimal" placeholder="-2.189875"></label><label>Longitud<input name="longitud" inputmode="decimal" placeholder="-79.884521"></label><p style="color:#637089;font-size:10px">Haga clic en el mapa para ubicar el punto.</p></div></div>
                    <div style="margin-top:14px;display:flex;gap:8px;justify-content:flex-end">
                        <button class="geo-ghost" type="button" id="cancelPlace2">Cancelar</button>
                        <button class="geo-primary" type="submit">Guardar lugar de servicio</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- WIZARD: ASIGNAR AGENTE A LUGAR DE SERVICIO -->
    <div class="geo-modal" id="assignWizard" hidden>
        <div class="geo-modal-dialog" role="dialog" aria-modal="true">
            <header class="geo-modal-header"><div><p>Asignación</p><h2>Asignar agente al lugar de servicio</h2></div><button type="button" id="cancelAssign" aria-label="Cerrar">×</button></header>
            <div class="geo-step-panel is-active">
                <div class="geo-agent-search"><label>Buscar agente<input id="agentSearch" type="search" placeholder="Nombres, apellidos o cédula"></label><div id="agentResults" class="geo-agent-results"></div></div>
                <div class="geo-assignment-editor" id="assignmentEditor" hidden>
                    <div class="geo-selected-agent" id="selectedAgent"></div>
                    <div class="geo-form-grid compact">
                        <label>Tipo<select id="assignType"><option value="FIJA">Fija</option><option value="TEMPORAL">Temporal</option><option value="RELEVO">Relevo</option></select></label>
                        <label>Fecha inicio<input id="assignStartDate" type="date"></label>
                        <label>Fecha fin<input id="assignEndDate" type="date"></label>
                        <label>Turno<select id="assignShift"><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
                        <label>Hora inicio<input id="assignStartTime" type="time"></label>
                        <label>Hora fin<input id="assignEndTime" type="time"></label>
                        <label>Función<input id="assignRole" placeholder="Ej: Vigilancia"></label>
                        <label>Observaciones<input id="assignNotes"></label>
                    </div>
                    <button class="geo-primary" id="addAgent" type="button">＋ Agregar agente</button>
                </div>
                <div style="margin-top:14px;display:flex;gap:8px;justify-content:flex-end">
                    <button class="geo-ghost" type="button" id="cancelAssign2">Cerrar</button>
                </div>
            </div>
        </div>
    </div>
    <?php endif; ?>

    <script id="geoCatalogs" type="application/json"><?= json_encode($catalogos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?></script>
</div>
