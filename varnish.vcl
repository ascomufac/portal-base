vcl 4.1;

backend default {
    .host = "backend";
    .port = "8080";
    .connect_timeout = 5s;
    .first_byte_timeout = 300s;
    .between_bytes_timeout = 60s;
}

############################
# REQUEST
############################
sub vcl_recv {

    # Saúde
    if (req.url == "/ok") {
        return (pass);
    }

    # Apenas GET e HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Nunca cache para usuários logados
    if (req.http.Cookie ~ "__ac|_ZopeId|auth_token|plone.session") {
        return (pass);
    }

    # Admin, API, login → sempre pass
    if (req.url ~ "^/(@@|\\+\\+api\\+\\+|login|logout|acl_users|plone_control_panel)") {
        return (pass);
    }

    # WebDAV, edição, REST
    if (req.url ~ "(@@edit|@@manage|@@sharing)") {
        return (pass);
    }

    # Remove cookies para anônimos
    unset req.http.Cookie;

    return (hash);
}

############################
# BACKEND RESPONSE
############################
sub vcl_backend_response {

    # Não cache erros
    if (beresp.status != 200) {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # TTL padrão
    set beresp.ttl = 10m;
    set beresp.grace = 30m;

    # Permite cache público
    unset beresp.http.Set-Cookie;

    # Gzip já tratado pelo Traefik
}

############################
# RESPONSE
############################
sub vcl_deliver {

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Debug opcional
    set resp.http.X-Cache-Hits = obj.hits;
}
