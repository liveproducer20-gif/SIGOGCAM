<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canRegister = $isAdmin || in_array('asistencia.registrar', $permissions, true);
$canEdit = $isAdmin || in_array('asistencia.editar', $permissions, true);
?>
<div class="pa-app" data-can-register="<?= $canRegister ? '1' : '0' ?>" data-can-edit="<?= $canEdit ? '1' : '0' ?>">
    <?php if (!empty($error)): ?><div class="pa-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

    <header class="pa-page-head">
        <div class="pa-page-title">
            <span class="pa-title-icon" aria-hidden="true">&#9744;</span>
            <div><h1>Panel de Asistencia</h1><p>Control de asistencia del personal asignado</p></div>
        </div>
        <section class="pa-filter-card" aria-label="Filtros">
            <label>Distrito
                <select id="paDistrict"><option value="">Seleccione distrito</option><?php foreach (($catalogos['distritos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
            </label>
            <label>Turno
                <select id="paShift"><option value="">Seleccione turno</option><?php foreach (($catalogos['turnos'] ?? []) as $item): ?><option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option><?php endforeach; ?></select>
            </label>
            <label>Ruta
                <select id="paRoute"><option value="">Todas las rutas</option></select>
            </label>
            <label>Fecha
                <input id="paDate" type="date" value="<?= date('Y-m-d') ?>">
            </label>
            <?php if ($canRegister): ?><button class="pa-btn pa-btn-primary pa-load-btn" id="paLoadBtn" type="button">Cargar personal</button><?php endif; ?>
        </section>
    </header>

    <div class="pa-board">
        <aside class="pa-stats-card">
            <h2>Resumen del dia</h2>
            <div class="pa-stats-grid">
                <div class="pa-stat"><span class="pa-stat-num" id="paTotal">0</span><span class="pa-stat-label">Total</span></div>
                <div class="pa-stat pa-stat-green"><span class="pa-stat-num" id="paPresentes">0</span><span class="pa-stat-label">Presentes</span></div>
                <div class="pa-stat pa-stat-orange"><span class="pa-stat-num" id="paAtrasos">0</span><span class="pa-stat-label">Atrasos</span></div>
                <div class="pa-stat pa-stat-red"><span class="pa-stat-num" id="paAusentes">0</span><span class="pa-stat-label">Ausentes</span></div>
                <div class="pa-stat pa-stat-blue"><span class="pa-stat-num" id="paPendientes">0</span><span class="pa-stat-label">Pendientes</span></div>
            </div>
            <div class="pa-stat-bar"><div class="pa-stat-bar-fill" id="paCoverageBar"></div><span id="paCoverageLabel">0%</span></div>

            <div class="pa-legend">
                <h3>Leyenda de estados</h3>
                <ul>
                    <li><span class="pa-dot pa-dot-green"></span> PRESENTE - A tiempo</li>
                    <li><span class="pa-dot pa-dot-orange"></span> ATRASO - Llego tarde</li>
                    <li><span class="pa-dot pa-dot-red"></span> AUSENTE - No se presento</li>
                    <li><span class="pa-dot pa-dot-blue"></span> PENDIENTE - Sin registrar</li>
                    <li><span class="pa-dot pa-dot-purple"></span> PERMISO / VACACIONES</li>
                </ul>
            </div>

            <div class="pa-quick-actions">
                <?php if ($canRegister): ?><button class="pa-btn pa-btn-outline" id="paMarkAllPresent" type="button">Marcar todos presentes</button><?php endif; ?>
            </div>
        </aside>

        <section class="pa-workspace">
            <div class="pa-empty-board" id="paEmptyBoard"><span>&#9744;</span><strong>Seleccione filtros</strong><p>Elija distrito, turno y fecha para cargar el personal asignado.</p></div>

            <div id="paAttendanceList" hidden>
                <div class="pa-toolbar">
                    <div class="pa-search"><span aria-hidden="true">&#128269;</span><input id="paSearch" type="search" placeholder="Buscar por nombre o cedula..."></div>
                    <div class="pa-batch-info"><span id="paSelectedCount">0</span> seleccionados</div>
                    <?php if ($canRegister): ?><button class="pa-btn pa-btn-primary" id="paSaveBtn" type="button" disabled>Guardar asistencia</button><?php endif; ?>
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
                                <th>Hora llegada</th>
                                <th>Observaciones</th>
                            </tr>
                        </thead>
                        <tbody id="paTableBody"></tbody>
                    </table>
                </div>
            </div>
        </section>
    </div>

    <div id="paToast" class="pa-toast" role="status" aria-live="polite"></div>
</div>
