<section class="page-header">
    <div>
        <p class="eyebrow">Cuenta</p>
        <h1>Mi perfil</h1>
    </div>
    <a class="button secondary" href="/dashboard">Volver</a>
</section>

<?php if ($error): ?>
    <div class="alert error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<section class="profile-card">
    <div class="avatar"><?= htmlspecialchars(strtoupper(substr($profile['nombre_completo'] ?? $profile['nombreCompleto'] ?? 'U', 0, 1))) ?></div>
    <div>
        <h2><?= htmlspecialchars($profile['nombre_completo'] ?? $profile['nombreCompleto'] ?? 'Usuario') ?></h2>
        <p><?= htmlspecialchars($profile['correo_institucional'] ?? $profile['correo'] ?? '') ?></p>
        <dl>
            <dt>Cédula</dt><dd><?= htmlspecialchars($profile['cedula'] ?? '') ?></dd>
            <dt>Cargo</dt><dd><?= htmlspecialchars($profile['cargo'] ?? '') ?></dd>
            <dt>Área</dt><dd><?= htmlspecialchars($profile['area'] ?? '') ?></dd>
            <dt>Grupo</dt><dd><?= htmlspecialchars($profile['grupo'] ?? '') ?></dd>
            <dt>Rol</dt><dd><?= htmlspecialchars($profile['rol'] ?? '') ?></dd>
        </dl>
    </div>
</section>
