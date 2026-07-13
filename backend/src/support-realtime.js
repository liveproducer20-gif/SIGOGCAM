const clients = new Set();

function subscribe(req, res) {
    res.status(200);
    res.set({
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        Connection: 'keep-alive',
        'X-Accel-Buffering': 'no'
    });
    res.flushHeaders?.();
    const client = { res, userId: Number(req.user.id), admin: req.user.rol === 'ADMINISTRADOR' };
    clients.add(client);
    res.write(`event: connected\ndata: ${JSON.stringify({ ok: true })}\n\n`);

    const keepAlive = setInterval(() => res.write(': keep-alive\n\n'), 25000);
    req.on('close', () => {
        clearInterval(keepAlive);
        clients.delete(client);
    });
}

function publish(type, ticket) {
    const payload = `event: ${type}\ndata: ${JSON.stringify(ticket)}\n\n`;
    for (const client of clients) {
        if (client.admin || client.userId === Number(ticket.usuario_id)) {
            try { client.res.write(payload); } catch (_) { clients.delete(client); }
        }
    }
}

module.exports = { subscribe, publish };

