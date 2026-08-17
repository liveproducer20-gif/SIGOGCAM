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
            <span class="td-title-icon" aria-hidden="true">&#9881;</span>
            <div><h1>Tablero de Distribuci&oacute;n</h1><p>Asignaci&oacute;n de personal por ruta y lugares de servicio</p></div>
        </div>
        <section class="td-filter-card" aria-label="Filtros del tablero">
            <label>Turno
                <select id="tdShift"><option value="">Seleccione turno</option><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
            </label>
            <label>Fecha
                <input id="tdBoardDate" type="date" value="<?= date('Y-m-d') ?>">
            </label>
        </section>
    </header>

    <select id="tdDistrict" hidden aria-hidden="true"><option value="">Seleccione distrito</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
    <select id="tdCircuit" hidden aria-hidden="true" disabled><option value="">Seleccione distrito</option></select>
    <section class="td-district-overview" aria-label="Estado guardado de los distritos">
        <div class="td-district-cards" id="tdDistrictCards"><div class="td-empty-small">Consultando distribuciones guardadas...</div></div>
        <p class="td-overview-help"><i>i</i> Seleccione un distrito para consultar y distribuir sus circuitos.</p>
    </section>

    <section class="td-selected-panel" id="tdSelectedDistrictPanel" hidden>
        <header><span>Mostrando circuitos disponibles de:</span><strong id="tdSelectedDistrictName"></strong></header>
        <div class="td-circuit-accordion" id="tdCircuitAccordion"></div>
    </section>

    <div class="td-board">
        <section class="td-workspace">
            <div class="td-empty-board" id="tdEmptyBoard"><span>&#9881;</span><strong>Seleccione una ruta</strong><p>Elija un distrito, turno y una ruta para comenzar la distribuci&oacute;n.</p></div>
            <div id="tdRouteWorkspace" hidden>

                <div class="td-kpis">
                    <article><i class="td-kpi-teal">&#9881;</i><div><strong id="tdKpiPlaces">0</strong><b>Lugares</b><small>Total</small></div></article>
                    <article><i class="td-kpi-blue">&#9823;</i><div><strong id="tdKpiRequired">0</strong><b>Requeridos</b><small>Necesarios</small></div></article>
                    <article><i class="td-kpi-green">&#9823;</i><div><strong id="tdKpiAssigned">0</strong><b>Asignados</b><small>Personal</small></div></article>
                    <article><i class="td-kpi-orange">&#9788;</i><div><strong id="tdKpiPending">0</strong><b>Pendientes</b><small>Por asignar</small></div></article>
                    <article class="td-coverage-kpi"><i class="td-kpi-purple">&#9711;</i><div><strong id="tdKpiCoverage">0%</strong><b>Cobertura</b><small id="tdCoverageLabel">Incompleta</small></div><span><em id="tdCoverageBar"></em></span></article>
                </div>

                <section class="td-managers-row">
                    <section class="td-manager-card" id="tdDistrictManagerCard" hidden>
                        <div class="td-manager-copy"><small>RESPONSABILIDAD DEL DISTRITO</small><h3>Encargado de distrito</h3><p id="tdDistrictManagerValue">Sin asignar</p>
                            <div class="td-resource-summary" id="tdDistrictResources"></div>
                            <div class="td-district-circuit-option" id="tdDistrictCircuitOption">
                                <label><input id="tdDistrictAsCircuitManager" type="checkbox"> Asignar tambi&eacute;n como encargado de circuito</label>
                                <select id="tdDistrictManagerCircuit"><option value="">Seleccione circuito</option></select>
                            </div>
                        </div>
                        <?php if ($canAssign): ?><div class="td-manager-actions"><button class="td-btn td-btn-ghost td-btn-sm" id="tdEditDistrictResources" type="button">Gestionar recursos</button><button class="td-btn td-btn-primary td-btn-sm" id="tdAssignDistrictManager" type="button">Cambiar encargado</button><button class="td-btn td-btn-ghost td-btn-sm" id="tdRemoveDistrictManager" type="button" hidden>Quitar</button></div><?php endif; ?>
                    </section>
                    <section class="td-circuit-managers" id="tdCircuitManagersCard">
                        <header><div><small>RESPONSABILIDAD OPERATIVA</small><h3>Encargados de circuito</h3></div><?php if ($canAssign): ?><button class="td-btn td-btn-primary td-btn-sm" id="tdAddCircuitManager" type="button">+ Agregar</button><?php endif; ?></header>
                        <div id="tdCircuitManagersList"><p class="td-empty-small">No existen encargados de circuito asignados.</p></div>
                    </section>
                    <section class="td-manager-card td-route-manager" id="tdRouteManagerCard" hidden>
                        <div><small>RESPONSABILIDAD DE LA RUTA</small><h3>Encargado de ruta</h3><p id="tdRouteManagerValue">Sin encargado de ruta<br><em>Responsable: Encargado del circuito</em></p></div>
                        <?php if ($canAssign): ?><div class="td-manager-actions"><label class="td-manager-switch"><input id="tdRouteManagerRequired" type="checkbox"><span></span> Asignar encargado</label><button class="td-btn td-btn-primary td-btn-sm" id="tdAssignRouteManager" type="button" hidden>Seleccionar</button></div><?php endif; ?>
                    </section>
                </section>

                <div class="td-assignment-zone">
                    <aside class="td-routes-card">
                        <div class="td-card-heading"><h2>Lugares de servicio</h2></div>
                        <label class="td-search"><span aria-hidden="true">&#128269;</span><input id="tdRouteSearch" type="search" placeholder="Buscar lugar..."></label>
                        <div class="td-route-list" id="tdRouteList"><div class="td-empty-small">Seleccione distrito y turno.</div></div>
                    </aside>
                    <div class="td-table-card">
                        <div class="td-table-header"><h3>Lugares y asignaci&oacute;n de personal</h3><span id="tdRouteName"></span><span id="tdRoutePlacesBadge" class="td-badge-count"></span></div>
                        <div class="td-table-scroll"><table><thead><tr><th>Lugar de servicio</th><th>Requerido</th><th>Asignaci&oacute;n actual</th><th>Estado</th><th>Acciones</th></tr></thead><tbody id="tdPlacesBody"></tbody></table></div>
                    </div>
                </div>

                <div class="td-bottom-bar">
                    <section class="td-random-card"><div class="td-tool-title"><i>&#9671;</i><h3>Asignaci&oacute;n aleatoria</h3></div><p>Asigna personal disponible a todos los lugares del circuito.</p><?php if ($canAssign): ?><button class="td-btn td-btn-primary" id="tdRandomAssign" type="button">Asignar circuito</button><?php endif; ?><div class="td-no-repeat"><b>&#9670; <span>Prioridad operativa</span></b><p>Primero deben definirse encargados. Los agentes no se repiten.</p></div></section>
                    <section class="td-availability-card"><h3>Disponibilidad actual</h3><dl><div><dt><i class="is-available"></i>Disponibles</dt><dd id="tdAvailable">0</dd></div><div><dt><i class="is-service"></i>En servicio</dt><dd id="tdInService">0</dd></div><div><dt><i class="is-unavailable"></i>No disponibles</dt><dd id="tdUnavailable">0</dd></div><div class="td-total"><dt>Total agentes</dt><dd id="tdTotalAgents">0</dd></div></dl></section>
                </div>

                <section class="td-info-bar"><i>i</i><div><b>Guardar distribuci&oacute;n</b><p>Al guardar se registrar&aacute; autom&aacute;ticamente como:</p><strong>DISTRIBUCI&Oacute;N DE PERSONAL FECHA XX/XX/XXXX</strong></div></section>
                <?php if ($canAssign): ?><div class="td-district-savebar"><span class="td-save-state" id="tdUnsavedState">&#10003; Guardado</span><button class="td-btn td-btn-primary td-save-button" id="tdSaveDraft" type="button" disabled><span aria-hidden="true">&#128190;</span> Guardar distribuci&oacute;n</button></div><?php endif; ?>
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
                        <input id="tdAgentSearch" type="search" placeholder="Buscar por nombre o apellido...">
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
                            <th>Agente</th><th>Grupo</th><th>Tipo servicio</th><th>Grado</th><th>Estado</th><th>Disponibilidad</th><th>Accion</th>
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
            <header><div><small>Responsabilidad operativa</small><h3 id="tdResourceModalTitle">Recursos del encargado</h3><p id="tdResourceModalSubtitle" class="td-modal-subtitle"></p></div><button type="button" data-close="tdCircuitManagerModal">&times;</button></header>
            <div class="td-modal-body td-circuit-editor">
                <label id="tdCircuitManagerCircuitField">Circuito<select id="tdCircuitManagerCircuit"><option value="">Seleccione circuito</option></select></label>
                <label class="td-circuit-role"><span>Encargado</span><strong id="tdCircuitManagerName">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="manager">Buscar usuario</button></label>
                <label class="td-circuit-role"><span>Conductor <em>Requerido</em></span><strong id="tdCircuitDriverName">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="driver">Asignar</button></label>
                <label class="td-circuit-role"><span>Auxiliar 1 <em>Requerido</em></span><strong id="tdCircuitAux1Name">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="aux1">Asignar</button></label>
                <label class="td-circuit-role"><span>Auxiliar 2 <em>Opcional</em></span><strong id="tdCircuitAux2Name">Sin seleccionar</strong><button class="td-btn td-btn-ghost td-btn-sm" type="button" data-circuit-role="aux2">Asignar</button></label>
                <label>M&oacute;vil asignado <em>Requerido</em><select id="tdCircuitMobile"><option value="">Seleccione m&oacute;vil</option></select></label>
            </div>
            <footer><button class="td-btn td-btn-ghost" type="button" data-close="tdCircuitManagerModal">Cancelar</button><button class="td-btn td-btn-primary" id="tdSaveCircuitManager" type="button">Guardar recursos</button></footer>
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

    <div class="td-modal" id="tdSaveModal" hidden><div class="td-modal-dialog td-modal-small"><header><div><small>Confirmaci&oacute;n</small><h3>Guardar distribuci&oacute;n de personal</h3></div><button type="button" data-close="tdSaveModal">&times;</button></header><div class="td-modal-body"><p>Seleccione la fecha de la distribuci&oacute;n de personal.</p><label class="td-date-label">Fecha de distribuci&oacute;n<input id="tdDistributionDate" type="date" required></label><p class="td-generated-name" id="tdGeneratedName">DISTRIBUCI&Oacute;N DE PERSONAL FECHA DD/MM/AAAA</p></div><footer><button class="td-btn td-btn-ghost" type="button" data-close="tdSaveModal">Cancelar</button><button class="td-btn td-btn-primary" id="tdConfirmSave" type="button">Guardar distribuci&oacute;n</button></footer></div></div>


    <div class="td-modal" id="tdResultModal" hidden><div class="td-modal-dialog"><header><div><small>Registro guardado</small><h3>&#10003; Distribuci&oacute;n guardada correctamente</h3></div><button type="button" data-close="tdResultModal">&times;</button></header><div class="td-modal-body"><div class="td-success-result"><i>&#10003;</i><h4 id="tdSavedName"></h4><p id="tdSavedSummary"></p></div><div class="td-saved-detail" id="tdSavedDetail"></div></div><footer class="td-result-actions"><button class="td-btn td-btn-ghost" id="tdViewSaved" type="button">Ver distribuci&oacute;n</button><button class="td-btn td-btn-ghost" id="tdEditSaved" type="button">Editar distribuci&oacute;n</button><button class="td-btn td-btn-ghost" id="tdPrintSaved" type="button">Imprimir</button><button class="td-btn td-btn-ghost" id="tdPdfSaved" type="button">Exportar PDF</button><?php if ($canDelete): ?><button class="td-btn td-btn-danger" id="tdDeleteSaved" type="button">Eliminar</button><?php endif; ?></footer></div></div>

    <div class="td-modal td-modal-md" id="tdManageAgentsModal" hidden>
        <div class="td-modal-dialog">
            <header>
                <div>
                    <small>Gestionar personal</small>
                    <h3 id="tdManageAgentsTitle">Agentes asignados</h3>
                </div>
                <button type="button" data-close="tdManageAgentsModal">&times;</button>
            </header>
            <div class="td-modal-body">
                <div class="td-manage-place-info" id="tdManagePlaceInfo"></div>
                <div class="td-manage-list" id="tdManageAgentsList"></div>
                <div class="td-manage-actions">
                    <span id="tdManageRequiredInfo"></span>
                    <?php if ($canAssign): ?><button class="td-btn td-btn-primary td-btn-sm" id="tdManageAddAgent" type="button">+ Agregar agente</button><?php endif; ?>
                </div>
            </div>
            <footer>
                <button class="td-btn td-btn-ghost" type="button" data-close="tdManageAgentsModal">Cerrar</button>
            </footer>
        </div>
    </div>

    <div class="td-modal td-modal-md" id="tdDistrictDetailModal" hidden><div class="td-modal-dialog"><header><div><small>Detalle de distribuci&oacute;n pendiente</small><h3 id="tdDistrictDetailTitle">Distrito</h3></div><button type="button" data-close="tdDistrictDetailModal">&times;</button></header><div class="td-modal-body td-pending-detail" id="tdDistrictPendingDetail"></div><footer><button class="td-btn td-btn-ghost" type="button" data-close="tdDistrictDetailModal">Cerrar</button></footer></div></div>

    <div class="td-modal" id="tdUnsavedModal" hidden><div class="td-modal-dialog td-modal-small"><header><div><small>Cambios sin guardar</small><h3>¿Desea cambiar de distrito?</h3></div><button type="button" data-close="tdUnsavedModal">&times;</button></header><div class="td-modal-body"><p id="tdUnsavedMessage"></p></div><footer><button class="td-btn td-btn-ghost" type="button" data-close="tdUnsavedModal">Cancelar</button><button class="td-btn td-btn-danger" id="tdDiscardDistrict" type="button">Descartar cambios</button><button class="td-btn td-btn-primary" id="tdSaveAndSwitchDistrict" type="button">Guardar y continuar</button></footer></div></div>

    <div class="td-toast" id="tdToast" role="status" aria-live="polite"></div>
    <script id="tdCatalogs" type="application/json"><?= json_encode($catalogos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?></script>
</div>
