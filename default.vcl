vcl 4.0;

backend default {
    .host = "backend";
    .port = "8080";
}

sub vcl_recv {
    # Adicione regras para manipulação de cache
    if (req.method == "PURGE") {
        if (client.ip != "127.0.0.1") {
            return (synth(405, "Not allowed."));
        }
        return (purge);
    }

    if (req.url ~ "^/editais") {
        return (pass);
    }
}

sub vcl_backend_response {
    # Adicione cabeçalhos de cache, se necessário
    set beresp.ttl = 10m;
}
