<section class="login-page">
<div class="login-container">
    <div class="login-left">
        <div class="brand-bg-shapes">
            <span class="shape shape-1"></span>
            <span class="shape shape-2"></span>
            <span class="shape shape-3"></span>
            <span class="shape shape-dots"></span>
        </div>
        <div class="brand-content">
            <div class="brand-logo">
                <img src="/assets/img/logo_sigo_gcam.png" alt="SIGO" />
            </div>
            <h1 class="brand-name">SIGO</h1>
            <p class="brand-subtitle">Sistema Inteligente de Gesti&oacute;n Operativa</p>
            <div class="brand-divider">
                <span class="brand-line"></span>
                <span class="brand-star">&#9733;</span>
                <span class="brand-line"></span>
            </div>
            <p class="brand-motto">Lealtad, Valor y Orden</p>
        </div>
        <div class="brand-welcome">
            <div class="brand-welcome-icon">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
            </div>
            <div class="brand-welcome-text">
                <strong>Bienvenido Agente</strong>
                <p>Accede al sistema para continuar gestionando operaciones de forma segura y eficiente.</p>
            </div>
        </div>
    </div>

    <div class="login-panel login-right">
        <form class="login-card" method="post" action="/login">
            <div class="login-header">
                <h2>Iniciar sesi&oacute;n</h2>
                <p>Ingrese sus credenciales institucionales.</p>
            </div>

            <?php if (!empty($error)): ?>
                <div class="login-alert"><?= htmlspecialchars($error) ?></div>
            <?php endif; ?>

            <div class="login-field">
                <label for="correo">Correo institucional</label>
                <div class="login-input-wrap">
                    <span class="login-input-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>
                    </span>
                    <input type="email" id="correo" name="correo" placeholder="usuario@institucion.gob.ec" required autofocus>
                </div>
            </div>

            <div class="login-field">
                <label for="password">Contrase&ntilde;a</label>
                <div class="login-input-wrap">
                    <span class="login-input-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                    </span>
                    <input type="password" id="password" name="password" placeholder="Ingrese su contrase&ntilde;a" required>
                    <button type="button" class="login-toggle-pass" id="togglePass" aria-label="Mostrar contrase&ntilde;a">
                        <svg class="eye-open" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                        <svg class="eye-closed" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" style="display:none"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                    </button>
                </div>
            </div>

            <a href="#" class="login-forgot">Olvid&oacute; su contrase&ntilde;a?</a>

            <button type="submit" class="login-submit">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                Ingresar
            </button>

            <div class="login-separator">
                <span>ACCESO INSTITUCIONAL</span>
            </div>

            <div class="login-notice">
                <div class="login-notice-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>
                </div>
                <div class="login-notice-text">
                    Uso exclusivo para personal autorizado.<br>
                    Sistema monitoreado y auditado.
                </div>
            </div>
        </form>
    </div>
</div>
</section>

<script>
(function(){
    var btn = document.getElementById('togglePass');
    var inp = document.getElementById('password');
    if(btn && inp){
        btn.addEventListener('click', function(){
            var isPass = inp.type === 'password';
            inp.type = isPass ? 'text' : 'password';
            btn.querySelector('.eye-open').style.display = isPass ? 'none' : '';
            btn.querySelector('.eye-closed').style.display = isPass ? '' : 'none';
        });
    }
})();
</script>
