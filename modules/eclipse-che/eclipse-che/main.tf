/**
 * Documentation
 *
 * terraform-docs --sort-inputs-by-required --with-aggregate-type-defaults md
 *
 */

locals {
  parameters = {
    name                 = var.name
    namespace            = var.namespace
    annotations          = merge(
      var.annotations,
      {
        "config_checksum" = md5(join("", keys(k8s_core_v1_config_map.che.data), values(k8s_core_v1_config_map.che.data)))
      },
    )
    replicas             = var.replicas
    ports                = var.ports
    enable_service_links = false

    containers = [
      {
        name  = "che"
        image = var.image

        env = concat([
          {
            name = "POD_NAME"
            value_from = {
              field_ref = {
                field_path = "metadata.name"
              }
            }
          },
          {
            name = "OPENSHIFT_KUBE_PING_NAMESPACE"
            value_from = {
              field_ref = {
                field_path = "metadata.namespace"
              }
            }
          }
        ], var.env)

        env_from = [
          {
            config_map_ref = {
              name = k8s_core_v1_config_map.che.metadata[0].name
            }
          },
        ]

        liveness_probe = {
          http_get = {
            path = "/api/system/state"
            port = "8080"
          }
          initial_delay_seconds = 120
          timeout_seconds       = 10
        }
        readiness_probe = {
          http_get = {
            path = "/api/system/state"
            port = "8080"
          }
          initial_delay_seconds = 15
          timeout_seconds       = 60
        }

        resources = {
          limits = {
            "memory" = "600Mi"
          }
          requests = {
            "memory" = "256Mi"
          }
        }

        security_context = {
          run_asuser = 1724
        }

        volume_mounts = [
          {
            name       = "che-data-volume"
            mount_path = "/data"
          },
        ]
      },
    ]

    init_containers = [
      {
        command = [
          "chmod",
          "777",
          "/data",
        ]
        image = "busybox"
        name  = "fmp-volume-permission"

        volume_mounts = [
          {
            name       = "che-data-volume"
            mount_path = "/data"
          },
        ]
      },
    ]

    security_context = {
      fsgroup = 1724
    }
    service_account_name = k8s_core_v1_service_account.che.metadata[0].name

    volumes = [
      {
        name = "che-data-volume"
        persistent_volume_claim = {
          claim_name = "che-data-volume"
        }
      },
    ]
  }
}

module "deployment-service" {
  source     = "../../../archetypes/deployment-service"
  parameters = merge(local.parameters, var.overrides)
}
