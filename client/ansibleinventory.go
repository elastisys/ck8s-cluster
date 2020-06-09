package client

import (
	"html/template"
	"io"

	"github.com/elastisys/ck8s/api"
)

const ansibleInventoryTemplate = `{{ range MachinesByNodeType (NodeType "master") -}}
{{ $.Cluster.Name }}-{{ .Name }} ansible_host={{ .PublicIP }} private_ip={{ .PrivateIP }}
{{ end }}
{{ range MachinesByNodeType (NodeType "worker") -}}
{{ $.Cluster.Name }}-{{ .Name }} ansible_host={{ .PublicIP }} private_ip={{ .PrivateIP }}
{{ end }}

[all:vars]
k8s_pod_cidr=192.168.0.0/16
k8s_service_cidr=10.96.0.0/12

ansible_user='ubuntu'
ansible_port=22
# TODO: move this to ansible.cfg when upgraded to ansible 2.8
ansible_python_interpreter=/usr/bin/python3

{{ if .State.ControlPlaneEndpoint -}}
control_plane_endpoint='{{ .State.ControlPlaneEndpoint }}'
{{ end -}}
{{ if .State.ControlPlanePort -}}
control_plane_port='{{ .State.ControlPlanePort }}'
{{ end -}}
{{ if .State.ControlPlanePublicIP -}}
public_endpoint='{{ .State.ControlPlanePublicIP }}'
{{ end -}}
{{ if .State.PrivateNetworkCIDR -}}
private_network_cidr='{{ .State.PrivateNetworkCIDR }}'
{{ end -}}
{{ if .State.KubeadmInitCloudProvider -}}
cloud_provider='{{ .State.KubeadmInitCloudProvider }}'
{{ end -}}
{{ if .State.KubeadmInitCloudConfigPath -}}
cloud_config='{{ .State.KubeadmInitCloudConfigPath }}'
{{ end -}}
cluster_name='{{ .Cluster.Name }}'

calico_mtu='{{ .State.CalicoMTU }}'

kubeadm_init_extra_args='{{ .State.KubeadmInitExtraArgs }}'

[masters]
{{ range MachinesByNodeType (NodeType "master") -}}
{{ $.Cluster.Name }}-{{ .Name }}
{{ end }}

[workers]
{{ range MachinesByNodeType (NodeType "worker") -}}
{{ $.Cluster.Name }}-{{ .Name }}
{{ end }}

{{ if MachinesByNodeType (NodeType "loadbalancer") -}}
[loadbalancers]
{{ range MachinesByNodeType (NodeType "loadbalancer") -}}
{{ $.Cluster.Name }}-{{ .Name }}
{{ end }}
{{ end }}
{{ if .State.InternalLoadBalancerAnsibleGroups -}}
[internal_lb:children]
{{ range .State.InternalLoadBalancerAnsibleGroups -}}
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
		"NodeType":           api.NodeTypeFromString,
		"MachinesByNodeType": machinesByNodeType,
	}).Parse(ansibleInventoryTemplate)
	if err != nil {
		return err
	}

	return tmpl.Execute(w, struct {
		Cluster api.Cluster
		State   api.ClusterState
	}{
		Cluster: cluster,
		State:   state,
	})
}
