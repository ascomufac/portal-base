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

    # VirtualHostMonster para Plone (/editais)
    if (req.http.host == "www3.ufac.br") {
        set req.url = "/VirtualHostBase/https/www3.ufac.br/editais/VirtualHostRoot" + req.url;
    }

    # Healthcheck
    if (req.url == "/ok") {
        return (pass);
    }

    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    if (req.http.Cookie ~ "__ac|_ZopeId|auth_token|plone.session") {
        return (pass);
    }

    if (req.url ~ "^/(@@|\\+\\+api\\+\\+|login|logout|acl_users)") {
        return (pass);
    }

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
