<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canRegister = $isAdmin || in_array('asistencia.registrar', $permissions, true);
$canEdit = $isAdmin || in_array('asistencia.editar', $permissions, true);
$canExport = $isAdmin || in_array('asistencia.ver', $permissions, true);
?>
<div class="pa-app" data-can-register="<?= $canRegister ? '1' : '0' ?>" data-can-edit="<?= $canEdit ? '1' : '0' ?>" data-can-export="<?= $canExport ? '1' : '0' ?>">
    <?php if (!empty($error)): ?><div class="pa-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

    <header class="pa-page-head">
        <div class="pa-page-title">
            <span class="pa-title-icon" aria-hidden="true">&#9744;</span>
            <div><h1>Panel de Asistencia</h1><p>Control de asistencia del personal asignado</p></div>
        </div>
    </header>

    <nav class="pa-tabs" role="tablist">
        <button class="pa-tab is-active" data-tab="registro" role="tab" aria-selected="true">&#9998; Registro</button>
        <button class="pa-tab" data-tab="historial" role="tab" aria-selected="false">&#9776; Historial</button>
    </nav>

    <section class="pa-tab-panel is-active" id="tab-registro" role="tabpanel">
        <section class="pa-filter-card" aria-label="Filtros de asistencia">
            <div class="pa-filter-row">
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Distrito</span>
                    <select id="paDistrict"><option value="">Todos los distritos</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Turno</span>
                    <select id="paShift"><option value="">Seleccione turno</option><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Ruta</span>
                    <select id="paRoute"><option value="">Todas las rutas</option></select>
                </label>
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Fecha</span>
                    <input id="paDate" type="date" value="<?= date('Y-m-d') ?>">
                </label>
                <?php if ($canRegister): ?>
                <button class="pa-btn pa-btn-primary pa-load-btn" id="paLoadBtn" type="button">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    Cargar personal
                </button>
                <?php endif; ?>
            </div>
        </section>

        <div class="pa-board">
            <aside class="pa-stats-card">
                <h2>Resumen del dia</h2>
                <div class="pa-stats-grid">
                    <div class="pa-stat"><span class="pa-stat-num" id="paTotal">0</span><span class="pa-stat-label">Total</span></div>
                    <div class="pa-stat pa-stat-green"><span class="pa-stat-num" id="paPresentes">0</span><span class="pa-stat-label">Presentes</span></div>
                    <div class="pa-stat pa-stat-orange"><span class="pa-stat-num" id="paAtrasos">0</span><span class="pa-stat-label">Atrasos</span></div>
                    <div class="pa-stat pa-stat-red"><span class="pa-stat-num" id="paAusentes">0</span><span class="pa-stat-label">Ausentes</span></div>
                    <div class="pa-stat pa-stat-blue"><span class="pa-stat-num" id="paPendientes">0</span><span class="pa-stat-label">Pendientes</span></div>
                    <div class="pa-stat pa-stat-purple"><span class="pa-stat-num" id="paNovedades">0</span><span class="pa-stat-label">Novedades</span></div>
                </div>
                <div class="pa-stat-bar">
                    <div class="pa-stat-bar-fill" id="paCoverageBar"></div>
                    <span id="paCoverageLabel">0%</span>
                </div>

                <div class="pa-legend">
                    <h3>Estados</h3>
                    <ul>
                        <li><span class="pa-dot pa-dot-green"></span> PRESENTE</li>
                        <li><span class="pa-dot pa-dot-orange"></span> ATRASO</li>
                        <li><span class="pa-dot pa-dot-red"></span> AUSENTE</li>
                        <li><span class="pa-dot pa-dot-blue"></span> PENDIENTE</li>
                        <li><span class="pa-dot pa-dot-purple"></span> PERMISO / VACACIONES</li>
                    </ul>
                </div>

                <div class="pa-quick-actions">
                    <?php if ($canRegister): ?>
                    <button class="pa-btn pa-btn-outline pa-btn-sm" id="paMarkAllPresent" type="button">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>
                        Todos presentes
                    </button>
                    <button class="pa-btn pa-btn-outline pa-btn-sm" id="paMarkAllAbsent" type="button">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6L6 18M6 6l12 12"/></svg>
                        Todos ausentes
                    </button>
                    <?php endif; ?>
                </div>
            </aside>

            <section class="pa-workspace">
                <div class="pa-empty-board" id="paEmptyBoard">
                    <span>&#9744;</span>
                    <strong>Seleccione filtros</strong>
                    <p>Elija distrito, turno y fecha para cargar el personal asignado.</p>
                </div>

                <div id="paAttendanceList" hidden>
                    <div class="pa-toolbar">
                        <div class="pa-search">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
                            <input id="paSearch" type="search" placeholder="Buscar por nombre o cedula...">
                        </div>
                        <div class="pa-toolbar-right">
                            <span class="pa-batch-info" id="paSelectedCount">0 seleccionados</span>
                            <?php if ($canExport): ?>
                            <button class="pa-btn pa-btn-outline pa-btn-sm" id="paExportBtn" type="button" title="Exportar a CSV">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                                Exportar
                            </button>
                            <?php endif; ?>
                            <?php if ($canRegister): ?>
                            <button class="pa-btn pa-btn-primary" id="paSaveBtn" type="button" disabled>
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
                                Guardar
                            </button>
                            <?php endif; ?>
                        </div>
                    </div>

                    <div class="pa-table-scroll">
                        <table>
                            <thead>
                                <tr>
                                    <th class="pa-th-check"><input type="checkbox" id="paCheckAll"></th>
                                    <th>#</th>
                                    <th>Agente</th>
                                    <th>Cedula</th>
                                    <th>Ruta / Lugar</th>
                                    <th>Estado</th>
                                    <th>Hora</th>
                                    <th>Observ.</th>
                                </tr>
                            </thead>
                            <tbody id="paTableBody"></tbody>
                        </table>
                    </div>
                </div>
            </section>
        </div>
    </section>

    <section class="pa-tab-panel" id="tab-historial" role="tabpanel" hidden>
        <section class="pa-filter-card" aria-label="Filtros de historial">
            <div class="pa-filter-row">
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Distrito</span>
                    <select id="paHistDistrict"><option value="">Todos</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
                </label>
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Estado</span>
                    <select id="paHistStatus">
                        <option value="">Todos</option>
                        <option value="PRESENTE">Presente</option>
                        <option value="ATRASO">Atraso</option>
                        <option value="AUSENTE">Ausente</option>
                        <option value="PERMISO">Permiso</option>
                        <option value="VACACIONES">Vacaciones</option>
                        <option value="INCAPACIDAD">Incapacidad</option>
                        <option value="FRANCO">Franco</option>
                    </select>
                </label>
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Desde</span>
                    <input id="paHistFrom" type="date" value="<?= date('Y-m-d', strtotime('-7 days')) ?>">
                </label>
                <label class="pa-filter-field">
                    <span class="pa-filter-label">Hasta</span>
                    <input id="paHistTo" type="date" value="<?= date('Y-m-d') ?>">
                </label>
                <button class="pa-btn pa-btn-primary pa-load-btn" id="paHistLoadBtn" type="button">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
                    Consultar
                </button>
            </div>
        </section>

        <div class="pa-history-workspace">
            <div class="pa-empty-board" id="paHistEmpty">
                <span>&#9776;</span>
                <strong>Consultar historial</strong>
                <p>Seleccione filtros y haga clic en Consultar para ver registros de asistencia.</p>
            </div>
            <div id="paHistoryList" hidden>
                <div class="pa-table-scroll">
                    <table>
                        <thead>
                            <tr>
                                <th>Fecha</th>
                                <th>Turno</th>
                                <th>Agente</th>
                                <th>Distrito</th>
                                <th>Ruta</th>
                                <th>Estado</th>
                                <th>Hora llegada</th>
                                <th>Observaciones</th>
                            </tr>
                        </thead>
                        <tbody id="paHistBody"></tbody>
                    </table>
                </div>
                <div class="pa-pagination" id="paHistPagination"></div>
            </div>
        </div>
    </section>

    <div id="paToast" class="pa-toast" role="status" aria-live="polite"></div>
</div>
