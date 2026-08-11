(function () {
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

    form.addEventListener('submit', (event) => {
        const values = ['encargado_id', 'auxiliar_1_id', 'auxiliar_2_id']
            .map((name) => String(form.elements.namedItem(name).value || ''))
            .filter(Boolean);
        if (new Set(values).size !== values.length) {
            event.preventDefault();
            window.alert('El encargado y los auxiliares deben ser personas diferentes.');
        }
    }, true);

    const viewDialog = document.getElementById('circuitViewDialog');
    const viewFields = [
        ['Distrito', 'distrito'], ['Encargado', 'encargado'], ['Auxiliar 1', 'auxiliar_1'],
        ['Auxiliar 2', 'auxiliar_2'], ['Móvil', 'movil'], ['Hora inicio', 'hora_inicio'],
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
