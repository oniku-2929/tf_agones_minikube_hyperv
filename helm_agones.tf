locals {
  agones_registry              = "gcr.io/agones-images"
  agones_image_tag             = var.agones_helm_chart_version
  agones_image_name_controller = "agones-controller"
  agones_image_name_allocator  = "agones-allocator"
  agones_image_name_ping       = "agones-ping"
  agones_image_name_sdk        = "agones-sdk"
  helm_values_agones = [
    ["agones.image.registry", local.agones_registry],
    ["agones.image.tag", local.agones_image_tag],
    ["agones.image.controller.name", local.agones_image_name_controller],
    ["agones.image.allocator.name", local.agones_image_name_allocator],
    ["agones.image.ping.name", local.agones_image_name_ping],
    ["agones.image.sdk.name", local.agones_image_name_sdk],

    ["agones.allocator.service.loadBalancerIP", local.metallb_shared_ip],
    ["agones.allocator.service.annotations.metallb\\.universe\\.tf/address-pool", "${var.metallb_address_pool_name}"],
    ["agones.allocator.service.annotations.metallb\\.universe\\.tf/allow-shared-ip", "${var.metallb_shared_ip_id}"],
    ["agones.ping.http.loadBalancerIP", local.metallb_shared_ip],
    ["agones.ping.http.annotations.metallb\\.universe\\.tf/address-pool", "${var.metallb_address_pool_name}"],
    ["agones.ping.http.annotations.metallb\\.universe\\.tf/allow-shared-ip", "${var.metallb_shared_ip_id}"],
    ["agones.ping.udp.loadBalancerIP", local.metallb_shared_ip],
    ["agones.ping.udp.annotations.metallb\\.universe\\.tf/address-pool", "${var.metallb_address_pool_name}"],
    ["agones.ping.udp.annotations.metallb\\.universe\\.tf/allow-shared-ip", "${var.metallb_shared_ip_id}"],
  ]
}

resource "kubernetes_namespace" "gameserver" {
  metadata {
    annotations = {
      name = "agones gameserver namespace"
    }
    name = var.agones_gameserver_namespace
  }
}

data "helm_template" "agones" {
  repository        = var.agones_helm_chart_repository
  name              = var.agones_helm_relase_name
  chart             = var.agones_chart_name
  namespace         = var.agones_namespace_system
  dependency_update = true
  values = [
    file(var.helm_values_file)
  ]
  dynamic "set" {
    for_each = local.helm_values_agones
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }
  depends_on = [
    kubernetes_namespace.gameserver,
    helm_release.metallb_minikube,
  ]
}

resource "helm_release" "agones" {
  name              = data.helm_template.agones.name
  repository        = data.helm_template.agones.repository
  chart             = data.helm_template.agones.chart
  namespace         = data.helm_template.agones.namespace
  version           = data.helm_template.agones.version
  create_namespace  = true
  dependency_update = true
  timeout           = local.helm_creation_timeout_seconds
  values = [
    file(var.helm_values_file)
  ]

  dynamic "set" {
    for_each = local.helm_values_agones
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }

  depends_on = [
    kubernetes_namespace.gameserver,
    helm_release.metallb_minikube,
  ]
}

