resource "k8s_core_v1_config_map" "istio_galley_configuration" {
  data = {
    "validatingwebhookconfiguration.yaml" = <<-EOF
      apiVersion: admissionregistration.k8s.io/v1beta1
      kind: ValidatingWebhookConfiguration
      metadata:
        name: istio-galley
        labels:
          app: galley
          chart: galley
          heritage: Tiller
          release: istio
          istio: galley
      webhooks:
        - name: pilot.validation.istio.io
          clientConfig:
            service:
              name: istio-galley
              namespace: ${var.namespace}
              path: "/admitpilot"
            caBundle: ""
          rules:
            - operations:
              - CREATE
              - UPDATE
              apiGroups:
              - config.istio.io
              apiVersions:
              - v1alpha2
              resources:
              - httpapispecs
              - httpapispecbindings
              - quotaspecs
              - quotaspecbindings
            - operations:
              - CREATE
              - UPDATE
              apiGroups:
              - rbac.istio.io
              apiVersions:
              - "*"
              resources:
              - "*"
            - operations:
              - CREATE
              - UPDATE
              apiGroups:
              - security.istio.io
              apiVersions:
              - "*"
              resources:
              - "*"
            - operations:
              - CREATE
              - UPDATE
              apiGroups:
              - authentication.istio.io
              apiVersions:
              - "*"
              resources:
              - "*"
            - operations:
              - CREATE
              - UPDATE
              apiGroups:
              - networking.istio.io
              apiVersions:
              - "*"
              resources:
              - destinationrules
              - envoyfilters
              - gateways
              - serviceentries
              - sidecars
              - virtualservices
          # Fail open until the validation webhook is ready. The webhook controller
          # will update this to `Fail` and patch in the `caBundle` when the webhook
          # endpoint is ready.
          failurePolicy: Ignore
          sideEffects: None
        - name: mixer.validation.istio.io
          clientConfig:
            service:
              name: istio-galley
              namespace: ${var.namespace}
              path: "/admitmixer"
            caBundle: ""
          rules:
            - operations:
              - CREATE
              - UPDATE
              apiGroups:
              - config.istio.io
              apiVersions:
              - v1alpha2
              resources:
              - rules
              - attributemanifests
              - adapters
              - handlers
              - instances
              - templates
          # Fail open until the validation webhook is ready. The webhook controller
          # will update this to `Fail` and patch in the `caBundle` when the webhook
          # endpoint is ready.
          failurePolicy: Ignore
          sideEffects: None
      EOF
  }
  metadata {
    labels = {
      "app"      = "galley"
      "chart"    = "galley"
      "heritage" = "Tiller"
      "istio"    = "galley"
      "release"  = "istio"
    }
    name      = "istio-galley-configuration"
    namespace = var.namespace
  }
}