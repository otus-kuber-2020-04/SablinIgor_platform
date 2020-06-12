pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "otus"
        }
    }

    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

template {
    destination = "/vault/secrets/index.html"
    contents = <<EOT
    <html>
    <body>
    <p>Some secrets:</p>
    {{- with secret "otus/otus-ro/config" }}
    <ul>
    <li><pre>username: {{ .Data.username }}</pre></li>
    <li><pre>password: {{ .Data.password }}</pre></li>
    </ul>
    {{ end }}
    </body>
    </html>
    EOT
}
vault {
      address = "http://vault:8200"
}

exit_after_auth = true