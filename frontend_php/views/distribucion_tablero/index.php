<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canAssign = $isAdmin || in_array('tablero_distribucion.asignar', $permissions, true);
$canConfig = $isAdmin || in_array('tablero_distribucion.configurar', $permissions, true);
$canClean = $isAdmin || in_array('tablero_distribucion.limpiar', $permissions, true);
?>
<div class="td-app" data-can-assign="<?= $canAssign ? '1' : '0' ?>" data-can-config="<?= $canConfig ? '1' : '0' ?>" data-can-clean="<?= $canClean ? '1' : '0' ?>">
    <main class="td-main">
        <?php if (!empty($error)): ?><div class="td-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

        <section class="td-selectors">
            <div class="td-selector-group">
                <label>Distrito
                    <select id="tdDistrict" required>
                        <option value="">Seleccione distrito</option>
                        <?php foreach (($catalogos['distritos'] ?? []) as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </label>
                <label>Ruta
                    <select id="tdRoute" required disabled>
                        <option value="">Seleccione una ruta</option>
                    </select>
                </label>
                <label>Fecha de servicio
                    <input type="date" id="tdDate" required>
                </label>
                <label>Turno
                    <select id="tdShift" required>
                        <option value="">Seleccione turno</option>
                        <?php foreach (($catalogos['turnos'] ?? []) as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"
                                data-nombre="<?= $esc($item['nombre']) ?>"
                                data-start="<?= $esc(substr((string)$item['hora_inicio'], 0, 5)) ?>"
                                data-end="<?= $esc(substr((string)$item['hora_fin'], 0, 5)) ?>">
                                <?= $esc($item['nombre']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </label>
                <div class="td-selector-actions">
                    <button class="td-btn td-btn-primary" id="tdLoadRoute" type="button">Cargar ruta</button>
                </div>
            </div>
        </section>

        <section class="td-route-info" id="tdRouteInfo" hidden>
            <div class="td-route-header">
                <div class="td-route-title">
                    <h2 id="tdRouteName">—</h2>
                    <span class="td-route-district" id="tdRouteDistrict">—</span>
                </div>
                <div class="td-route-stats" id="tdRouteStats">
                    <div class="td-stat"><span class="td-stat-value" id="tdStatSectores">0</span><span class="td-stat-label">Lugares</span></div>
                    <div class="td-stat"><span class="td-stat-value" id="tdStatRequeridos">0</span><span class="td-stat-label">Requeridos</span></div>
                    <div class="td-stat"><span class="td-stat-value" id="tdStatAsignados">0</span><span class="td-stat-label">Asignados</span></div>
                    <div class="td-stat"><span class="td-stat-value" id="tdStatPendientes">0</span><span class="td-stat-label">Pendientes</span></div>
                    <div class="td-stat td-stat-coverage">
                        <span class="td-stat-value" id="tdStatCobertura">0%</span>
                        <span class="td-stat-label">Cobertura</span>
                        <div class="td-coverage-bar"><div class="td-coverage-fill" id="tdCoverageFill"></div></div>
                    </div>
                </div>
            </div>
            <div class="td-route-actions">
                <?php if ($canConfig): ?>
                    <button class="td-btn td-btn-secondary" id="tdConfigSectors" type="button">Configurar requerimiento</button>
                <?php endif; ?>
                <button class="td-btn td-btn-secondary" id="tdViewSectors" type="button">Ver lugares de servicio</button>
                <?php if ($canAssign): ?>
                    <button class="td-btn td-btn-primary td-btn-icon" id="tdRandomAssign" type="button">
                        <span class="td-icon">🎲</span> Asignacion aleatoria
                    </button>
                <?php endif; ?>
                <?php if ($canClean): ?>
                    <button class="td-btn td-btn-danger" id="tdCleanAssign" type="button">Limpiar asignaciones</button>
                <?php endif; ?>
            </div>
        </section>

        <section class="td-sectors-panel" id="tdSectorsPanel" hidden>
            <div class="td-panel-header">
                <h3>Lugares de servicio</h3>
                <button class="td-btn td-btn-ghost" id="tdCloseSectors" type="button">×</button>
            </div>
            <div class="td-panel-content">
                <div class="td-places-list" id="tdSectorsList"></div>
                <div class="td-personnel-search">
                    <h4>Buscar personal</h4>
                    <input type="text" id="tdPersonnelSearch" placeholder="Nombre o cedula..." class="td-search-input">
                    <div class="td-personnel-results" id="tdPersonnelResults"></div>
                </div>
            </div>
            <div class="td-panel-actions">
                <button class="td-btn td-btn-primary td-btn-icon" id="tdRandomAssignBottom" type="button">
                    <span class="td-icon">🎲</span> Asignacion aleatoria
                </button>
            </div>
        </section>

        <section class="td-assignments-panel" id="tdAssignmentsPanel" hidden>
            <div class="td-panel-header">
                <h3>Asignaciones actuales</h3>
                <button class="td-btn td-btn-ghost" id="tdCloseAssignments" type="button">×</button>
            </div>
            <div class="td-assignments-table" id="tdAssignmentsTable"></div>
        </section>

        <?php if ($canConfig): ?>
        <div class="td-modal" id="tdConfigModal" hidden>
            <div class="td-modal-dialog" role="dialog" aria-modal="true" aria-labelledby="tdConfigTitle">
                <div class="td-modal-header">
                    <div><p>Configuracion</p><h3 id="tdConfigTitle">Requerimiento de personal por sector</h3></div>
                    <button class="td-btn td-btn-ghost" id="tdCloseConfig" type="button">×</button>
                </div>
                <div class="td-modal-body">
                    <div class="td-config-table" id="tdConfigTable"></div>
                </div>
                <div class="td-modal-footer">
                    <button class="td-btn td-btn-ghost" id="tdCancelConfig" type="button">Cancelar</button>
                    <button class="td-btn td-btn-primary" id="tdSaveConfig" type="button">Guardar requerimiento</button>
                </div>
            </div>
        </div>
        <?php endif; ?>

        <div class="td-modal" id="tdSorteoModal" hidden>
            <div class="td-modal-dialog td-modal-wide" role="dialog" aria-modal="true" aria-labelledby="tdSorteoTitle">
                <div class="td-modal-header">
                    <div><p>Vista previa</p><h3 id="tdSorteoTitle">Asignacion aleatoria</h3></div>
                    <button class="td-btn td-btn-ghost" id="tdCloseSorteo" type="button">×</button>
                </div>
                <div class="td-modal-body" id="tdSorteoBody"></div>
                <div class="td-modal-footer">
                    <button class="td-btn td-btn-ghost" id="tdCancelSorteo" type="button">Cancelar</button>
                    <?php if ($canAssign): ?>
                        <button class="td-btn td-btn-secondary" id="tdRetrySorteo" type="button">Volver a sortear</button>
                        <button class="td-btn td-btn-primary" id="tdConfirmSorteo" type="button">Confirmar asignacion</button>
                    <?php endif; ?>
                </div>
            </div>
        </div>

        <div class="td-modal" id="tdInsufficientModal" hidden>
            <div class="td-modal-dialog" role="dialog" aria-modal="true">
                <div class="td-modal-header">
                    <div><p>Personal insuficiente</p><h3>No hay suficiente personal disponible</h3></div>
                    <button class="td-btn td-btn-ghost" id="tdCloseInsufficient" type="button">×</button>
                </div>
                <div class="td-modal-body" id="tdInsufficientBody"></div>
                <div class="td-modal-footer">
                    <button class="td-btn td-btn-ghost" id="tdCancelInsufficient" type="button">Cancelar</button>
                    <button class="td-btn td-btn-primary" id="tdConfirmPartial" type="button">Asignar personal disponible</button>
                </div>
            </div>
        </div>

        <div class="td-toast" id="tdToast" role="status" aria-live="polite"></div>
    </main>

    <script id="tdCatalogs" type="application/json"><?= json_encode($catalogos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?></script>
</div>
