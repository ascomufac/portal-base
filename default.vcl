vcl 4.0;

backend default {
    .host = "backend";
    .port = "8080";
}

sub vcl_recv {
    # Forçar X-Forwarded-Proto para HTTPS
    if (req.http.X-Forwarded-Proto) {
        set req.http.X-Forwarded-Proto = "https";
    } else {
        add req.http.X-Forwarded-Proto = "https";
    }

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

    # Não cache requisições não GET/HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }
    
    # Não cache usuários autenticados
    if (req.http.Cookie ~ "(auth|__ac|_ZopeId)") {
        return (pass);
    }

    # Cache normal para demais requisições
    return (hash);
}


sub vcl_backend_response {
    if (bereq.url ~ "\.(css|js|png|jpe?g|gif|svg|ico|woff2?|ttf)$") {
        set beresp.ttl = 1h;
        set beresp.grace = 30m;
        return (deliver);
    }

    # Não cache páginas com Set-Cookie
    if (beresp.http.Set-Cookie) {
        set beresp.ttl = 0s;
        return (deliver);
    }

    # TTL padrão para HTML e JSON
    if (beresp.http.Content-Type ~ "text/html" || beresp.http.Content-Type ~ "application/json") {
        set beresp.ttl = 5m;
        set beresp.grace = 10m;
    }

    return (deliver);
}

sub vcl_hit {
    if (obj.ttl >= 0s) {
        return (deliver);
    }
    if (obj.ttl + obj.grace > 0s) {
        return (deliver);
    }
    return (miss);
}

sub vcl_miss {
    return (fetch);
}

