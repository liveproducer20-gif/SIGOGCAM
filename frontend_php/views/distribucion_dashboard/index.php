<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$dists = $distributions['distribuciones'] ?? [];
$totalGroups = count($dists);
$totalDists = array_sum(array_column($dists, 'total_distritos'));
$completas = array_sum(array_column($dists, 'distritos_completos'));
$incompletas = $totalDists - $completas;
$totalAgentes = array_sum(array_column($dists, 'total_asignado'));
$totalRequerido = array_sum(array_column($dists, 'total_requerido'));
$promedioCobertura = $totalRequerido > 0 ? round($totalAgentes / $totalRequerido * 100) : 0;
$permissions = $usuario['permisos'] ?? [];
$isAdmin = str_contains(strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? '')), 'ADMINISTRADOR');
$canDelete = $isAdmin || in_array('tablero_distribucion.eliminar', $permissions, true);
?>
<div class="dd-app">
    <?php if (!empty($error)): ?><div class="td-alert" role="alert"><?= $esc($error) ?></div><?php endif; ?>

    <header class="td-page-head">
        <div class="td-page-title">
            <span class="td-title-icon" aria-hidden="true">&#9632;</span>
            <div><h1>Dashboard de Distribuciones</h1><p>Estado de las distribuciones de personal guardadas</p></div>
        </div>
    </header>

    <div class="dd-kpis">
        <article class="dd-kpi-card"><div class="dd-kpi-icon dd-kpi-teal">&#9632;</div><div><strong><?= $totalGroups ?></strong><b>Distribuciones</b><small>Registradas</small></div></article>
        <article class="dd-kpi-card"><div class="dd-kpi-icon dd-kpi-green">&#10003;</div><div><strong><?= $completas ?>/<?= $totalDists ?></strong><b>Distritos</b><small>Completos</small></div></article>
        <article class="dd-kpi-card"><div class="dd-kpi-icon dd-kpi-orange">&#9888;</div><div><strong><?= $incompletas ?></strong><b>Pendientes</b><small>Distritos incompletos</small></div></article>
        <article class="dd-kpi-card"><div class="dd-kpi-icon dd-kpi-blue">&#9823;</div><div><strong><?= $totalAgentes ?>/<?= $totalRequerido ?></strong><b>Agentes</b><small>Asignados / Requeridos</small></div></article>
        <article class="dd-kpi-card"><div class="dd-kpi-icon dd-kpi-purple">&#9711;</div><div><strong><?= $promedioCobertura ?>%</strong><b>Cobertura</b><small>Promedio general</small></div></article>
    </div>

    <section class="dd-filters">
        <label class="dd-search-label"><span>&#128269;</span><input id="ddSearch" type="search" placeholder="Buscar por fecha, turno o distrito..."></label>
        <select id="ddFilterEstado"><option value="">Todos los estados</option><option value="completa">Completas</option><option value="incompleta">Incompletas</option></select>
    </section>

    <div class="dd-list" id="ddList">
        <?php if (empty($dists)): ?>
            <div class="dd-empty"><span>&#9632;</span><strong>No hay distribuciones guardadas</strong><p>Cree distribuciones desde el Tablero de Distribucion.</p></div>
        <?php else: ?>
            <?php foreach ($dists as $group): ?>
                <?php
                    $allComplete = $group['es_completa'];
                    $groupKey = $group['fecha_distribucion'] . '_' . $group['turno_id'];
                ?>
                <article class="dd-card <?= $allComplete ? 'dd-card-complete' : 'dd-card-incomplete' ?>" data-group-key="<?= $esc($groupKey) ?>">
                    <div class="dd-card-header" data-toggle-group="<?= $esc($groupKey) ?>">
                        <div class="dd-card-status">
                            <span class="dd-status-dot <?= $allComplete ? 'dd-dot-green' : 'dd-dot-orange' ?>"></span>
                            <span class="dd-status-label"><?= $allComplete ? 'Completa' : 'Incompleta' ?></span>
                        </div>
                        <div class="dd-card-title">
                            <h3><?= $esc($group['nombre']) ?></h3>
                            <small>Turno: <?= $esc($group['turno']) ?> &middot; <?= $esc($group['fecha_distribucion'] ?? '') ?> &middot; Creado por <?= $esc($group['creado_por'] ?? '') ?></small>
                        </div>
                        <div class="dd-card-coverage">
                            <strong><?= $group['porcentaje_cobertura'] ?>%</strong>
                            <small>Cobertura</small>
                        </div>
                        <div class="dd-card-actions">
                            <button class="dd-card-pdf" type="button" data-pdf-group="<?= $esc($groupKey) ?>" title="Generar PDF de esta distribución"><span aria-hidden="true">&#128196;</span> PDF</button>
                            <?php if ($canDelete): ?><button class="dd-card-delete" type="button" data-delete-group='<?= json_encode(["fecha" => $group["fecha_distribucion"], "turno_id" => $group["turno_id"]], JSON_HEX_APOS) ?>' title="Eliminar distribución"><span aria-hidden="true">&#128465;</span> Eliminar</button><?php endif; ?>
                        </div>
                        <button class="dd-card-toggle" type="button" data-toggle-dist="<?= $esc($groupKey) ?>" aria-expanded="false">&#9660;</button>
                    </div>
                    <div class="dd-card-bar"><div class="dd-bar-fill" style="width:<?= min(100, $group['porcentaje_cobertura']) ?>%"></div></div>
                    <div class="dd-card-summary">
                        <span><b><?= $group['total_asignado'] ?></b> asignados</span>
                        <span><b><?= $group['pendientes'] ?></b> pendientes</span>
                        <span><b><?= $group['total_distritos'] ?></b> distritos</span>
                        <span><b><?= $group['distritos_completos'] ?>/<?= $group['total_distritos'] ?></b> completos</span>
                    </div>
                    <div class="dd-card-detail" id="ddDetail-<?= $esc($groupKey) ?>" hidden>
                        <table class="dd-district-table">
                            <thead><tr><th>Distrito</th><th>Estado</th><th>Requerido</th><th>Asignado</th><th>Cobertura</th><th>Accion</th></tr></thead>
                            <tbody>
                            <?php foreach ($group['distritos'] as $d): ?>
                                <tr>
                                    <td><b><?= $esc($d['distrito']) ?></b></td>
                                    <td><span class="dd-chip <?= $d['es_completa'] ? 'dd-chip-green' : 'dd-chip-orange' ?>"><?= $d['es_completa'] ? 'Completo' : 'Incompleto' ?></span></td>
                                    <td><?= $d['total_requerido'] ?></td>
                                    <td><?= $d['total_asignado'] ?></td>
                                    <td><?= $d['porcentaje_cobertura'] ?>%</td>
                                    <td>
                                        <?php if ($d['es_completa']): ?>
                                            <span class="dd-done-label">&#10003; Asignado</span>
                                        <?php else: ?>
                                            <a class="dd-btn-distribuir" href="/distribucion-tablero?distrito_id=<?= $d['distrito_id'] ?>&turno_id=<?= $group['turno_id'] ?>">Distribuir</a>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </article>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

    <div class="td-toast" id="ddToast" role="status" aria-live="polite"></div>

    <?php foreach ($dists as $group): $groupKey = $group['fecha_distribucion'] . '_' . $group['turno_id']; ?>
        <section class="dd-print-section" id="ddPrint-<?= $esc($groupKey) ?>" aria-hidden="true">
            <div class="dd-print-header"><h1>SIGO - Sistema Inteligente de Gestión Operativa</h1><h2>Distribución de Personal</h2><p>Fecha: <?= $esc($group['fecha_distribucion']) ?> · Turno: <?= $esc($group['turno']) ?> · Estado: <?= $group['es_completa'] ? 'COMPLETA' : 'INCOMPLETA' ?></p></div>
            <?php foreach ($group['distritos'] as $d): ?>
                <section class="dd-print-district">
                    <h2><?= $esc($d['distrito']) ?> <small><?= $d['es_completa'] ? 'COMPLETO' : 'INCOMPLETO' ?> · <?= $d['porcentaje_cobertura'] ?>%</small></h2>
                    <?php foreach (($d['rutas'] ?? []) as $route): ?>
                        <h3><?= $esc($route['ruta']) ?></h3>
                        <table class="dd-print-table"><thead><tr><th>Lugar de servicio</th><th>Agente</th><th>Hora ingreso</th><th>Hora salida</th><th>Consignas</th><th>Observaciones</th></tr></thead><tbody>
                        <?php foreach (($route['filas'] ?? []) as $row): ?><tr><td><?= $esc($row['lugar']) ?></td><td><?= $esc($row['agente']) ?></td><td><?= $esc($row['hora_ingreso'] ? substr((string)$row['hora_ingreso'], 0, 5) : '—') ?></td><td><?= $esc($row['hora_salida'] ? substr((string)$row['hora_salida'], 0, 5) : '—') ?></td><td><?= $esc($row['consignas']) ?></td><td><?= $esc($row['observaciones']) ?></td></tr><?php endforeach; ?>
                        </tbody></table>
                    <?php endforeach; ?>
                </section>
            <?php endforeach; ?>
            <div class="dd-print-footer"><p>Distritos completos: <?= $group['distritos_completos'] ?>/<?= $group['total_distritos'] ?> · Agentes asignados: <?= $group['total_asignado'] ?>/<?= $group['total_requerido'] ?> · Cobertura: <?= $group['porcentaje_cobertura'] ?>%</p></div>
        </section>
    <?php endforeach; ?>
</div>
