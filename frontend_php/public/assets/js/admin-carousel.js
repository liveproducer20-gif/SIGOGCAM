/**
 * RandomRouteInfoSlider – componente reutilizable de carrusel informativo.
 * Muestra rutas aleatorias con su cantidad de lugares de servicio.
 * Uso: new RandomRouteInfoSlider(containerEl, { routes: [...], title, subtitle })
 */
function RandomRouteInfoSlider(el, opts) {
    if (!el || !opts.routes || !opts.routes.length) return;
    this.el = el;
    this.routes = opts.routes.filter(function (r) { return r.nombre; });
    this.title = opts.title || 'Lugares de servicio por ruta';
    this.subtitle = opts.subtitle || 'Orden aleatorio';
    this.interval = opts.interval || 6000;
    this.currentIndex = 0;
    this.order = this._shuffle();
    this.timer = null;
    this.paused = false;
    this._build();
    this._render();
    this._startAuto();
}

RandomRouteInfoSlider.prototype._shuffle = function () {
    var arr = [];
    for (var i = 0; i < this.routes.length; i++) arr.push(i);
    for (var i = arr.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var tmp = arr[i]; arr[i] = arr[j]; arr[j] = tmp;
    }
    return arr;
};

RandomRouteInfoSlider.prototype._build = function () {
    this.el.innerHTML = '';
    this.el.className = 'rc-slider';

    var header = document.createElement('div');
    header.className = 'rc-header';
    header.innerHTML = '<div><strong class="rc-title">' + this._esc(this.title) + '</strong><span class="rc-subtitle">' + this._esc(this.subtitle) + '</span></div>';
    this.el.appendChild(header);

    var body = document.createElement('div');
    body.className = 'rc-body';

    var prev = document.createElement('button');
    prev.type = 'button';
    prev.className = 'rc-arrow rc-arrow--prev';
    prev.setAttribute('aria-label', 'Anterior');
    prev.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M15 18l-6-6 6-6"/></svg>';
    var self = this;
    prev.addEventListener('click', function () { self._prev(); self._restartAuto(); });
    body.appendChild(prev);

    var slide = document.createElement('div');
    slide.className = 'rc-slide';
    this._slideEl = slide;
    body.appendChild(slide);

    var next = document.createElement('button');
    next.type = 'button';
    next.className = 'rc-arrow rc-arrow--next';
    next.setAttribute('aria-label', 'Siguiente');
    next.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M9 18l6-6-6-6"/></svg>';
    next.addEventListener('click', function () { self._next(); self._restartAuto(); });
    body.appendChild(next);

    this.el.appendChild(body);

    var dots = document.createElement('div');
    dots.className = 'rc-dots';
    this._dotsEl = dots;
    this.el.appendChild(dots);
};

RandomRouteInfoSlider.prototype._render = function () {
    var route = this.routes[this.order[this.currentIndex]];
    var slide = this._slideEl;
    slide.style.opacity = '0';
    var self = this;
    setTimeout(function () {
        slide.innerHTML =
            '<div class="rc-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 13l9 5 9-5"/><path d="M3 18l9 5 9-5"/></svg></div>' +
            '<div class="rc-info"><span class="rc-route-name">' + self._esc(route.nombre) + '</span><span class="rc-route-count">' + (route.lugares || 0) + ' lugar' + (route.lugares !== 1 ? 'es' : '') + ' de servicio</span></div>';
        slide.style.opacity = '1';
    }, 150);
    this._renderDots();
};

RandomRouteInfoSlider.prototype._renderDots = function () {
    var dots = this._dotsEl;
    dots.innerHTML = '';
    var count = Math.min(this.routes.length, 8);
    for (var i = 0; i < count; i++) {
        var dot = document.createElement('button');
        dot.type = 'button';
        dot.className = 'rc-dot' + (i === this.currentIndex ? ' rc-dot--active' : '');
        dot.setAttribute('aria-label', 'Ruta ' + (i + 1));
        dot.dataset.index = i;
        var self = this;
        dot.addEventListener('click', (function (idx) {
            return function () { self.currentIndex = idx; self._render(); self._restartAuto(); };
        })(i));
        dots.appendChild(dot);
    }
};

RandomRouteInfoSlider.prototype._next = function () {
    this.currentIndex = (this.currentIndex + 1) % this.routes.length;
    this._render();
};

RandomRouteInfoSlider.prototype._prev = function () {
    this.currentIndex = (this.currentIndex - 1 + this.routes.length) % this.routes.length;
    this._render();
};

RandomRouteInfoSlider.prototype._startAuto = function () {
    this._stopAuto();
    var self = this;
    this.timer = setInterval(function () {
        if (!self.paused) self._next();
    }, this.interval);
};

RandomRouteInfoSlider.prototype._stopAuto = function () {
    if (this.timer) { clearInterval(this.timer); this.timer = null; }
};

RandomRouteInfoSlider.prototype._restartAuto = function () {
    this._stopAuto();
    this._startAuto();
};

RandomRouteInfoSlider.prototype._esc = function (s) {
    var d = document.createElement('div');
    d.textContent = s || '';
    return d.innerHTML;
};

// Pause on hover
RandomRouteInfoSlider.prototype._initHover = function () {
    var self = this;
    this.el.addEventListener('mouseenter', function () { self.paused = true; });
    this.el.addEventListener('mouseleave', function () { self.paused = false; });
};
