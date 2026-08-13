<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canAssign = $isAdmin || in_array('tablero_distribucion.asignar', $permissions, true);
$canDelete = $isAdmin || in_array('tablero_distribucion.eliminar', $permissions, true);
$canForce = $isAdmin || in_array('distribucion.forzar_asignacion', $permissions, true);
?>
<div class="td-app" data-can-assign="<?= $canAssign ? '1' : '0' ?>" data-can-delete="<?= $canDelete ? '1' : '0' ?>" data-can-force="<?= $canForce ? '1' : '0' ?>">
    <?php if (!empty($error)): ?><div class="td-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

    <header class="td-page-head">
        <div class="td-page-title">
            <span class="td-title-icon" aria-hidden="true">⌖</span>
            <div><h1>Tablero de Distribución</h1><p>Asignación de personal por ruta y lugares de servicio</p></div>
        </div>
        <section class="td-filter-card" aria-label="Filtros del tablero">
            <label>Distrito
                <select id="tdDistrict"><option value="">Seleccione distrito</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
            </label>
            <label>Circuito
                <select id="tdCircuit" disabled><option value="">Seleccione distrito</option></select>
            </label>
            <label>Turno
                <select id="tdShift"><option value="">Seleccione turno</option><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
            </label>
            <label>Fecha
                <input id="tdBoardDate" type="date" value="<?= date('Y-m-d') ?>">
            </label>
            <?php if ($canAssign): ?><button class="td-btn td-btn-primary td-save-button" id="tdSaveDraft" type="button"><span aria-hidden="true">▣</span> Guardar distribución</button><?php endif; ?>
        </section>
    </header>

    <div class="td-board">
        <aside class="td-routes-card">
            <div class="td-card-heading"><h2>Lugares de servicio</h2><a href="/admin?tab=rutas" title="Crear ruta" aria-label="Crear ruta">+</a></div>
            <label class="td-search"><span aria-hidden="true">⌕</span><input id="tdRouteSearch" type="search" placeholder="Buscar lugar de servicio..."></label>
            <div class="td-route-list" id="tdRouteList"><div class="td-empty-small">Seleccione distrito y turno.</div></div>
            <a class="td-new-route" href="/admin?tab=rutas">＋ Crear nueva ruta</a>
        </aside>

        <section class="td-workspace">
            <div class="td-empty-board" id="tdEmptyBoard"><span>⌖</span><strong>Seleccione una ruta</strong><p>Elija un distrito, turno y una ruta para comenzar la distribución.</p></div>
            <div id="tdRouteWorkspace" hidden>
                <section class="td-manager-card" id="tdDistrictManagerCard" hidden>
                    <div class="td-manager-copy"><small>RESPONSABILIDAD DEL DISTRITO</small><h3>Encargado de distrito</h3><p id="tdDistrictManagerValue">Sin asignar</p>
                        <div class="td-district-circuit-option" id="tdDistrictCircuitOption">
                            <label><input id="tdDistrictAsCircuitManager" type="checkbox"> Asignar también como encargado de circuito</label>
                            <select id="tdDistrictManagerCircuit"><option value="">Seleccione circuito</option></select>
                        </div>
                    </div>
                    <?php if ($canAssign): ?><div class="td-manager-actions"><button class="td-btn td-btn-primary td-btn-sm" id="tdAssignDistrictManager" type="button">Asignar encargado de distrito</button><button class="td-btn td-btn-ghost td-btn-sm" id="tdRemoveDistrictManager" type="button" hidden>Quitar</button></div><?php endif; ?>
                </section>
                <section class="td-circuit-managers" id="tdCircuitManagersCard">
                    <header><div><small>RESPONSABILIDAD OPERATIVA</small><h3>Encargados de circuito</h3></div><?php if ($canAssign): ?><button class="td-btn td-btn-primary td-btn-sm" id="tdAddCircuitManager" type="button">+ Agregar encargado de circuito</button><?php endif; ?></header>
                    <div id="tdCircuitManagersList"><p class="td-empty-small">No existen encargados de circuito asignados.</p></div>
                </section>
                <div class="td-route-heading"><h2 id="tdRouteName">Ruta</h2><span id="tdRoutePlacesBadge">0 lugares</span></div>
                <section class="td-manager-card td-route-manager" id="tdRouteManagerCard" hidden>
                    <div><small>RESPONSABILIDAD DE LA RUTA</small><h3>Encargado de ruta</h3><p id="tdRouteManagerValue">Sin encargado de ruta · Responsable: Encargado del Distrito</p></div>
                    <?php if ($canAssign): ?><div class="td-manager-actions"><label class="td-manager-switch"><input id="tdRouteManagerRequired" type="checkbox"><span></span> Asignar encargado</label><button class="td-btn td-btn-primary td-btn-sm" id="tdAssignRouteManager" type="button" hidden>Seleccionar agente</button></div><?php endif; ?>
                </section>
                <div class="td-kpis">
                    <article><i class="td-kpi-teal">⌖</i><div><strong id="tdKpiPlaces">0</strong><b>Lugares</b><small>Total de lugares</small></div></article>
                    <article><i class="td-kpi-blue">♙</i><div><strong id="tdKpiRequired">0</strong><b>Requeridos</b><small>Personal necesario</small></div></article>
                    <article><i class="td-kpi-green">♟</i><div><strong id="tdKpiAssigned">0</strong><b>Asignados</b><small>Personal asignado</small></div></article>
                    <article><i class="td-kpi-orange">◷</i><div><strong id="tdKpiPending">0</strong><b>Pendientes</b><small>Por asignar</small></div></article>
                    <article class="td-coverage-kpi"><i class="td-kpi-purple">◴</i><div><strong id="tdKpiCoverage">0%</strong><b>Cobertura</b><small id="tdCoverageLabel">Ruta incompleta</small></div><span><em id="tdCoverageBar"></em></span></article>
                </div>

                <section class="td-table-card">
                    <h3>Lugares y asignación de personal</h3>
                    <div class="td-table-scroll"><table><thead><tr><th>#</th><th>Lugar de servicio</th><th>Requerido</th><th>Asignación actual</th><th>Estado</th><th>Acciones</th></tr></thead><tbody id="tdPlacesBody"></tbody></table></div>
                </section>

                <div class="td-bottom-bar">
                    <section class="td-random-card"><div class="td-tool-title"><i>◇</i><h3>Asignación aleatoria</h3></div><p>Asigna personal disponible a todos los lugares del circuito seleccionado.</p><?php if ($canAssign): ?><button class="td-btn td-btn-primary" id="tdRandomAssign" type="button">Asignar circuito</button><?php endif; ?><div class="td-no-repeat"><b>◆ <span>Prioridad operativa</span></b><p>Primero deben definirse los encargados de distrito, circuito y rutas. Los agentes no se repiten.</p></div></section>
                    <section class="td-availability-card"><h3>Disponibilidad actual</h3><dl><div><dt><i class="is-available"></i>Disponibles</dt><dd id="tdAvailable">0</dd></div><div><dt><i class="is-service"></i>En servicio</dt><dd id="tdInService">0</dd></div><div><dt><i class="is-unavailable"></i>No disponibles</dt><dd id="tdUnavailable">0</dd></div><div class="td-total"><dt>Total agentes</dt><dd id="tdTotalAgents">0</dd></div></dl></section>
                </div>

                <section class="td-info-bar"><i>i</i><div><b>Guardar distribución</b><p>Al guardar, el sistema solicitará la fecha de la distribución de personal y se registrará automáticamente como:</p><strong>DISTRIBUCIÓN DE PERSONAL FECHA XX/XX/XXXX</strong></div><span aria-hidden="true">▦　→　▤</span></section>
            </div>
        </section>
    </div>

    <div class="td-modal td-modal-lg" id="tdAgentModal" hidden>
        <div class="td-modal-dialog">
            <header>
                <div>
                    <small>Cambiar agente asignado</small>
                    <h3 id="tdAgentModalTitle">Seleccionar agente</h3>
                    <p id="tdAgentModalSubtitle" class="td-modal-subtitle"></p>
                </div>
                <button type="button" data-close="tdAgentModal">&times;</button>
            </header>
            <div class="td-modal-body">
                <div class="td-agent-info-bar" id="tdAgentInfoBar"></div>
                <div class="td-agent-filters">
                    <label class="td-agent-search-label">
                        <span>&#128269;</span>
                        <input id="tdAgentSearch" type="search" placeholder="Buscar por nombre, apellido o cedula...">
                    </label>
                    <select id="tdFilterGrupo"><option value="">Grupo</option></select>
                    <select id="tdFilterTipoServicio"><option value="">Tipo servicio</option></select>
                    <select id="tdFilterGrado"><option value="">Grado</option></select>
                    <select id="tdFilterEstado"><option value="">Estado</option></select>
                    <button class="td-btn td-btn-ghost td-btn-sm" id="tdClearAgentFilters" type="button">Limpiar filtros</button>
                </div>
                <div class="td-agent-table-wrap">
                    <table class="td-agent-table">
                        <thead><tr>
                            <th>Agente</th><th>Identificacion</th><th>Grupo</th><th>Tipo servicio</th><th>Grado</th><th>Estado</th><th>Disponibilidad</th><th>Accion</th>
                        </tr></thead>
                        <tbody id="tdAgentTableBody"></tbody>
                    </table>
                </div>
                <div class="td-agent-pagination" id="tdAgentPagination"></div>
            </div>
            <footer>
                <button class="td-btn td-btn-ghost" type="button" data-close="tdAgentModal">Cancelar</button>
            </footer>
        </div>
    </div>

    <div class="td-modal td-modal-md" id="tdCircuitManagerModal" hidden>
        <div class="td-modal-dialog">
            <header><div><small>Responsabilidad operativa</small><h3>Encargado de circuito</h3></div><button type="button" data-close="tdCircuitManagerModal">&times;</button></header>
            <div class="td-modal-body td-circuit-editor">
                <label>Circuito<select id="tdCircuitManagerCircuit"><option value="">Seleccione circuito</option></select></label>
                <label class="td-circuit-role"><span>Encargado</span><strong id="tdCircuitManagerName">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="manager">Buscar usuario</button></label>
                <label class="td-circuit-role"><span>Auxiliar 1</span><strong id="tdCircuitAux1Name">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="aux1">Buscar usuario</button></label>
                <label class="td-circuit-role"><span>Auxiliar 2</span><strong id="tdCircuitAux2Name">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="aux2">Buscar usuario</button></label>
                <label>Móvil asignado<select id="tdCircuitMobile"><option value="">Sin móvil</option></select></label>
            </div>
            <footer><button class="td-btn td-btn-ghost" type="button" data-close="tdCircuitManagerModal">Cancelar</button><button class="td-btn td-btn-primary" id="tdSaveCircuitManager" type="button">Guardar encargado</button></footer>
        </div>
    </div>

    <div class="td-modal td-modal-md" id="tdForceModal" hidden>
        <div class="td-modal-dialog">
            <header>
                <div>
                    <small class="td-force-warning">Forzar asignacion</small>
                    <h3>&#9888; Forzar asignacion</h3>
                </div>
                <button type="button" data-close="tdForceModal">&times;</button>
            </header>
            <div class="td-modal-body">
                <div class="td-force-warning-box">
                    El agente seleccionado actualmente se encuentra en estado: <strong id="tdForceAgentStatus"></strong>.
                    Por esta condicion el agente no deberia ser asignado a un servicio.
                    &iquest;Desea forzar la asignacion de este agente?
                </div>
                <div class="td-force-details">
                    <div><b>Agente:</b> <span id="tdForceAgentName"></span></div>
                    <div><b>Estado:</b> <span id="tdForceAgentEstado"></span></div>
                    <div><b>Lugar:</b> <span id="tdForceLugar"></span></div>
                    <div><b>Turno:</b> <span id="tdForceTurno"></span></div>
                </div>
                <div class="td-force-justificacion">
                    <label><b>Motivo de la asignacion forzada</b>
                        <textarea id="tdForceJustificacion" rows="3" placeholder="Ej: Por disposicion del superior de turno."></textarea>
                    </label>
                </div>
            </div>
            <footer>
                <button class="td-btn td-btn-ghost" type="button" data-close="tdForceModal">Cancelar</button>
                <button class="td-btn td-btn-warning" id="tdConfirmForce" type="button">Forzar asignacion</button>
            </footer>
        </div>
    </div>

    <div class="td-modal" id="tdSaveModal" hidden><div class="td-modal-dialog td-modal-small"><header><div><small>Confirmación</small><h3>Guardar distribución de personal</h3></div><button type="button" data-close="tdSaveModal">×</button></header><div class="td-modal-body"><p>Seleccione la fecha de la distribución de personal.</p><label class="td-date-label">Fecha de distribución<input id="tdDistributionDate" type="date" required></label><p class="td-generated-name" id="tdGeneratedName">DISTRIBUCIÓN DE PERSONAL FECHA DD/MM/AAAA</p></div><footer><button class="td-btn td-btn-ghost" type="button" data-close="tdSaveModal">Cancelar</button><button class="td-btn td-btn-primary" id="tdConfirmSave" type="button">Guardar distribución</button></footer></div></div>


    <div class="td-modal" id="tdResultModal" hidden><div class="td-modal-dialog"><header><div><small>Registro guardado</small><h3>✓ Distribución guardada correctamente</h3></div><button type="button" data-close="tdResultModal">×</button></header><div class="td-modal-body"><div class="td-success-result"><i>✓</i><h4 id="tdSavedName"></h4><p id="tdSavedSummary"></p></div><div class="td-saved-detail" id="tdSavedDetail"></div></div><footer class="td-result-actions"><button class="td-btn td-btn-ghost" id="tdViewSaved" type="button">Ver distribución</button><button class="td-btn td-btn-ghost" id="tdEditSaved" type="button">Editar distribución</button><button class="td-btn td-btn-ghost" id="tdPrintSaved" type="button">Imprimir</button><button class="td-btn td-btn-ghost" id="tdPdfSaved" type="button">Exportar PDF</button><?php if ($canDelete): ?><button class="td-btn td-btn-danger" id="tdDeleteSaved" type="button">Eliminar</button><?php endif; ?></footer></div></div>

    <div class="td-toast" id="tdToast" role="status" aria-live="polite"></div>
    <script id="tdCatalogs" type="application/json"><?= json_encode($catalogos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?></script>
</div>
