<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canCreate = $isAdmin || in_array('distribucion.crear', $permissions, true);
$canEdit = $isAdmin || in_array('distribucion.editar', $permissions, true);
$canAssign = $isAdmin || in_array('distribucion.asignar', $permissions, true);
?>
<div class="geo-app" data-can-create="<?= $canCreate ? '1' : '0' ?>" data-can-edit="<?= $canEdit ? '1' : '0' ?>" data-can-assign="<?= $canAssign ? '1' : '0' ?>">
    <main class="geo-main">
        <?php if (!empty($error)): ?><div class="geo-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

        <button class="geo-filter-toggle" type="button" id="geoFilterToggle">☷ Mostrar filtros</button>
        <form class="geo-filters" id="geoFilters">
            <label>Distrito<select name="distrito_id" id="filterDistrict" required><option value="">Seleccione un distrito</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select></label>
            <label>Ruta<select name="ruta_id" id="filterRoute" disabled><option value="">Seleccione un distrito primero</option></select></label>
            <label>Lugar de servicio<select name="lugar_servicio_id" id="filterServicePlace" disabled><option value="">Todos los lugares</option></select></label>
            <div class="geo-filter-actions">
                <?php if ($canCreate): ?><button class="geo-primary" type="button" id="btnNewRoute">＋ Dibujar nueva ruta</button><?php endif; ?>
                <?php if ($canCreate): ?><button class="geo-primary" type="button" id="btnAddPlace" style="display:none">＋ Agregar lugar de servicio</button><?php endif; ?>
            </div>
        </form>

        <section class="geo-workspace">
            <div class="geo-map-wrap">
                <div id="geoMap" aria-label="Mapa de distribución geográfica"></div>
                <div class="geo-map-tools"><span><b id="visiblePointCount">0</b> lugares visibles</span><button type="button" id="centerGeoMap" title="Centrar mapa">⌖</button><button type="button" id="fullscreenGeoMap" title="Pantalla completa">⛶</button></div>
                <div class="geo-legend"><strong>Leyenda</strong><span><i class="covered"></i> Cubierto</span><span><i class="unassigned"></i> Sin asignación</span><span><i class="route"></i> Ruta trazada</span></div>
                <div class="geo-map-empty" id="geoMapEmpty" hidden>Seleccione un distrito y una ruta para visualizar el trazado y los lugares de servicio.</div>
            </div>
            <aside class="geo-detail" id="geoDetail" aria-live="polite">
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
