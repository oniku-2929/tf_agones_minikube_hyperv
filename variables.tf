variable "enable_manifest_output" {
  type        = bool
  default     = false
  description = "The flag to enable to display all of data.helm_template resources."
}

variable "enable_image_output" {
  type        = bool
  default     = false
  description = "The flag to enable to display all of container image names."
}

variable "metallb_shared_ip_id" {
  type        = string
  default     = "share-minikube-ip"
  description = "The Identifier to the specified group for using same IP address pool in MetalLB. [see here](https://metallb.universe.tf/usage/#ip-address-sharing)"
}

variable "metallb_address_pool_name" {
  type        = string
  default     = "local-address-pool"
  description = "The name of IPAdressPool in MetalLB."
}

variable "metallb_minikube_helm_chart_name" {
  type        = string
  default     = "./helm_metallb_minikube"
  description = "The name of Helm chart Path for creating MetalLB release."
}

variable "metallb_system_repository" {
  type        = string
  default     = "https://metallb.github.io/metallb"
  description = "The name of Helm repository for MetalLB."
}

variable "metallb_system_release_name" {
  type        = string
  default     = "metallb"
  description = "The Helm release name for MetalLB."
}

variable "metallb_system_version" {
  type        = string
  default     = "0.13.7"
  description = "The version of MetalLB."
}

variable "agones_helm_chart_repository" {
  type        = string
  default     = "https://agones.dev/chart/stable"
  description = "The name of Helm repository for Agones."
}

variable "agones_helm_chart_version" {
  type        = string
  default     = "1.26.0"
  description = "The version of Agones."
}

variable "agones_namespace_system" {
  type        = string
  default     = "agones-system"
  description = "The namespace name for running Agones system components."
}

variable "agones_chart_name" {
  type        = string
  default     = "agones"
  description = "The Helm chart name for Agones."
}

variable "agones_helm_relase_name" {
  type        = string
  default     = "agones-minikube"
  description = "The Helm release name for Agones."
}

variable "helm_values_file" {
  type        = string
  default     = "values.yaml"
  description = "The value file for Helm"
}

variable "agones_gameserver_namespace" {
  type        = string
  default     = "agones-gs"
  description = "The namespace name for running Agones game server."
}

variable "port_gameserver" {
  type        = number
  default     = 30000
  description = "The port number for Agones game server."
}

variable "gameserver_container_name" {
  type        = string
  default     = "simple-game-server"
  description = "The container name for Agones game server."
}

variable "gameserver_container_tag" {
  type        = string
  default     = "0.13"
  description = "The version tag for Agones simple game server."
}
