<section class="dashboard">
    <header class="topbar">
        <div>
            <h1>Anuncios</h1>
            <p>Publicaciones internas y novedades institucionales.</p>
        </div>
        <a class="button-link" href="/dashboard">Volver</a>
    </header>

    <?php if (!empty($error)): ?>
        <div class="alert"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <?php if (!empty($success)): ?>
        <div class="success"><?= htmlspecialchars($success) ?></div>
    <?php endif; ?>

    <form class="work-card" method="post" action="/anuncios" enctype="multipart/form-data">
        <div class="form-grid">
            <label>Título<input type="text" name="titulo" required></label>
            <label>Prioridad
                <select name="prioridad">
                    <option>Normal</option>
                    <option>Alta</option>
                    <option>Media</option>
                    <option>Baja</option>
                </select>
            </label>
        </div>
        <label>Descripción<textarea name="descripcion" rows="5" required></textarea></label>
        <label>Imagen<input type="file" name="imagen" accept="image/*"></label>
        <label class="check-row"><input type="checkbox" name="publicado" checked> Publicado</label>
        <label class="check-row"><input type="checkbox" name="notificar" checked> Notificar</label>
        <button type="submit">Crear anuncio</button>
    </form>

    <div class="table-card">
        <table>
            <thead>
                <tr>
                    <th>Título</th>
                    <th>Prioridad</th>
                    <th>Publicado</th>
                    <th>Fecha</th>
                    <th>Adjunto</th>
                    <th>Acción</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($items as $item): ?>
                    <tr>
                        <td><?= htmlspecialchars($item['titulo'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['prioridad'] ?? '') ?></td>
                        <td><?= !empty($item['publicado']) ? 'Sí' : 'No' ?></td>
                        <td><?= htmlspecialchars((string) ($item['fecha_publicacion'] ?? '')) ?></td>
                        <td>
                            <?php if (!empty($item['imagen_url'])): ?>
                                <details>
                                    <summary>Imagen</summary>
                                    <img class="image-preview" src="<?= htmlspecialchars($item['imagen_url']) ?>" alt="Imagen del anuncio">
                                </details>
                            <?php endif; ?>
                        </td>
                        <td>
                            <form method="post" action="/anuncios/eliminar" class="inline-form">
                                <input type="hidden" name="id" value="<?= (int)($item['id'] ?? 0) ?>">
                                <button type="submit" class="danger">Eliminar</button>
                            </form>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</section>
