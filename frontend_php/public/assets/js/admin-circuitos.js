(function () {
    [
        ['routeImportDialog', '/admin?tab=rutas'],
        ['servicePlaceImportDialog', '/admin?tab=lugares'],
    ].forEach(([dialogId, returnUrl]) => {
        const dialog = document.getElementById(dialogId);
        if (!dialog) return;
        dialog.showModal();
        dialog.querySelector('[data-import-close]')?.addEventListener('click', () => {
            dialog.close();
            window.location.assign(returnUrl);
        });
    });

    document.querySelectorAll('.csv-toggle-detail').forEach((button) => {
        button.addEventListener('click', () => {
            const row = document.getElementById(button.dataset.target || '');
            if (!row) return;
            const isVisible = !row.hidden;
            row.hidden = isVisible;
            button.textContent = button.hasAttribute('data-toggle-text')
                ? (isVisible ? 'Detalle' : 'Ocultar')
                : (isVisible ? '▼' : '▲');
            button.setAttribute('aria-expanded', String(!isVisible));
        });
    });

    const bulkDeleteButton = document.querySelector('[data-bulk-delete-places]');
    const bulkDeleteDialog = document.getElementById('bulkDeletePlacesDialog');
    if (bulkDeleteButton && bulkDeleteDialog) {
        const routeSelect = document.querySelector('[data-table-filter="admin-places-table"][data-filter-attribute="route"]');
        const circuitSelect = document.querySelector('[data-table-filter="admin-places-table"][data-filter-attribute="circuit"]');
        const deleteForm = bulkDeleteDialog.querySelector('form');
        const routeInput = deleteForm.elements.namedItem('ruta_id');
        const circuitInput = deleteForm.elements.namedItem('circuito_id');

        bulkDeleteButton.addEventListener('click', () => {
            const routeId = routeSelect?.value || '';
            const circuitId = circuitSelect?.value || '';
            const byRoute = routeId !== '' && routeId !== '__empty__';
            const byCircuit = !byRoute && circuitId !== '' && circuitId !== '__empty__';
            if (!byRoute && !byCircuit) {
                window.alert('Seleccione una ruta o un circuito antes de eliminar lugares.');
                return;
            }

            const attribute = byRoute ? 'route' : 'circuit';
            const value = byRoute ? routeId : circuitId;
            const scopeSelect = byRoute ? routeSelect : circuitSelect;
            const count = Array.from(document.querySelectorAll('#admin-places-table tbody tr'))
                .filter((row) => row.dataset[attribute] === value).length;
            if (count === 0) {
                window.alert('No existen lugares para eliminar en la selección indicada.');
                return;
            }

            routeInput.value = byRoute ? routeId : '';
            circuitInput.value = byCircuit ? circuitId : '';
            bulkDeleteDialog.querySelector('[data-bulk-delete-count]').textContent = String(count);
            bulkDeleteDialog.querySelector('[data-bulk-delete-scope]').textContent =
                `${byRoute ? 'la ruta' : 'el circuito'} “${scopeSelect.options[scopeSelect.selectedIndex].text}”`;
            bulkDeleteDialog.showModal();
        });

        bulkDeleteDialog.querySelectorAll('[data-bulk-delete-close]').forEach((button) => {
            button.addEventListener('click', () => bulkDeleteDialog.close());
        });
    }

    const form = document.getElementById('form-circuito');
    if (!form) return;

    const district = form.elements.namedItem('distrito_id');
    const routeLabels = Array.from(form.querySelectorAll('[data-circuit-route-options] [data-district-id]'));
    const updateRoutes = (keepSelection) => {
        const selectedDistrict = String(district.value || '');
        routeLabels.forEach((label) => {
            const visible = selectedDistrict !== '' && label.dataset.districtId === selectedDistrict;
            label.hidden = !visible;
            if (!visible && !keepSelection) label.querySelector('input').checked = false;
        });
    };
    district.addEventListener('change', () => updateRoutes(false));

    document.querySelector('[data-circuit-create]')?.addEventListener('click', () => {
        form.reset();
        form.elements.namedItem('id').value = '';
        form.querySelector('[data-circuit-form-title]').textContent = 'Nuevo circuito';
        form.hidden = false;
        updateRoutes(false);
        form.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
    form.querySelector('[data-circuit-cancel]')?.addEventListener('click', () => { form.hidden = true; });

    document.querySelectorAll('[data-circuit-edit]').forEach((button) => {
        button.addEventListener('click', () => {
            const payload = JSON.parse(button.dataset.payload || '{}');
            form.hidden = false;
            form.querySelector('[data-circuit-form-title]').textContent = 'Editar circuito';
            updateRoutes(true);
            const selected = (payload.ruta_ids || []).map(String);
            routeLabels.forEach((label) => {
                const checkbox = label.querySelector('input');
                checkbox.checked = selected.includes(checkbox.value);
                label.hidden = label.dataset.districtId !== String(payload.distrito_id);
            });
        });
    });

    const viewDialog = document.getElementById('circuitViewDialog');
    const viewFields = [
        ['Distrito', 'distrito'], ['Hora inicio', 'hora_inicio'],
        ['Hora fin', 'hora_fin'], ['Lugar de formación', 'lugar_formacion'], ['Rutas', 'rutas'],
        ['Consignas', 'consignas'], ['Observaciones', 'observaciones'], ['Perímetro', 'perimetro'],
    ];
    document.querySelectorAll('[data-circuit-view]').forEach((button) => {
        button.addEventListener('click', () => {
            const payload = JSON.parse(button.dataset.payload || '{}');
            viewDialog.querySelector('[data-view-name]').textContent = payload.nombre || 'Circuito';
            const content = viewDialog.querySelector('[data-circuit-view-content]');
            content.replaceChildren();
            viewFields.forEach(([label, key]) => {
                const dt = document.createElement('dt');
                const dd = document.createElement('dd');
                dt.textContent = label;
                dd.textContent = payload[key] || '—';
                content.append(dt, dd);
            });
            viewDialog.showModal();
        });
    });

    const routesDialog = document.getElementById('circuitRoutesDialog');
    const routesForm = document.getElementById('circuitRoutesForm');
    document.querySelectorAll('[data-circuit-routes]').forEach((button) => {
        button.addEventListener('click', () => {
            const selected = (button.dataset.routes || '').split(',').filter(Boolean);
            routesForm.elements.namedItem('id').value = button.dataset.id;
            routesForm.querySelector('[data-routes-name]').textContent = button.dataset.name;
            routesForm.querySelectorAll('[data-district-id]').forEach((label) => {
                label.hidden = label.dataset.districtId !== button.dataset.district;
                const checkbox = label.querySelector('input');
                checkbox.checked = selected.includes(checkbox.value);
            });
            routesDialog.showModal();
        });
    });
    routesDialog.querySelector('[data-dialog-close]')?.addEventListener('click', () => routesDialog.close());
})();
