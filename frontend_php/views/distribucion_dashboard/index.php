<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$dists = $distributions['distribuciones'] ?? [];
$totalDists = count($dists);
$completas = count(array_filter($dists, fn($d) => $d['es_completa']));
$incompletas = $totalDists - $completas;
$totalAgentes = array_sum(array_column($dists, 'total_asignado'));
$totalRequerido = array_sum(array_column($dists, 'total_requerido'));
$promedioCobertura = $totalRequerido > 0 ? round($totalAgentes / $totalRequerido * 100) : 0;
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
        <article class="dd-kpi-card">
            <div class="dd-kpi-icon dd-kpi-teal">&#9632;</div>
            <div><strong><?= $totalDists ?></strong><b>Distribuciones</b><small>Total registradas</small></div>
        </article>
        <article class="dd-kpi-card">
            <div class="dd-kpi-icon dd-kpi-green">&#10003;</div>
            <div><strong><?= $completas ?></strong><b>Completas</b><small>Sin pendientes</small></div>
        </article>
        <article class="dd-kpi-card">
            <div class="dd-kpi-icon dd-kpi-orange">&#9888;</div>
            <div><strong><?= $incompletas ?></strong><b>Incompletas</b><small>Con lugares vacios</small></div>
        </article>
        <article class="dd-kpi-card">
            <div class="dd-kpi-icon dd-kpi-blue">&#9823;</div>
            <div><strong><?= $totalAgentes ?>/<?= $totalRequerido ?></strong><b>Agentes</b><small>Asignados / Requeridos</small></div>
        </article>
        <article class="dd-kpi-card">
            <div class="dd-kpi-icon dd-kpi-purple">&#9711;</div>
            <div><strong><?= $promedioCobertura ?>%</strong><b>Cobertura</b><small>Promedio general</small></div>
        </article>
    </div>

    <section class="dd-filters">
        <label class="dd-search-label">
            <span>&#128269;</span>
            <input id="ddSearch" type="search" placeholder="Buscar por nombre, distrito o turno...">
        </label>
        <select id="ddFilterEstado">
            <option value="">Todos los estados</option>
            <option value="COMPLETA">Completas</option>
            <option value="PARCIAL">Parciales</option>
            <option value="BORRADOR">Borradores</option>
        </select>
        <select id="ddFilterCobertura">
            <option value="">Toda cobertura</option>
            <option value="100">100% cobertura</option>
            <option value="incomplete">Incompletas</option>
        </select>
    </section>

    <div class="dd-list" id="ddList">
        <?php if (empty($dists)): ?>
            <div class="dd-empty">
                <span>&#9632;</span>
                <strong>No hay distribuciones guardadas</strong>
                <p>Cree distribuciones desde el Tablero de Distribucion.</p>
            </div>
        <?php else: ?>
            <?php foreach ($dists as $dist): ?>
                <article class="dd-card <?= $dist['es_completa'] ? 'dd-card-complete' : 'dd-card-incomplete' ?>" data-dist-id="<?= (int)$dist['id'] ?>">
                    <div class="dd-card-header">
                        <div class="dd-card-status">
                            <span class="dd-status-dot <?= $dist['es_completa'] ? 'dd-dot-green' : 'dd-dot-orange' ?>"></span>
                            <span class="dd-status-label"><?= $dist['es_completa'] ? 'Completa' : 'Incompleta' ?></span>
                        </div>
                        <div class="dd-card-title">
                            <h3><?= $esc($dist['nombre']) ?></h3>
                            <small><?= $esc($dist['distrito']) ?> &middot; <?= $esc($dist['turno']) ?> &middot; <?= $esc($dist['fecha_distribucion'] ?? '') ?></small>
                        </div>
                        <div class="dd-card-coverage">
                            <strong><?= round($dist['porcentaje_cobertura']) ?>%</strong>
                            <small>Cobertura</small>
                        </div>
                        <button class="dd-card-toggle" type="button" data-toggle-dist="<?= (int)$dist['id'] ?>" aria-expanded="false">&#9660;</button>
                    </div>
                    <div class="dd-card-bar">
                        <div class="dd-bar-fill" style="width:<?= min(100, round($dist['porcentaje_cobertura'])) ?>%"></div>
                    </div>
                    <div class="dd-card-summary">
                        <span><b><?= $dist['total_asignado'] ?></b> asignados</span>
                        <span><b><?= $dist['pendientes'] ?></b> pendientes</span>
                        <span><b><?= $dist['total_rutas'] ?></b> rutas</span>
                        <span><b><?= $dist['rutas_completas'] ?>/<?= $dist['total_rutas'] ?></b> rutas completas</span>
                    </div>
                    <div class="dd-card-detail" id="ddDetail-<?= (int)$dist['id'] ?>" hidden>
                        <?php if (!empty($dist['lugares_pendientes'])): ?>
                            <div class="dd-missing-header">&#9888; Lugares sin personal asignado:</div>
                            <table class="dd-missing-table">
                                <thead><tr><th>Ruta</th><th>Lugar de servicio</th><th>Requerido</th></tr></thead>
                                <tbody>
                                <?php foreach ($dist['lugares_pendientes'] as $pend): ?>
                                    <tr>
                                        <td><?= $esc($pend['ruta']) ?></td>
                                        <td><?= $esc($pend['lugar']) ?></td>
                                        <td><?= (int)$pend['requerido'] ?></td>
                                    </tr>
                                <?php endforeach; ?>
                                </tbody>
                            </table>
                        <?php else: ?>
                            <div class="dd-all-assigned">&#10003; Todos los lugares tienen personal asignado.</div>
                        <?php endif; ?>
                        <?php if (!empty($dist['rutas'])): ?>
                            <div class="dd-routes-summary">
                                <b>Detalle por ruta:</b>
                                <?php foreach ($dist['rutas'] as $ruta): ?>
                                    <div class="dd-route-row">
                                        <span class="dd-route-name"><?= $esc($ruta['ruta']) ?></span>
                                        <span class="dd-route-stat <?= $ruta['pendiente'] > 0 ? 'dd-stat-warn' : 'dd-stat-ok' ?>">
                                            <?= $ruta['asignado'] ?>/<?= $ruta['requerido'] ?> agentes
                                        </span>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        <?php endif; ?>
                    </div>
                </article>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

    <div class="td-toast" id="ddToast" role="status" aria-live="polite"></div>
</div>
