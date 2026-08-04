<?php
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$sidebarPermissions = $usuarioActual['permisos'] ?? [];
$sidebarRoleName = strtoupper((string)($usuarioActual['rolNombre'] ?? $usuarioActual['rol'] ?? ''));
$sidebarIsAdministrator = str_contains($sidebarRoleName, 'ADMINISTRADOR');
$sidebarCan = static function (array $required) use ($sidebarPermissions, $sidebarIsAdministrator): bool {
    if ($sidebarIsAdministrator) return true;
    foreach ($required as $permission) {
        if (in_array($permission, $sidebarPermissions, true)) return true;
    }
    return false;
};
$active = static fn(array $routes): string => in_array($path, $routes, true) ? ' is-active' : '';
$open = static fn(array $routes): string => in_array($path, $routes, true) ? ' is-open' : '';
?>
<aside class="sigo-sidebar" id="sigoSidebar" aria-label="Navegación principal">
    <a class="sigo-logo" href="/dashboard">
        <span class="sigo-logo-mark"><i>★</i></span>
        <span><strong>SIGO</strong><small>Sistema Inteligente de<br>Gestión Operativa</small></span>
    </a>
    <nav class="sigo-navigation">
        <a class="sigo-nav-link<?= $active(['/dashboard']) ?>" href="/dashboard"><span class="sigo-nav-icon">▣</span><span>Panel principal</span><b>›</b></a>
        <p class="sigo-nav-label">Módulos</p>

        <?php if ($sidebarCan(['administracion.ver', 'personal.ver', 'catalogos.ver'])): ?>
        <section class="sigo-nav-group<?= $open(['/admin', '/personal']) ?>" data-nav-group>
            <button type="button" aria-expanded="<?= in_array($path, ['/admin', '/personal'], true) ? 'true' : 'false' ?>"><span class="sigo-nav-icon">♙</span><span>Administración</span><b>⌄</b></button>
            <div class="sigo-submenu">
                <?php if ($sidebarCan(['personal.ver'])): ?><a class="<?= $active(['/personal']) ?>" href="/personal">Personal</a><?php endif; ?>
                <?php if ($sidebarCan(['catalogos.ver'])): ?><a href="/admin?tab=catalogos">Catálogos</a><?php endif; ?>
                <?php if ($sidebarCan(['roles.ver', 'permisos.ver'])): ?><a href="/configuracion">Roles y permisos</a><?php endif; ?>
                <?php if ($sidebarCan(['lugares_servicio.ver'])): ?><a href="/admin?tab=lugares">Lugares de servicio</a><?php endif; ?>
                <?php if ($sidebarCan(['rutas.ver'])): ?><a href="/admin?tab=rutas">Rutas</a><?php endif; ?>
                <?php if ($sidebarCan(['personal.ver'])): ?><a href="/admin?tab=grados">Grados</a><?php endif; ?>
                <?php if ($sidebarCan(['eas.ver'])): ?><a href="/admin?tab=eas">EAS</a><?php endif; ?>
                <?php if ($sidebarCan(['moviles.ver'])): ?><a href="/admin?tab=moviles">Móviles</a><?php endif; ?>
                <?php if ($sidebarCan(['moviles.asignar'])): ?><a href="/admin?tab=asignaciones">Asignaciones móvil–EAS</a><?php endif; ?>
                <?php if ($sidebarCan(['moviles.ver'])): ?><a href="/admin?tab=mantenimiento">Mantenimiento</a><?php endif; ?>
            </div>
        </section>
        <?php endif; ?>

        <?php if ($sidebarCan(['distribucion.ver'])): ?>
        <section class="sigo-nav-group<?= $open(['/distribucion-geografica', '/distribucion-tablero']) ?>" data-nav-group>
            <button type="button" aria-expanded="<?= in_array($path, ['/distribucion-geografica', '/distribucion-tablero'], true) ? 'true' : 'false' ?>"><span class="sigo-nav-icon">⌖</span><span>Distribución</span><b>⌄</b></button>
            <div class="sigo-submenu">
                <a class="<?= $active(['/distribucion-geografica']) ?>" href="/distribucion-geografica">Distribución geográfica</a>
                <a class="<?= $active(['/distribucion-tablero']) ?>" href="/distribucion-tablero">Tablero de distribución</a>
            </div>
        </section>
        <?php endif; ?>

        <?php if ($sidebarCan(['eventos.ver', 'anuncios.ver', 'eventos.crear'])): ?>
        <section class="sigo-nav-group<?= $open(['/eventos', '/anuncios']) ?>" data-nav-group>
            <button type="button" aria-expanded="<?= in_array($path, ['/eventos', '/anuncios'], true) ? 'true' : 'false' ?>"><span class="sigo-nav-icon">▧</span><span>Eventos y anuncios</span><b>⌄</b></button>
            <div class="sigo-submenu"><a class="<?= $active(['/eventos']) ?>" href="/eventos">Eventos</a><a class="<?= $active(['/anuncios']) ?>" href="/anuncios">Anuncios</a></div>
        </section>
        <?php endif; ?>

        <?php if ($sidebarCan(['cartillas.ver', 'cartillas.generar'])): ?><a class="sigo-nav-link<?= $active(['/cartillas']) ?>" href="/cartillas"><span class="sigo-nav-icon">▤</span><span>Cartillas</span><b>›</b></a><?php endif; ?>
        <?php if ($sidebarCan(['insignias.ver', 'cartillas.ver'])): ?><a class="sigo-nav-link<?= $active(['/insignias']) ?>" href="/insignias"><span class="sigo-nav-icon">♜</span><span>Insignias</span><b>›</b></a><?php endif; ?>
        <?php if ($sidebarCan(['soporte.ver', 'soporte.crear'])): ?><a class="sigo-nav-link<?= $active(['/soporte']) ?>" href="/soporte"><span class="sigo-nav-icon">♧</span><span>Alertas / Soporte</span><b>›</b></a><?php endif; ?>
        <?php if ($sidebarCan(['configuracion.ver', 'roles.ver', 'permisos.ver'])): ?><a class="sigo-nav-link<?= $active(['/configuracion']) ?>" href="/configuracion"><span class="sigo-nav-icon">⚙</span><span>Configuración</span><b>›</b></a><?php endif; ?>
    </nav>
    <div class="sigo-sidebar-art" aria-hidden="true"><span>★</span></div>
    <a class="sigo-user-mini" href="/perfil"><i><?= htmlspecialchars(strtoupper(substr((string)($usuarioActual['nombres'] ?? 'U'), 0, 1) . substr((string)($usuarioActual['apellidos'] ?? ''), 0, 1))) ?></i><span><strong><?= htmlspecialchars($usuarioActual['nombreCompleto'] ?? 'Usuario SIGO') ?></strong><small>Rol: <?= htmlspecialchars($usuarioActual['rolNombre'] ?? $usuarioActual['rol'] ?? '') ?></small></span><b>⌄</b></a>
</aside>
