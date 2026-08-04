<?php
$badges = $progress['insignias'] ?? [];
?>
<section class="page-header">
    <div>
        <p class="eyebrow">Rendimiento</p>
        <h1>Mis insignias</h1>
    </div>
    <a class="button secondary" href="/dashboard">Volver</a>
</section>

<?php if ($error): ?>
    <div class="alert error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<section class="stats-grid">
    <article class="stat"><span>Total cartillas</span><strong><?= (int)($progress['total_cartillas_generadas'] ?? 0) ?></strong></article>
    <article class="stat"><span>Desbloqueadas</span><strong><?= (int)($progress['desbloqueadas'] ?? 0) ?></strong></article>
    <article class="stat"><span>Pendientes</span><strong><?= (int)($progress['pendientes'] ?? 0) ?></strong></article>
</section>

<section class="content-grid">
    <div>
        <h2>Progreso de insignias</h2>
        <div class="badge-grid">
            <?php foreach ($badges as $badge): ?>
                <article class="badge-card <?= !empty($badge['desbloqueada']) ? 'is-open' : '' ?>">
                    <strong><?= htmlspecialchars($badge['titulo'] ?? '') ?></strong>
                    <span><?= htmlspecialchars((string)($badge['meta_cartillas'] ?? 0)) ?> cartillas</span>
                    <progress max="100" value="<?= htmlspecialchars((string)($badge['porcentaje'] ?? 0)) ?>"></progress>
                </article>
            <?php endforeach; ?>
        </div>
    </div>
    <aside>
        <h2>Ranking</h2>
        <div class="table-wrap compact">
            <table>
                <thead><tr><th>#</th><th>Servidor</th><th>Cartillas</th></tr></thead>
                <tbody>
                <?php foreach ($ranking as $row): ?>
                    <tr>
                        <td><?= (int)($row['posicion'] ?? 0) ?></td>
                        <td><?= htmlspecialchars($row['nombre_completo'] ?? '') ?></td>
                        <td><?= (int)($row['total_cartillas_generadas'] ?? 0) ?></td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </aside>
</section>
