<section class="dashboard">
    <header class="topbar">
        <div>
            <h1>Personal</h1>
            <p>Consulta general del personal registrado.</p>
        </div>
        <a class="button-link" href="/dashboard">Volver</a>
    </header>

    <?php if (!empty($error)): ?>
        <div class="alert"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <div class="table-card">
        <table>
            <thead>
                <tr>
                    <th>Nombre</th>
                    <th>Cedula</th>
                    <th>Grupo</th>
                    <th>Rol</th>
                    <th>Estado</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($items as $item): ?>
                    <tr>
                        <td><?= htmlspecialchars($item['nombre_completo'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['cedula'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['grupo'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['rol'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['estado_personal'] ?? '') ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</section>
