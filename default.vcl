vcl 4.0;

backend default {
    .host = "backend";
    .port = "8080";
}

sub vcl_recv {
    # Permitir PURGE apenas do localhost
    if (req.method == "PURGE") {
        if (client.ip != "127.0.0.1") {
            return (synth(405, "Not allowed."));
        }
        return (purge);
    }

    # Arquivos estáticos: CSS, JS, imagens
    if (req.url ~ "\.(css|js|png|jpe?g|gif|svg|ico|woff2?|ttf)$") {
        return (hash);
    }

    # Forçar não cache para /editais
    if (req.url ~ "^/editais") {
        return (pass);
    }

    # Cache normal para demais requisições
    return (hash);
}


sub vcl_backend_response {
    # Configurar TTL para arquivos estáticos
    if (bereq.url ~ "\.(css|js|png|jpe?g|gif|svg|ico|woff2?|ttf)$") {
        set beresp.ttl = 1h; # Cache de 1 hora
        set beresp.grace = 30m; # Usar cache expirado por até 30 minutos
        return (deliver);
    }

    # Configurar TTL genérico
    set beresp.ttl = 10m;
}

