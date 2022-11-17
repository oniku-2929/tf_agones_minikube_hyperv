# Terraform running Agones on Minikube to use Windows Hyper-V driver
These configurations and scripts tried to run [Agones](https://agones.dev/site/docs/) on Minikube with Windows Hyper-V driver using MetalLB.  
This [workaround](https://agones.dev/site/docs/installation/creating-cluster/minikube/#local-connection-workarounds) said it's recommended to use
another driver when `minikube tunnel` doesn't work.  
However, I wanted to keep using Hyper-V driver and wanted to manage configurations through Terraform.
That's the purpose for these configurations.

Then I searched workaround and I found [his post.](https://github.com/kubernetes/minikube/issues/12362#issuecomment-1034678334)

Currently, it's just run (simple game server)[https://github.com/googleforgames/agones/tree/main/examples/simple-game-server]

# Usage
## Normal Usage
1. minikube start --kubernetes-version v1.23.9 -p agones
    - if you changed Minikube driver manually, run `minikube config set driver hyperv -p agones`
2. terraform init; terraform apply

After the process, the game server will be running.  
you can check this through (tools)[https://agones.dev/site/docs/getting-started/create-gameserver/#3-connect-to-the-gameserver] like nc or nmap.  

1. install network tool
2. check the `minikube ip -p agones` for deciding the host that it will send UDP packet.
3. The default load balancer port is `30000`, so you can send UDP packets using the above tools.
    - In the case of nc, `nc -u (minikube ip) 30000`
    - Type `aaa` then enter, and it will return `ACK: aaa`
## Test(required Go)
if you have Go developing environment, you can test it one-shot `go test` command.
- cd ./test
- `go test -v`
    - if there are no `agones` Minikube Cluster, it will automatically create by command `minikube start --kubernetes-version v1.23.9 -p agones`.
    - In default, all resources (Minikube Cluster, MetalLB, and Agones components running on the cluster) will remain after the test.
    - if you want to clean all of these after the test, you can use `--clean` flag so run `go test -v --clean`

# Requirements(Software and tools)
| Name | Version |
|-----------|---------|
| Terraform | >= v1.2.3 |
| Minikube  | >= v1.27.0 |
| Helm      | >= v3.8.2 |

# Why & Why Not?
## Why did you split Helm chart for MetalLB (about helm_release.metallb and helm_release.metallb_minikube)
Because I didn't handle template generation priority to use `pre install` Chart Hook during Helm generation.  
[On MetalLB over v0.12, these components defined on CRDs.](https://metallb.universe.tf/configuration/migration_to_crds/)  
Initially, I tied to define a Chart with my configurated CRDs(IPAddressPool and L2Advertisement) and base metalLB Helm chart as a Sub Chart.  
However, Helm `pre install` hook didn't work at the time because of [this reason](https://github.com/helm/helm/issues/11422#issuecomment-1281158642).  
So I didn't solve dependencies only the Helm layer then I move its relation to Terraform configuration.  
That's why I split the helm_release.

# Terraform Information
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_external"></a> [external](#requirement\_external) | ~> 2.2.3 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.7.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.14.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.2.3 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.7.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.14.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| helm_release.agones | resource |
| helm_release.gameserver | resource |
| helm_release.metallb | resource |
| helm_release.metallb_minikube | resource |
| kubernetes_namespace.gameserver | resource |
| null_resource.preload_images | resource |
| external_external.minikube_ip | data source |
| external_external.minikube_ip_unix | data source |
| helm_template.agones | data source |
| helm_template.gameserver | data source |
| helm_template.metallb | data source |
| helm_template.metallb_minikube | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agones_chart_name"></a> [agones\_chart\_name](#input\_agones\_chart\_name) | The Helm chart name for Agones. | `string` | `"agones"` | no |
| <a name="input_agones_gameserver_namespace"></a> [agones\_gameserver\_namespace](#input\_agones\_gameserver\_namespace) | The namespace name for running Agones game server. | `string` | `"agones-gs"` | no |
| <a name="input_agones_helm_chart_repository"></a> [agones\_helm\_chart\_repository](#input\_agones\_helm\_chart\_repository) | The name of Helm repository for Agones. | `string` | `"https://agones.dev/chart/stable"` | no |
| <a name="input_agones_helm_chart_version"></a> [agones\_helm\_chart\_version](#input\_agones\_helm\_chart\_version) | The version of Agones. | `string` | `"1.26.0"` | no |
| <a name="input_agones_helm_relase_name"></a> [agones\_helm\_relase\_name](#input\_agones\_helm\_relase\_name) | The Helm release name for Agones. | `string` | `"agones-minikube"` | no |
| <a name="input_agones_namespace_system"></a> [agones\_namespace\_system](#input\_agones\_namespace\_system) | The namespace name for running Agones system components. | `string` | `"agones-system"` | no |
| <a name="input_enable_image_output"></a> [enable\_image\_output](#input\_enable\_image\_output) | The flag to enable to display all of container image names. | `bool` | `false` | no |
| <a name="input_enable_manifest_output"></a> [enable\_manifest\_output](#input\_enable\_manifest\_output) | The flag to enable to display all of data.helm\_template resources. | `bool` | `false` | no |
| <a name="input_gameserver_container_name"></a> [gameserver\_container\_name](#input\_gameserver\_container\_name) | The container name for Agones game server. | `string` | `"simple-game-server"` | no |
| <a name="input_gameserver_container_tag"></a> [gameserver\_container\_tag](#input\_gameserver\_container\_tag) | The version tag for Agones simple game server. | `string` | `"0.13"` | no |
| <a name="input_helm_values_file"></a> [helm\_values\_file](#input\_helm\_values\_file) | The value file for Helm | `string` | `"values.yaml"` | no |
| <a name="input_metallb_address_pool_name"></a> [metallb\_address\_pool\_name](#input\_metallb\_address\_pool\_name) | The name of IPAdressPool in MetalLB. | `string` | `"local-address-pool"` | no |
| <a name="input_metallb_minikube_helm_chart_name"></a> [metallb\_minikube\_helm\_chart\_name](#input\_metallb\_minikube\_helm\_chart\_name) | The name of Helm chart Path for creating MetalLB release. | `string` | `"./helm_metallb_minikube"` | no |
| <a name="input_metallb_shared_ip_id"></a> [metallb\_shared\_ip\_id](#input\_metallb\_shared\_ip\_id) | The Identifier to the specified group for using same IP address pool in MetalLB. [see here](https://metallb.universe.tf/usage/#ip-address-sharing) | `string` | `"share-minikube-ip"` | no |
| <a name="input_metallb_system_release_name"></a> [metallb\_system\_release\_name](#input\_metallb\_system\_release\_name) | The Helm release name for MetalLB. | `string` | `"metallb"` | no |
| <a name="input_metallb_system_repository"></a> [metallb\_system\_repository](#input\_metallb\_system\_repository) | The name of Helm repository for MetalLB. | `string` | `"https://metallb.github.io/metallb"` | no |
| <a name="input_metallb_system_version"></a> [metallb\_system\_version](#input\_metallb\_system\_version) | The version of MetalLB. | `string` | `"0.13.7"` | no |
| <a name="input_port_gameserver"></a> [port\_gameserver](#input\_port\_gameserver) | The port number for Agones game server. | `number` | `30000` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agones_yaml_manifests"></a> [agones\_yaml\_manifests](#output\_agones\_yaml\_manifests) | The yaml manifests genareted by Helm for Agones components |
| <a name="output_gameserver_yaml_manifests"></a> [gameserver\_yaml\_manifests](#output\_gameserver\_yaml\_manifests) | The yaml manifests genareted by Helm for Agones game server |
| <a name="output_image_agones_allocator"></a> [image\_agones\_allocator](#output\_image\_agones\_allocator) | Container image name Agones allocator. |
| <a name="output_image_agones_controller"></a> [image\_agones\_controller](#output\_image\_agones\_controller) | Container image name Agones controller. |
| <a name="output_image_agones_game_server"></a> [image\_agones\_game\_server](#output\_image\_agones\_game\_server) | Container image name Agones gameserver. |
| <a name="output_image_agones_ping"></a> [image\_agones\_ping](#output\_image\_agones\_ping) | Container image name Agones ping. |
| <a name="output_image_agones_sdk"></a> [image\_agones\_sdk](#output\_image\_agones\_sdk) | Container image name Agones sdk. |
| <a name="output_image_metallb_controller"></a> [image\_metallb\_controller](#output\_image\_metallb\_controller) | Container image name MetalLB controller. |
| <a name="output_image_metallb_speaker"></a> [image\_metallb\_speaker](#output\_image\_metallb\_speaker) | Container image name MetalLB speaker. |
| <a name="output_metallb_manifests"></a> [metallb\_manifests](#output\_metallb\_manifests) | The yaml manifests genareted by Helm for MatlLB system components |
| <a name="output_metallb_minikube_manifests"></a> [metallb\_minikube\_manifests](#output\_metallb\_minikube\_manifests) | The yaml manifests genareted by Helm for MatlLB CRDs(IPAdressPool, L2Advertisement) |
| <a name="output_port_gameserver"></a> [port\_gameserver](#output\_port\_gameserver) | The port number for Agones game server. |
<!-- END_TF_DOCS -->

## Licence
MIT