(function () {
    const dragList = document.getElementById('menuDragList');
    if (dragList) {
        let dragged = null;
        dragList.querySelectorAll('.drag-row').forEach((row) => {
            row.addEventListener('dragstart', () => {
                dragged = row;
                row.classList.add('is-dragging');
            });
            row.addEventListener('dragend', () => {
                row.classList.remove('is-dragging');
                dragged = null;
                renumberRows(dragList);
            });
            row.addEventListener('dragover', (event) => {
                event.preventDefault();
                const target = event.currentTarget;
                if (!dragged || dragged === target) return;
                const rect = target.getBoundingClientRect();
                const before = event.clientY < rect.top + rect.height / 2;
                dragList.insertBefore(dragged, before ? target : target.nextSibling);
            });
        });
    }

    document.querySelectorAll('[data-edit-target]').forEach((button) => {
        button.addEventListener('click', () => {
            const target = document.querySelector(button.dataset.editTarget);
            if (!target) return;
            const payload = JSON.parse(button.dataset.payload || '{}');
            Object.keys(payload).forEach((key) => {
                const field = target.querySelector(`[name="${key}"]`);
                if (!field) return;
                if (field.type === 'checkbox') {
                    field.checked = Boolean(payload[key]);
                } else if (field instanceof HTMLSelectElement && field.multiple) {
                    const selected = (payload[key] || []).map(String);
                    Array.from(field.options).forEach((option) => { option.selected = selected.includes(option.value); });
                } else {
                    field.value = payload[key] ?? '';
                }
            });
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
    });

    function renumberRows(list) {
        list.querySelectorAll('.drag-row').forEach((row, index) => {
            const input = row.querySelector('.order-input');
            if (input) input.value = String(index + 1);
        });
    }

    const sidebar = document.getElementById('sigoSidebar');
    const sigoApp = document.getElementById('sigoApp');
    const menuButton = document.getElementById('sigoMenuButton');
    const overlay = document.getElementById('sigoOverlay');

    document.querySelectorAll('[data-nav-group] > button').forEach((button) => {
        button.addEventListener('click', () => {
            const group = button.closest('[data-nav-group]');
            const open = !group.classList.contains('is-open');
            group.classList.toggle('is-open', open);
            button.setAttribute('aria-expanded', String(open));
        });
    });

    if (menuButton && sidebar && sigoApp) {
        menuButton.addEventListener('click', () => {
            if (window.matchMedia('(max-width: 900px)').matches) {
                sidebar.classList.toggle('mobile-open');
                overlay?.classList.toggle('is-visible', sidebar.classList.contains('mobile-open'));
                return;
            }
            sidebar.classList.toggle('is-collapsed');
            sigoApp.classList.toggle('sidebar-collapsed');
        });
        overlay?.addEventListener('click', () => {
            sidebar.classList.remove('mobile-open');
            overlay.classList.remove('is-visible');
        });
    }

    document.querySelectorAll('.inline-form').forEach((form) => {
        const danger = form.querySelector('button.danger');
        if (!danger) return;
        form.addEventListener('submit', (event) => {
            if (!window.confirm('Esta acción cambiará el estado del registro. ¿Desea continuar?')) {
                event.preventDefault();
                event.stopImmediatePropagation();
            }
        });
    });

    document.querySelectorAll('form[method="post"]').forEach((form) => {
        form.addEventListener('submit', () => {
            const submit = form.querySelector('button[type="submit"]');
            if (!submit || submit.disabled) return;
            submit.dataset.originalText = submit.textContent;
            submit.textContent = 'Procesando…';
            submit.disabled = true;
        });
    });

    document.querySelectorAll('.table-card table, .table-wrap table').forEach((table, tableIndex) => {
        if (table.dataset.enhanced === 'true') return;
        table.dataset.enhanced = 'true';
        const body = table.tBodies[0];
        if (!body) return;
        const rows = Array.from(body.rows);
        if (!rows.length) {
            const columns = Math.max(1, table.tHead?.rows[0]?.cells.length || 1);
            body.innerHTML = `<tr><td colspan="${columns}" class="empty-state">No existen registros para mostrar.</td></tr>`;
            return;
        }
        const container = table.closest('.table-card, .table-wrap');
        const controls = document.createElement('div');
        controls.className = 'table-controls';
        controls.innerHTML = `<label>Mostrar <select aria-label="Cantidad de registros"><option>10</option><option>25</option><option>50</option></select></label><label class="table-search">Buscar <input type="search" aria-label="Buscar en tabla" placeholder="Escriba para filtrar…"></label><span class="table-counter"></span><span class="table-pagination"><button type="button" aria-label="Página anterior">‹</button><button type="button" aria-label="Página siguiente">›</button></span>`;
        container.insertBefore(controls, table);
        if (table.closest('.admin-workspace')) {
            const exports = document.createElement('span');
            exports.className = 'table-exports';
            exports.innerHTML = '<button type="button" data-export="csv">CSV</button><button type="button" data-export="xls">Excel</button><button type="button" data-export="print">PDF / Imprimir</button>';
            controls.appendChild(exports);
            exports.addEventListener('click', (event) => {
                const button = event.target.closest('[data-export]');
                if (!button) return;
                if (button.dataset.export === 'print') {
                    window.print();
                    return;
                }
                const separator = button.dataset.export === 'xls' ? '\t' : ',';
                const extension = button.dataset.export === 'xls' ? 'xls' : 'csv';
                const escapeCell = (value) => {
                    const clean = value.replace(/\s+/g, ' ').trim();
                    return separator === ',' ? `"${clean.replace(/"/g, '""')}"` : clean.replace(/\t/g, ' ');
                };
                const lines = [];
                if (table.tHead) lines.push(Array.from(table.tHead.rows[0].cells).slice(0, -1).map((cell) => escapeCell(cell.textContent)).join(separator));
                rows.forEach((row) => lines.push(Array.from(row.cells).slice(0, -1).map((cell) => escapeCell(cell.textContent)).join(separator)));
                const blob = new Blob(['\ufeff' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8' });
                const link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = `sigo-administracion-${new Date().toISOString().slice(0, 10)}.${extension}`;
                link.click();
                URL.revokeObjectURL(link.href);
            });
        }
        const search = controls.querySelector('input');
        const amount = controls.querySelector('select');
        const counter = controls.querySelector('.table-counter');
        const [previous, next] = controls.querySelectorAll('.table-pagination button');
        const searchCols = table.hasAttribute('data-search-cols')
            ? table.getAttribute('data-search-cols').split(',').map(Number)
            : null;
        let page = 0;
        const render = () => {
            const term = search.value.trim().toLowerCase();
            const filtered = rows.filter((row) => {
                if (searchCols) {
                    return searchCols.some((ci) => {
                        const cell = row.cells[ci];
                        return cell && cell.textContent.toLowerCase().includes(term);
                    });
                }
                return row.textContent.toLowerCase().includes(term);
            });
            const size = Number(amount.value);
            const pages = Math.max(1, Math.ceil(filtered.length / size));
            page = Math.min(page, pages - 1);
            const start = page * size;
            rows.forEach((row) => { row.hidden = true; });
            filtered.slice(start, start + size).forEach((row) => { row.hidden = false; });
            counter.textContent = filtered.length ? `${start + 1}–${Math.min(start + size, filtered.length)} de ${filtered.length}` : '0 registros';
            previous.disabled = page === 0;
            next.disabled = page >= pages - 1;
        };
        search.addEventListener('input', () => { page = 0; render(); });
        amount.addEventListener('change', () => { page = 0; render(); });
        previous.addEventListener('click', () => { page = Math.max(0, page - 1); render(); });
        next.addEventListener('click', () => { page += 1; render(); });
        render();
    });

    document.addEventListener('keydown', (event) => {
        if (event.key !== 'Escape') return;
        document.querySelectorAll('.geo-modal:not([hidden]) [data-close-wizard]').forEach((button) => button.click());
        sidebar?.classList.remove('mobile-open');
        overlay?.classList.remove('is-visible');
    });

    const cardForm = document.getElementById('cartillaForm');
    const cardOutput = document.querySelector('.cartilla-preview textarea[name="contenido"]');
    if (cardForm && cardOutput) {
        let manual = cardOutput.value.trim() !== '';
        cardOutput.addEventListener('input', () => { manual = true; });
        const value = (name) => cardForm.elements.namedItem(name)?.value?.trim() || '';
        const greet = () => {
            const h = new Date().getHours();
            if (h >= 6 && h < 12) return 'buenos días';
            if (h >= 12 && h < 19) return 'buenas tardes';
            return 'buenas noches';
        };
        const procedureByCause = (cause, address) => {
            const base = `Muy ${greet()}, Sr. Maldonado Cabrera Freddy, Jefe de Control Municipal, muy respetuosamente me permito informarle que`;
            const c = (cause || '').toLowerCase();
            const l = address ? ` en la dirección ${address}` : '';
            if (c.includes('desalojo')) return `${base} durante el recorrido preventivo se evidenció la presencia de vendedores ocupando el espacio público${l}, por lo que se procedió a dialogar de manera respetuosa, indicando la normativa vigente y solicitando el retiro voluntario del lugar. La intervención se desarrolló sin novedades adicionales, manteniendo presencia preventiva en el sector.`;
            if (c.includes('retiro')) return `${base} se realizó el retiro temporal correspondiente${l}, verificando previamente las condiciones del sitio y coordinando la actuación de forma ordenada para precautelar la seguridad ciudadana y el uso adecuado del espacio público.`;
            if (c.includes('requerimiento')) return `${base} se atendió un requerimiento ciudadano/institucional${l}, tomando contacto con las partes involucradas y brindando la colaboración operativa necesaria conforme a las competencias del Cuerpo de Agentes de Control Municipal.`;
            if (c.includes('ronda')) return `${base} se ejecutaron rondas disuasivas${l}, manteniendo presencia preventiva, verificando puntos sensibles y observando el normal desarrollo de las actividades en el sector asignado.`;
            if (c.includes('entidades')) return `${base} se brindó colaboración operativa a otras entidades${l}, acompañando el procedimiento solicitado y manteniendo presencia institucional hasta la culminación de la novedad, sin registrarse incidentes adicionales.`;
            if (c.includes('ciudadana')) return `${base} se brindó colaboración ciudadana${l}, orientando a la persona requirente y realizando las gestiones operativas necesarias dentro del ámbito de competencia institucional.`;
            if (c.includes('accidente')) return `${base} se tomó conocimiento de un accidente${l}, verificando la situación en territorio y precautelando el área mientras se coordinaba la atención correspondiente con las entidades competentes. Se mantuvo presencia preventiva hasta normalizar la novedad.`;
            if (c.includes('robo')) return `${base} se tomó conocimiento de una alerta relacionada con presunto robo${l}, por lo que se mantuvo presencia preventiva, se verificó la novedad y se orientó a la persona afectada para la coordinación con las entidades competentes.`;
            if (c.includes('extorsi')) return `${base} se recibió información relacionada con una presunta extorsión${l}, manteniendo reserva y orientando a la persona involucrada sobre la canalización correspondiente con las autoridades competentes.`;
            if (c.includes('amenaza')) return `${base} se atendió una novedad por amenazas${l}, brindando acompañamiento preventivo y recomendando a la persona afectada formalizar la denuncia respectiva ante la entidad competente.`;
            if (c.includes('desapar')) return `${base} se tomó conocimiento sobre la presunta desaparición de una persona${l}, por lo que se orientó a los ciudadanos respecto al procedimiento correspondiente y se dejó constancia de la novedad para fines pertinentes.`;
            if (c.includes('agresi')) return `${base} se verificó una novedad relacionada con agresión${l}, manteniendo presencia preventiva, procurando separar a las partes involucradas y coordinando la atención correspondiente según la situación observada.`;
            if (c.includes('cámara') || c.includes('camara')) return `${base} se realizó visualización de cámaras relacionada con la novedad reportada${l}, revisando la información disponible y dejando constancia de los detalles relevantes para conocimiento superior.`;
            if (c.includes('ausent')) return `${base} se registra permiso de ausentismo del servidor correspondiente, dejando constancia de la novedad para conocimiento superior y fines administrativos.`;
            if (c.includes('martillo')) return `${base} durante el servicio asignado se mantuvo presencia preventiva${l}, verificando el orden en el sector y realizando acciones disuasivas conforme a las disposiciones operativas.`;
            return `${base} durante el servicio establecido se verificó la novedad correspondiente a ${cause}${l}.`;
        };
        const renderCard = () => {
            if (manual) return;
            const now = new Date();
            const tipo = value('tipo_servicio').toUpperCase();
            const tipoC = value('tipo_cartilla');
            const cause = value('causa');
            const detail = value('detalle');
            const address = value('direccion');
            const movil = value('movil');
            const cp = value('cp');
            const jp = value('jp');
            const policia = value('policia');
            const cedula = value('cedula_ultimos_4');
            const disco = value('numero_disco');
            const kilometraje = value('kilometraje');
            const esConductor = tipo === 'CONDUCTOR';
            let texto = '*CUERPO DE AGENTES DE CONTROL MUNICIPAL*\n\n';
            texto += `*REPORTE DE ${tipoC ? tipoC.toUpperCase() : tipo}*\n`;
            texto += `*DISTRITO:* ${value('distrito').toUpperCase()}\n`;
            texto += `*CIRCUITO:* ${value('circuito') || value('eas_nombre') || 'EAS'}\n`;
            texto += `*HORARIO:* ${value('horario') || 'POR DEFINIR'}\n`;
            texto += `*HORA:* ${now.toLocaleTimeString('es-EC',{hour:'2-digit',minute:'2-digit'})}\n`;
            texto += `*FECHA:* ${now.toLocaleDateString('es-EC')}\n`;
            texto += `*DIRECCIÓN:* ${address}\n\n`;
            texto += `*CAUSA:* ${cause}\n\n`;
            texto += '*PROCEDIMIENTO:*\n\n';
            let procedimiento = procedureByCause(cause, address);
            if (!cause.toLowerCase().includes('ausent') && address) {
                procedimiento += ` Se procedió con punto martillo en la calle ${address}.`;
            }
            texto += procedimiento + '\n\n';
            texto += 'Notifico novedades para fines correspondientes.\n';
            if (esConductor) {
                if (kilometraje) texto += `\n*Kilometraje:* ${kilometraje}`;
                if (disco) texto += `\n*Disco:* ${disco}`;
                if (cedula) texto += `\n*Cédula últimos 4:* ${cedula}`;
            }
            if (movil) texto += `\n*Móvil ${movil}*`;
            texto += '\n\n*REPORTA:*\n\n';
            texto += `*CP:* ${cp}\n`;
            texto += `*JP:* ${jp}`;
            if (policia) texto += `\n*POLICÍA:* ${policia}`;
            texto += '\n\n*Lealtad, Valor y Orden*\n\n';
            texto += 'Adjunto fotografía';
            cardOutput.value = texto;
        };
        cardForm.addEventListener('input', renderCard);
        cardForm.addEventListener('change', renderCard);
        renderCard();
        document.querySelector('[data-copy-cartilla]')?.addEventListener('click', async () => { await navigator.clipboard.writeText(cardOutput.value); });
        document.querySelector('[data-share-cartilla]')?.addEventListener('click', async () => {
            if (navigator.share) await navigator.share({title:'Cartilla SIGO',text:cardOutput.value});
            else await navigator.clipboard.writeText(cardOutput.value);
        });
    }
    document.querySelector('[data-share-achievements]')?.addEventListener('click', async () => {
        const text = Array.from(document.querySelectorAll('.badge-stats .stat')).map((card) => `${card.querySelector('span')?.textContent}: ${card.querySelector('strong')?.textContent}`).join(' · ');
        if (navigator.share) await navigator.share({ title: 'Mis insignias SIGO', text });
        else await navigator.clipboard.writeText(text);
    });
})();
