<section class="page-header">
    <div>
        <p class="eyebrow">Atención interna</p>
        <h1>Alertas / Soporte</h1>
    </div>
    <a class="button secondary" href="/dashboard">Volver</a>
</section>

<?php if ($message): ?>
    <div class="alert"><?= htmlspecialchars($message) ?></div>
<?php endif; ?>
<?php if ($error): ?>
    <div class="alert error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<section class="stats-grid">
    <article class="stat"><span>Total</span><strong><?= (int)($stats['total'] ?? 0) ?></strong></article>
    <article class="stat"><span>Nuevas</span><strong><?= (int)($stats['nuevos'] ?? 0) ?></strong></article>
    <article class="stat"><span>En proceso</span><strong><?= (int)($stats['en_proceso'] ?? 0) ?></strong></article>
    <article class="stat"><span>Resueltas</span><strong><?= (int)($stats['resueltos'] ?? 0) ?></strong></article>
</section>

<section class="split-panel">
    <form method="post" action="/soporte" class="form-panel">
        <h2>Nueva alerta</h2>
        <label>Título <input name="titulo" required minlength="3"></label>
        <label>Módulo <input name="modulo" value="Plataforma" required></label>
        <label>Prioridad
            <select name="prioridad">
                <option>Media</option>
                <option>Alta</option>
                <option>Baja</option>
                <option>Crítica</option>
            </select>
        </label>
        <label>Descripción <textarea name="descripcion" required rows="5"></textarea></label>
        <button class="button" type="submit">Registrar alerta</button>
    </form>

    <div class="table-wrap">
        <table>
            <thead><tr><th>Código</th><th>Título</th><th>Módulo</th><th>Prioridad</th><th>Estado</th></tr></thead>
            <tbody>
            <?php foreach ($tickets as $ticket): ?>
                <tr>
                    <td><?= htmlspecialchars($ticket['codigo_alerta'] ?? '') ?></td>
                    <td><?= htmlspecialchars($ticket['titulo'] ?? '') ?></td>
                    <td><?= htmlspecialchars($ticket['modulo'] ?? '') ?></td>
                    <td><?= htmlspecialchars($ticket['prioridad'] ?? '') ?></td>
                    <td><span class="pill"><?= htmlspecialchars($ticket['estado'] ?? '') ?></span></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</section>
