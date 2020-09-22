package client

import (
	"encoding/json"
	"io"
	"text/template"

	"github.com/elastisys/ck8s/api"
)

const ansibleInventoryTemplate = `{{ range $Name, $Machine := MachinesByNodeType "master" -}}
{{ $.Cluster.Name }}-{{ $Name }} ansible_host={{ $Machine.PublicIP }} private_ip={{ $Machine.PrivateIP }}
{{ end }}
{{ range $Name, $Machine := MachinesByNodeType "worker" -}}
{{ $.Cluster.Name }}-{{ $Name }} ansible_host={{ $Machine.PublicIP }} private_ip={{ $Machine.PrivateIP }}
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
{{ if .CloudProviderVars -}}
cloud_provider_vars='{{ .CloudProviderVars }}'
{{ end -}}
cluster_name='{{ .Cluster.Name }}'

calico_mtu='{{ .State.CalicoMTU }}'

kubeadm_init_extra_args='{{ .State.KubeadmInitExtraArgs }}'

[masters]
{{ range $Name, $_ := MachinesByNodeType "master" -}}
{{ $.Cluster.Name }}-{{ $Name }}
{{ end }}

[workers]
{{ range $Name, $_ := MachinesByNodeType "worker" -}}
{{ $.Cluster.Name }}-{{ $Name }}
{{ end }}

{{ if MachinesByNodeType "loadbalancer" -}}
[loadbalancers]
{{ range $Name, $Machine := MachinesByNodeType "loadbalancer" -}}
{{ $.Cluster.Name }}-{{ $Name }} ansible_host={{ $Machine.PublicIP }} private_ip={{ $Machine.PrivateIP }}
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
	machinesByNodeType := func(nt api.NodeType) map[string]api.MachineState {
		machines := map[string]api.MachineState{}
		for name, machine := range state.Machines() {
			if machine.NodeType == nt {
				machines[name] = machine
			}
		}
		return machines
	}

	// TODO: We really should try to get away from arbitrary JSON in the
	//		 Ansible inventory. Individual cloud config types would make more
	//		 sense. Perhaps even use the upstream types?
	//		 E.g. https://github.com/kubernetes/cloud-provider-openstack/blob/2493d936afe901a63066e4506dcfa716f1d96dc9/pkg/cloudprovider/providers/openstack/openstack.go#L223
	var cloudProviderVarsBytes []byte
	cloudProviderVars := cluster.CloudProviderVars(state)
	if cloudProviderVars != nil {
		var err error
		cloudProviderVarsBytes, err = json.Marshal(cloudProviderVars)
		if err != nil {
			return err
		}
	}

	tmpl, err := template.New("inventory").Funcs(template.FuncMap{
		"MachinesByNodeType": machinesByNodeType,
	}).Parse(ansibleInventoryTemplate)
	if err != nil {
		return err
	}

	return tmpl.Execute(w, struct {
		Cluster           api.Cluster
		State             api.ClusterState
		CloudProviderVars string
	}{
		Cluster:           cluster,
		State:             state,
		CloudProviderVars: string(cloudProviderVarsBytes),
	})
}
