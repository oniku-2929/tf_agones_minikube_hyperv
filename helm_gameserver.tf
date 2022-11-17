locals {
  agones_image_name_gameserver = var.gameserver_container_name
  agones_image_tag_gameserver  = var.gameserver_container_tag
  helm_values_gameserver = [
    ["gameServer.containerName", var.gameserver_container_name],
    ["gameServer.imageTag", var.gameserver_container_tag],
    ["gameServer.service.localPort", var.port_gameserver],
    ["gameServer.service.loadBalancerIP", local.metallb_shared_ip],
    ["gameServer.service.annotations.metallb.addressPool", var.metallb_address_pool_name],
    ["gameServer.service.annotations.metallb.allowSharedIP", var.metallb_shared_ip_id],
  ]
}

data "helm_template" "gameserver" {
  name              = "agones-gameserver"
  chart             = "./gameserver"
  namespace         = var.agones_gameserver_namespace
  dependency_update = true
  create_namespace  = true
  values = [
    file(var.helm_values_file)
  ]

  dynamic "set" {
    for_each = local.helm_values_gameserver
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }

  depends_on = [
    helm_release.agones
  ]
}

resource "helm_release" "gameserver" {
  name              = data.helm_template.gameserver.name
  repository        = data.helm_template.gameserver.repository
  chart             = data.helm_template.gameserver.chart
  namespace         = data.helm_template.gameserver.namespace
  version           = data.helm_template.gameserver.version
  create_namespace  = true
  dependency_update = true
  force_update      = true
  timeout           = local.helm_creation_timeout_seconds
  wait              = true
  values = [
    file(var.helm_values_file)
  ]

  dynamic "set" {
    for_each = local.helm_values_gameserver
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }

  depends_on = [
    helm_release.agones,
  ]
}
