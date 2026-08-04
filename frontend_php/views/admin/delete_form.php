<form method="post" action="/admin/eliminar" class="inline-form">
    <input type="hidden" name="entity" value="<?= htmlspecialchars($entity) ?>">
    <input type="hidden" name="id" value="<?= (int)$id ?>">
    <button type="submit" class="danger">Desactivar</button>
</form>
