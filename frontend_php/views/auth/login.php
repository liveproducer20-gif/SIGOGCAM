<section class="login-page">
    <div class="brand-panel">
        <h1>SIGO-GCAM</h1>
        <p>Sistema Inteligente de Gestión Operativa</p>
        <span>Lealtad, Valor y Orden</span>
    </div>

    <form class="login-card" method="post" action="/login">
        <h2>Iniciar sesión</h2>
        <p>Ingrese sus credenciales institucionales.</p>

        <?php if (!empty($error)): ?>
            <div class="alert"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>

        <label>
            Correo institucional
            <input type="email" name="correo" required autofocus>
        </label>

        <label>
            Contraseña
            <input type="password" name="password" required>
        </label>

        <button type="submit">Ingresar</button>
    </form>
</section>
