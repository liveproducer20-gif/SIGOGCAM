(function () {
    [
        ['routeImportDialog', '/admin?tab=rutas'],
        ['servicePlaceImportDialog', '/admin?tab=lugares'],
        ['circuitRouteImportPreviewDialog', '/admin?tab=circuitos'],
    ].forEach(([dialogId, returnUrl]) => {
        const dialog = document.getElementById(dialogId);
        if (!dialog) return;
        dialog.showModal();
        dialog.querySelector('[data-import-close]')?.addEventListener('click', () => {
            dialog.close();
            window.location.assign(returnUrl);
        });
    });

    const circuitImportStart = document.getElementById('circuitRouteImportStartDialog');
    document.querySelector('[data-circuit-import-open]')?.addEventListener('click', () => circuitImportStart?.showModal());
    circuitImportStart?.querySelectorAll('[data-circuit-import-close]').forEach((button) => {
        button.addEventListener('click', () => circuitImportStart.close());
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

    const placeForm = document.getElementById('form-lugar');
    if (placeForm) {
        const placesList = document.getElementById('lugares-list');
        const addPlaceButton = document.getElementById('add-lugar');
        const formTitle = placeForm.querySelector('.admin-form-title h3');
        const submitButton = placeForm.querySelector('[data-place-submit]');
        const primaryNameInput = placesList.querySelector('input[name="nombre[]"]');
        const setValue = (name, value) => {
            const field = placeForm.elements.namedItem(name);
            if (field) field.value = value ?? '';
        };
        primaryNameInput?.addEventListener('input', () => {
            if (primaryNameInput.dataset.syncDirection === '1') setValue('direccion', primaryNameInput.value);
        });

        document.querySelectorAll('[data-edit-service-place]').forEach((button) => {
            button.addEventListener('click', () => {
                const payload = JSON.parse(button.dataset.payload || '{}');
                Array.from(placesList.querySelectorAll('.lugar-row')).slice(1).forEach((row) => row.remove());
                const nameInput = placesList.querySelector('input[name="nombre[]"]');
                if (nameInput) nameInput.value = payload.nombre || payload.direccion || '';
                if (nameInput) nameInput.dataset.syncDirection = (!payload.direccion || payload.direccion === payload.nombre) ? '1' : '0';

                setValue('id', payload.id);
                setValue('direccion', payload.direccion || payload.nombre || '');
                setValue('distrito_id', payload.distrito_id);
                placeForm.elements.namedItem('distrito_id')?.dispatchEvent(new Event('change'));
                setValue('ruta_id', payload.ruta_id);
                setValue('tipo_servicio_id', payload.tipo_servicio_id);
                setValue('turno_id', payload.turno_id);
                setValue('cantidad_requerida', payload.cantidad_requerida || 1);
                setValue('ubicacion_especifica', payload.ubicacion_especifica);
                setValue('estado_operativo', payload.estado_operativo || 'ACTIVO');
                setValue('consignas', payload.consignas);
                setValue('observacion', payload.observacion);
                setValue('lugar_formacion', payload.lugar_formacion);
                setValue('latitud', payload.latitud);
                setValue('longitud', payload.longitud);
                setValue('activo', payload.activo ? '1' : '0');

                if (formTitle) formTitle.textContent = 'Editar lugar de servicio';
                if (submitButton) submitButton.textContent = 'Guardar cambios';
                if (addPlaceButton) addPlaceButton.hidden = true;
                placeForm.scrollIntoView({ behavior: 'smooth', block: 'start' });
                nameInput?.focus({ preventScroll: true });
            });
        });

        placeForm.addEventListener('reset', () => setTimeout(() => {
            Array.from(placesList.querySelectorAll('.lugar-row')).slice(1).forEach((row) => row.remove());
            if (formTitle) formTitle.textContent = 'Nuevo lugar';
            if (submitButton) submitButton.textContent = 'Guardar lugares';
            if (addPlaceButton) addPlaceButton.hidden = false;
            if (primaryNameInput) primaryNameInput.dataset.syncDirection = '1';
        }));
    }

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
