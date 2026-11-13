variable "image" {
  type    = string
  default = "nomad-rollback-demo:local"
}

variable "app_version" {
  type    = string
  default = "v1"
}

variable "health_mode" {
  type    = string
  default = "healthy"
}

job "rollback-demo" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count          = 1
    shutdown_delay = "5s"

    network {
      mode = "host"
      port "http" {
        to = 8080
      }
    }

    update {
      max_parallel      = 1
      canary            = 1
      auto_promote      = true
      auto_revert       = true
      health_check      = "checks"
      min_healthy_time  = "10s"
      healthy_deadline  = "2m"
      progress_deadline = "4m"
    }

    service {
      name         = "rollback-demo"
      provider     = "consul"
      port         = "http"
      address_mode = "host"

      check {
        name     = "flask-health"
        type     = "http"
        path     = "/health"
        interval = "5s"
        timeout  = "2s"
      }
    }

    task "app" {
      driver = "docker"
      config {
        image      = var.image
        force_pull = false
        ports      = ["http"]
      }
      env {
        APP_VERSION = var.app_version
        HEALTH_MODE = var.health_mode
      }
      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
