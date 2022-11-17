output "metallb_manifests" {
  value       = var.enable_manifest_output ? data.helm_template.metallb.manifests : null
  description = "The yaml manifests genareted by Helm for MatlLB system components"
}

output "metallb_minikube_manifests" {
  value       = var.enable_manifest_output ? data.helm_template.metallb_minikube.manifests : null
  description = "The yaml manifests genareted by Helm for MatlLB CRDs(IPAdressPool, L2Advertisement)"
}

output "agones_yaml_manifests" {
  value       = var.enable_manifest_output ? data.helm_template.agones.manifests : null
  description = "The yaml manifests genareted by Helm for Agones components"
}

output "gameserver_yaml_manifests" {
  value       = var.enable_manifest_output ? data.helm_template.gameserver.manifests : null
  description = "The yaml manifests genareted by Helm for Agones game server"
}

output "port_gameserver" {
  value       = var.port_gameserver
  description = "The port number for Agones game server."
}

output "image_metallb_speaker" {
  value       = var.enable_image_output ? "${local.repository_speaker}:${local.version_tag}" : null
  description = "Container image name MetalLB speaker."
}

output "image_metallb_controller" {
  value       = var.enable_image_output ? "${local.repository_controller}:${local.version_tag}" : null
  description = "Container image name MetalLB controller."
}

output "image_agones_controller" {
  value       = var.enable_image_output ? "${local.agones_registry}/${local.agones_image_name_controller}:${local.agones_image_tag}" : null
  description = "Container image name Agones controller."
}

output "image_agones_allocator" {
  value       = var.enable_image_output ? "${local.agones_registry}/${local.agones_image_name_allocator}:${local.agones_image_tag}" : null
  description = "Container image name Agones allocator."
}

output "image_agones_ping" {
  value       = var.enable_image_output ? "${local.agones_registry}/${local.agones_image_name_ping}:${local.agones_image_tag}" : null
  description = "Container image name Agones ping."
}

output "image_agones_sdk" {
  value       = var.enable_image_output ? "${local.agones_registry}/${local.agones_image_name_sdk}:${local.agones_image_tag}" : null
  description = "Container image name Agones sdk."
}

output "image_agones_game_server" {
  value       = var.enable_image_output ? "${local.agones_registry}/${local.agones_image_name_gameserver}:${local.agones_image_tag_gameserver}" : null
  description = "Container image name Agones gameserver."
}
