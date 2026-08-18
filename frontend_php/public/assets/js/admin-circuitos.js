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
                // turnos_ids handled by place dialog checkboxes
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

    const circuitDialog = document.getElementById('circuitDialog');
    const circuitFormId = document.getElementById('circuitFormId');
    const circuitFormTitle = document.getElementById('circuitFormTitle');
    const circuitFormEyebrow = document.getElementById('circuitFormEyebrow');
    const circuitFormSubtitle = document.getElementById('circuitFormSubtitle');

    const district = form.querySelector('select[name="distrito_id"]');
    let currentCircuitId = null;
    const routeLabels = Array.from(form.querySelectorAll('[data-circuit-route-options] [data-district-id]'));
    const updateRoutes = (keepSelection) => {
        const selectedDistrict = String(district.value || '');
        routeLabels.forEach((label) => {
            const matchDistrict = selectedDistrict !== '' && String(label.dataset.districtId) === selectedDistrict;
            const circuitId = Number(label.dataset.circuitId || 0);
            // Hide if: no district selected, wrong district, OR belongs to another circuit
            const isCurrentOrFree = circuitId === 0 || (currentCircuitId !== null && circuitId === currentCircuitId);
            const visible = matchDistrict && isCurrentOrFree;
            label.hidden = !visible;
            if (!visible && !keepSelection) label.querySelector('input').checked = false;
        });
    };

    // EAS handling for Estacion de Accion Segura district
    const ESTACION_DISTRICT_ID = Number(form.dataset.estacionDistrictId || 0);
    const circuitFormNombre = document.getElementById('circuitFormNombre');
    const circuitRouteHint = document.getElementById('circuitRouteHint');
    const easOptions = Array.from(form.querySelectorAll('.circuit-eas-option'));

    function isEstacionDistrict() {
        return Number(district.value) === ESTACION_DISTRICT_ID;
    }

    function toggleEasOptions() {
        const isEstacion = isEstacionDistrict();
        easOptions.forEach((label) => {
            label.hidden = !isEstacion;
        });
        if (circuitRouteHint) {
            circuitRouteHint.textContent = isEstacion
                ? 'Seleccione las Estaciones de Acción que pertenecen a este circuito.'
                : 'Solo se habilitan rutas del distrito seleccionado.';
        }
        if (circuitFormNombre) {
            circuitFormNombre.readOnly = false;
            circuitFormNombre.placeholder = '';
        }
    }



    district.addEventListener('change', () => { toggleEasOptions(); updateRoutes(false); });

    const openCircuitDialog = (payload) => {
        form.reset();
        if (circuitFormId) circuitFormId.value = '';
        currentCircuitId = null;
        // Hide ALL route and EAS labels first
        routeLabels.forEach((label) => { label.hidden = true; label.querySelector('input').checked = false; });
        easOptions.forEach((label) => { label.hidden = true; const cb = label.querySelector('input'); if (cb) cb.checked = false; });

        toggleEasOptions();
        if (payload && payload.id) {
            currentCircuitId = Number(payload.id);
            Object.keys(payload).forEach((key) => {
                const field = form.querySelector(`[name="${key}"]`);
                if (!field) return;
                if (field.type === 'checkbox') field.checked = Boolean(payload[key]);
                else if (field instanceof HTMLSelectElement && field.multiple) {
                    const sel = (payload[key] || []).map(String);
                    Array.from(field.options).forEach((o) => { o.selected = sel.includes(o.value); });
                } else field.value = payload[key] ?? '';
            });
            if (circuitFormId) circuitFormId.value = payload.id;
            if (circuitFormTitle) circuitFormTitle.textContent = 'Editar circuito';
            if (circuitFormEyebrow) circuitFormEyebrow.textContent = 'Editar';
            if (circuitFormSubtitle) circuitFormSubtitle.textContent = 'Actualice la informacion del circuito.';
            toggleEasOptions();
            updateRoutes(true);
            const selected = (payload.ruta_ids || []).map(String);
            routeLabels.forEach((label) => {
                const checkbox = label.querySelector('input');
                checkbox.checked = selected.includes(checkbox.value);
                label.hidden = label.dataset.districtId !== String(payload.distrito_id);
            });
            // Check EAS checkboxes if editing an Estacion circuit
            const selectedEasIds = (payload.eas_ids || []).map(Number);
            easOptions.forEach((label) => {
                const cb = label.querySelector('input');
                if (cb) cb.checked = selectedEasIds.includes(Number(cb.value));
            });
        } else {
            currentCircuitId = null;
            if (circuitFormTitle) circuitFormTitle.textContent = 'Crear circuito';
            if (circuitFormEyebrow) circuitFormEyebrow.textContent = 'Nuevo circuito';
            if (circuitFormSubtitle) circuitFormSubtitle.textContent = 'Organice las rutas y recursos de un circuito operativo.';
        }
        updateRoutes(false);
        if (circuitDialog) circuitDialog.showModal();
    };

    document.querySelector('[data-circuit-create]')?.addEventListener('click', () => openCircuitDialog(null));
    document.getElementById('closeCircuitDialog')?.addEventListener('click', () => circuitDialog?.close());
    document.getElementById('cancelCircuitDialog')?.addEventListener('click', () => circuitDialog?.close());
    circuitDialog?.addEventListener('click', (e) => { if (e.target === circuitDialog) circuitDialog.close(); });

    document.querySelectorAll('[data-circuit-edit]').forEach((button) => {
        button.addEventListener('click', () => {
            const payload = JSON.parse(button.dataset.payload || '{}');
            openCircuitDialog(payload);
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
            const circuitId = Number(button.dataset.id || 0);
            routesForm.elements.namedItem('id').value = circuitId;
            routesForm.querySelector('[data-routes-name]').textContent = button.dataset.name;
            routesForm.querySelectorAll('[data-district-id]').forEach((label) => {
                const matchDistrict = label.dataset.districtId === button.dataset.district;
                const ownerCircuit = Number(label.dataset.circuitId || 0);
                // Show if: matches district AND (unassigned OR belongs to this circuit)
                const visible = matchDistrict && (ownerCircuit === 0 || ownerCircuit === circuitId);
                label.hidden = !visible;
                const checkbox = label.querySelector('input');
                checkbox.checked = selected.includes(checkbox.value);
            });
            routesDialog.showModal();
        });
    });
    routesDialog?.querySelector('[data-dialog-close]')?.addEventListener('click', () => routesDialog.close());
})();
