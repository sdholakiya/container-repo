resource "kubernetes_pod" "multi_container_pod" {
  metadata {
    name      = var.pod_name
    namespace = var.namespace
    labels = {
      app = "multi-container-app"
    }
  }

  spec {
    # Frontend container
    container {
      name  = "frontend"
      image = var.container_image_frontend

      port {
        container_port = 80
      }

      volume_mount {
        name       = "shared-data"
        mount_path = "/shared-data"
      }

      resources {
        limits = {
          cpu    = "0.5"
          memory = "512Mi"
        }
        requests = {
          cpu    = "0.2"
          memory = "256Mi"
        }
      }

      env {
        name  = "BACKEND_SERVICE"
        value = "localhost:8080"
      }
    }

    # Backend container
    container {
      name  = "backend"
      image = var.container_image_backend

      command = ["/bin/sh", "-c"]
      args    = ["python -m http.server 8080"]

      port {
        container_port = 8080
      }

      volume_mount {
        name       = "shared-data"
        mount_path = "/shared-data"
      }

      volume_mount {
        name       = "logs"
        mount_path = "/logs"
      }

      resources {
        limits = {
          cpu    = "0.5"
          memory = "512Mi"
        }
        requests = {
          cpu    = "0.3"
          memory = "384Mi"
        }
      }
    }

    # Logger container
    container {
      name  = "logger"
      image = var.container_image_logger

      volume_mount {
        name       = "logs"
        mount_path = "/fluentd/log"
      }

      volume_mount {
        name       = "config"
        mount_path = "/fluentd/etc"
      }

      resources {
        limits = {
          cpu    = "0.3"
          memory = "256Mi"
        }
        requests = {
          cpu    = "0.1"
          memory = "128Mi"
        }
      }
    }

    # Volumes for shared data between containers
    volume {
      name = "shared-data"
      empty_dir {}
    }

    volume {
      name = "logs"
      empty_dir {}
    }

    volume {
      name = "config"
      config_map {
        name = kubernetes_config_map.fluentd_config.metadata[0].name
      }
    }
  }
}

resource "kubernetes_config_map" "fluentd_config" {
  metadata {
    name      = "fluentd-config"
    namespace = var.namespace
  }

  data = {
    "fluent.conf" = <<-EOF
      <source>
        @type tail
        path /fluentd/log/*.log
        pos_file /fluentd/log/app.log.pos
        tag app.*
        <parse>
          @type json
        </parse>
      </source>
      
      <match app.**>
        @type stdout
      </match>
    EOF
  }
}

resource "kubernetes_service" "multi_container_service" {
  metadata {
    name      = "${var.pod_name}-service"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "multi-container-app"
    }

    port {
      name       = "http"
      port       = 80
      target_port = 80
    }

    port {
      name       = "api"
      port       = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}