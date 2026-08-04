<footer class="sigo-footer">
    <div><span class="sigo-footer-icon">▥</span><span><strong>Información institucional</strong><small>SIGO · Sistema Inteligente de Gestión Operativa</small></span></div>
    <span><b>Entorno:</b> <?= htmlspecialchars(\App\Core\Config::get('APP_ENV', 'development')) ?></span>
    <span><b>Acceso:</b> <?= date('d/m/Y H:i') ?></span>
    <span><b>IP:</b> <?= htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? '127.0.0.1') ?></span>
    <strong class="sigo-footer-brand">SIGO</strong>
    <small class="sigo-copyright">© <?= date('Y') ?> SIGO · Todos los derechos reservados.</small>
</footer>
