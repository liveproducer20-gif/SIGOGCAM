(function () {
    'use strict';
    const $ = (sel, root = document) => root.querySelector(sel);
    const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
    if (!$('.dd-app')) return;

    function esc(v) { const n = document.createElement('div'); n.textContent = v ?? ''; return n.innerHTML; }
    function notify(msg, err = false) {
        const t = $('#ddToast'); if (!t) return;
        t.textContent = msg; t.classList.toggle('is-error', err); t.classList.add('is-visible');
        clearTimeout(notify._t); notify._t = setTimeout(() => t.classList.remove('is-visible'), 3500);
    }

    $$('.dd-card-header').forEach(header => {
        header.addEventListener('click', () => {
            const card = header.closest('.dd-card');
            const id = card?.dataset.distId;
            const detail = $(`#ddDetail-${id}`);
            const toggle = $('[data-toggle-dist]', card);
            if (!detail) return;
            const expanded = !detail.hidden;
            detail.hidden = expanded;
            toggle.setAttribute('aria-expanded', String(!expanded));
        });
    });

    const searchInput = $('#ddSearch');
    const filterEstado = $('#ddFilterEstado');
    const filterCobertura = $('#ddFilterCobertura');

    function applyFilters() {
        const query = searchInput?.value?.trim().toLowerCase() || '';
        const estado = filterEstado?.value || '';
        const cobertura = filterCobertura?.value || '';
        $$('.dd-card').forEach(card => {
            const text = card.textContent.toLowerCase();
            const matchesSearch = !query || text.includes(query);
            const id = card.dataset.distId;
            const detail = $(`#ddDetail-${id}`);
            const estadoText = card.querySelector('.dd-status-label')?.textContent?.toUpperCase() || '';
            let matchesEstado = true;
            if (estado === 'COMPLETA') matchesEstado = card.classList.contains('dd-card-complete');
            else if (estado === 'PARCIAL') matchesEstado = card.classList.contains('dd-card-incomplete');
            else if (estado === 'BORRADOR') matchesEstado = text.includes('borrador');
            let matchesCobertura = true;
            if (cobertura === '100') {
                const pct = parseInt(card.querySelector('.dd-card-coverage strong')?.textContent || '0');
                matchesCobertura = pct >= 100;
            } else if (cobertura === 'incomplete') {
                matchesCobertura = card.classList.contains('dd-card-incomplete');
            }
            card.style.display = (matchesSearch && matchesEstado && matchesCobertura) ? '' : 'none';
        });
    }

    searchInput?.addEventListener('input', applyFilters);
    filterEstado?.addEventListener('change', applyFilters);
    filterCobertura?.addEventListener('change', applyFilters);
})();
