package client

import (
	"html/template"
	"io"

	"github.com/elastisys/ck8s/api"
)

const ansibleInventoryTemplate = `{{ range MachinesByNodeType (NodeType "master") -}}
{{ $.Name }}-{{ .Name }} ansible_host={{ .PublicIP }} private_ip={{ .PrivateIP }}
{{ end }}
{{ range MachinesByNodeType (NodeType "worker") -}}
{{ $.Name }}-{{ .Name }} ansible_host={{ .PublicIP }} private_ip={{ .PrivateIP }}
{{ end }}

[all:vars]
k8s_pod_cidr=192.168.0.0/16
k8s_service_cidr=10.96.0.0/12

ansible_user='ubuntu'
ansible_port=22
# TODO: move this to ansible.cfg when upgraded to ansible 2.8
ansible_python_interpreter=/usr/bin/python3

{{ if .ControlPlaneEndpoint -}}
control_plane_endpoint='{{ .ControlPlaneEndpoint }}'
{{ end -}}
{{ if .ControlPlanePort -}}
control_plane_port='{{ .ControlPlanePort }}'
{{ end -}}
{{ if ControlPlanePublicIP -}}
public_endpoint='{{ ControlPlanePublicIP }}'
{{ end -}}
{{ if .PrivateNetworkCIDR -}}
private_network_cidr='{{ .PrivateNetworkCIDR }}'
{{ end -}}
{{ if .KubeadmInitCloudProvider -}}
cloud_provider='{{ .KubeadmInitCloudProvider }}'
{{ end -}}
{{ if .KubeadmInitCloudConfigPath -}}
cloud_config='{{ .KubeadmInitCloudConfigPath }}'
{{ end -}}
cluster_name='{{ .Name }}'

calico_mtu='{{ .CalicoMTU }}'

kubeadm_init_extra_args='{{ .KubeadmInitExtraArgs }}'

[masters]
{{ range MachinesByNodeType (NodeType "master") -}}
{{ $.Name }}-{{ .Name }}
{{ end }}

[workers]
{{ range MachinesByNodeType (NodeType "worker") -}}
{{ $.Name }}-{{ .Name }}
{{ end }}

{{ if MachinesByNodeType (NodeType "loadbalancer") -}}
[loadbalancers]
{{ range MachinesByNodeType (NodeType "loadbalancer") -}}
{{ $.Name }}-{{ .Name }}
{{ end }}
{{ end }}
{{ if .InternalLoadBalancerAnsibleGroups -}}
[internal_lb:children]
{{ range .InternalLoadBalancerAnsibleGroups -}}
{{ . }}
{{ end }}
{{ end -}}

[nodes:children]
masters
workers
`

func renderAnsibleInventory(
	cluster api.Cluster,
	state api.ClusterState,
	w io.Writer,
) error {
	machinesByNodeType := func(nt api.NodeType) (machines []api.MachineState) {
		for _, machine := range state.Machines() {
			if machine.NodeType == nt {
				machines = append(machines, machine)
			}
		}
		return
	}

	tmpl, err := template.New("inventory").Funcs(template.FuncMap{
		"NodeType":             api.NodeTypeFromString,
		"ControlPlanePublicIP": state.ControlPlanePublicIP,
		"MachinesByNodeType":   machinesByNodeType,
	}).Parse(ansibleInventoryTemplate)
	if err != nil {
		return err
	}

	return tmpl.Execute(w, cluster)
}
