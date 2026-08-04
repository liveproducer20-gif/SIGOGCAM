<section class="dashboard">
    <header class="topbar">
        <div>
            <h1>Eventos</h1>
            <p>Gestión de capacitaciones, reuniones y operativos.</p>
        </div>
        <a class="button-link" href="/dashboard">Volver</a>
    </header>

    <?php if (!empty($error)): ?>
        <div class="alert"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <?php if (!empty($success)): ?>
        <div class="success"><?= htmlspecialchars($success) ?></div>
    <?php endif; ?>

    <form class="work-card" method="post" action="/eventos" enctype="multipart/form-data">
        <div class="form-grid">
            <label>Título<input type="text" name="titulo" required></label>
            <label>Tipo de evento
                <select name="tipo_evento_id" required>
                    <option value="">Seleccione</option>
                    <?php foreach (($tipos ?? []) as $tipo): ?>
                        <option value="<?= (int)($tipo['id'] ?? 0) ?>"><?= htmlspecialchars($tipo['nombre'] ?? '') ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label>Fecha inicio<input type="datetime-local" name="fecha_inicio" required></label>
            <label>Fecha fin<input type="datetime-local" name="fecha_fin" required></label>
            <label>Prioridad
                <select name="prioridad">
                    <option>Normal</option>
                    <option>Alta</option>
                    <option>Media</option>
                    <option>Baja</option>
                </select>
            </label>
        </div>
        <label>Lugar<input type="text" name="lugar" required></label>
        <label>Descripción<textarea name="descripcion" rows="4"></textarea></label>
        <div class="form-grid">
            <label>Imagen<input type="file" name="imagen" accept="image/*"></label>
            <label>PDF<input type="file" name="pdf" accept="application/pdf"></label>
        </div>
        <label class="check-row"><input type="checkbox" name="notificar" checked> Notificar</label>
        <button type="submit">Crear evento</button>
    </form>

    <div class="table-card">
        <table>
            <thead>
                <tr>
                    <th>Evento</th>
                    <th>Tipo</th>
                    <th>Fecha</th>
                    <th>Lugar</th>
                    <th>Estado</th>
                    <th>Adjuntos</th>
                    <th>Acción</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($items as $item): ?>
                    <tr>
                        <td><?= htmlspecialchars($item['titulo'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['tipo_evento'] ?? '') ?></td>
                        <td><?= htmlspecialchars((string) ($item['fecha_inicio'] ?? '')) ?></td>
                        <td><?= htmlspecialchars($item['lugar'] ?? '') ?></td>
                        <td><?= htmlspecialchars($item['estado'] ?? '') ?></td>
                        <td>
                            <?php if (!empty($item['imagen_url'])): ?>
                                <details>
                                    <summary>Imagen</summary>
                                    <img class="image-preview" src="<?= htmlspecialchars($item['imagen_url']) ?>" alt="Imagen del evento">
                                </details>
                            <?php endif; ?>
                            <?php if (!empty($item['pdf_url'])): ?>
                                <details>
                                    <summary>PDF</summary>
                                    <iframe class="pdf-preview" src="<?= htmlspecialchars($item['pdf_url']) ?>" title="PDF del evento"></iframe>
                                </details>
                            <?php endif; ?>
                        </td>
                        <td>
                            <form method="post" action="/eventos/eliminar" class="inline-form">
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
