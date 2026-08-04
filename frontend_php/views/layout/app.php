<?php
use App\Core\AuthSession;
use App\Core\Config;

$usuarioActual = AuthSession::user();
?>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= htmlspecialchars(Config::get('APP_NAME', 'SIGO-GCAM')) ?></title>
    <link rel="stylesheet" href="/assets/css/app.css">
    <?php if (AuthSession::check()): ?><link rel="stylesheet" href="/assets/css/institutional.css"><?php endif; ?>
    <?php foreach (($pageStyles ?? []) as $style): ?>
        <link rel="stylesheet" href="<?= htmlspecialchars($style) ?>">
    <?php endforeach; ?>
</head>
<body>
    <?php if (AuthSession::check()): ?>
        <?php require dirname(__DIR__) . '/components/sidebar.php'; ?>
        <div class="sigo-app" id="sigoApp">
            <?php require dirname(__DIR__) . '/components/topbar.php'; ?>
            <main class="sigo-content">
                <nav class="sigo-breadcrumb" aria-label="Migas de navegación"><a href="/dashboard">Inicio</a><span>›</span><strong><?= htmlspecialchars($title) ?></strong></nav>
                <?php require $viewFile; ?>
            </main>
            <?php require dirname(__DIR__) . '/components/footer.php'; ?>
        </div>
        <div class="sigo-overlay" id="sigoOverlay"></div>
    <?php else: ?>
        <main class="app-shell"><?php require $viewFile; ?></main>
    <?php endif; ?>
    <script src="/assets/js/app.js"></script>
    <?php foreach (($pageScripts ?? []) as $script): ?>
        <script src="<?= htmlspecialchars($script) ?>"></script>
    <?php endforeach; ?>
</body>
</html>
