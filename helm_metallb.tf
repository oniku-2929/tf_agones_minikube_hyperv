locals {
  is_unix                       = substr(abspath(path.root), 0, 1) == "/"
  namespace_metallb             = "metallb-system"
  relasename_metallb_post       = "metallb-minikube"
  metallb_shared_ip             = local.is_unix ? data.external.minikube_ip_unix[0].result.address : data.external.minikube_ip[0].result.address
  repository_speaker            = "quay.io/metallb/speaker"
  repository_controller         = "quay.io/metallb/controller"
  version_tag                   = "v${var.metallb_system_version}"
  helm_creation_timeout_seconds = 1200

  helm_values_metallb_system = [
    ["speaker.image.repository", local.repository_speaker],
    ["speaker.image.tag", local.version_tag],
    ["controller.image.repository", local.repository_controller],
    ["controller.image.tag", local.version_tag],
  ]

  helm_values_metallb = [
    ["metalLB.addressConfig.addressPool.metadata.name", var.metallb_address_pool_name],
    ["metalLB.addressConfig.addressPool.range", "${local.metallb_shared_ip}-${local.metallb_shared_ip}"],
  ]

  preload_images = {
    "metallb_speaker"    = "${local.repository_speaker}:${local.version_tag}",
    "metallb_controller" = "${local.repository_controller}:${local.version_tag}",
    "agones_controller"  = "${local.agones_registry}/${local.agones_image_name_controller}:${local.agones_image_tag}",
    "agones_allocator"   = "${local.agones_registry}/${local.agones_image_name_allocator}:${local.agones_image_tag}",
    "agones_ping"        = "${local.agones_registry}/${local.agones_image_name_ping}:${local.agones_image_tag}",
    "agones_sdk"         = "${local.agones_registry}/${local.agones_image_name_sdk}:${local.agones_image_tag}",
    "agones_gameserver"  = "${local.agones_registry}/${local.agones_image_name_gameserver}:${local.agones_image_tag_gameserver}"
  }
}

data "external" "minikube_ip" {
  count   = local.is_unix ? 0 : 1
  program = ["Powershell.exe", "-Executionpolicy", "bypass", "-File", "./get_minikube_ip.ps1"]
}

data "external" "minikube_ip_unix" {
  count   = local.is_unix ? 1 : 0
  program = ["./get_minikube_ip.sh"]
}

resource "null_resource" "preload_images" {
  for_each = local.preload_images
  triggers = {
    always = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOT
    minikube image load ${each.value} -p agones
    EOT
  }
}

data "helm_template" "metallb" {
  repository        = var.metallb_system_repository
  name              = var.metallb_system_release_name
  chart             = var.metallb_system_release_name
  version           = var.metallb_system_version
  namespace         = local.namespace_metallb
  dependency_update = true
  create_namespace  = true
  values = [
    file(var.helm_values_file)
  ]
  dynamic "set" {
    for_each = local.helm_values_metallb_system
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }

  depends_on = [
    null_resource.preload_images
  ]
}

resource "helm_release" "metallb" {
  name              = data.helm_template.metallb.name
  repository        = data.helm_template.metallb.repository
  chart             = data.helm_template.metallb.chart
  namespace         = data.helm_template.metallb.namespace
  version           = data.helm_template.metallb.version
  create_namespace  = true
  dependency_update = true
  devel             = true
  timeout           = local.helm_creation_timeout_seconds
  values = [
    file(var.helm_values_file)
  ]
  dynamic "set" {
    for_each = local.helm_values_metallb_system
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }

  depends_on = [
    null_resource.preload_images
  ]
}

data "helm_template" "metallb_minikube" {
  name              = local.relasename_metallb_post
  chart             = var.metallb_minikube_helm_chart_name
  namespace         = local.namespace_metallb
  create_namespace  = true
  dependency_update = true
  values = [
    file(var.helm_values_file)
  ]
  dynamic "set" {
    for_each = local.helm_values_metallb
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }
  depends_on = [
    helm_release.metallb
  ]
}

resource "helm_release" "metallb_minikube" {
  name              = data.helm_template.metallb_minikube.name
  chart             = data.helm_template.metallb_minikube.chart
  namespace         = local.namespace_metallb
  create_namespace  = true
  dependency_update = true
  force_update      = true
  timeout           = local.helm_creation_timeout_seconds
  values = [
    file(var.helm_values_file)
  ]
  dynamic "set" {
    for_each = local.helm_values_metallb
    content {
      name  = set.value[0]
      value = set.value[1]
    }
  }

  depends_on = [
    helm_release.metallb
  ]
}
