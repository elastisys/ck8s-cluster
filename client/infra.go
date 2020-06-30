package client

import (
	"io"
	"io/ioutil"

	"encoding/json"

	"github.com/elastisys/ck8s/api"
)

type infraClusterStruct struct {
	DNSName    interface{} `json:"dns_name"`
	DomainName interface{} `json:"domain_name"`

	LBIPAddress interface{} `json:"loadbalancer_ip_addresses"`

	MasterCount     interface{} `json:"master_count"`
	MasterIPAddress interface{} `json:"master_ip_addresses"`

	WorkerCount     interface{} `json:"worker_count"`
	WorkerIPAddress interface{} `json:"worker_ip_addresses"`

	NFSIPAddress interface{} `json:"nfs_ip_addresses"`
}

type infraStruct struct {
	WorkloadCluster infraClusterStruct `json:"workload_cluster"`
	ServiceCluster  infraClusterStruct `json:"service_cluster"`
}

func renderInfraJSON(
	config *ConfigHandler,
	f io.Reader,
	tfOutput interface{},
) error {
	currentValuesBytes, err := ioutil.ReadAll(f)
	if err != nil {
		return err
	}

	var newValuesMap infraStruct
	if len(currentValuesBytes) > 0 {
		if err := json.Unmarshal(currentValuesBytes, &newValuesMap); err != nil {
			config.logger.Warn("invalid_existing_infra_json")
			newValuesMap = infraStruct{}
		}
	}

	newValuesMap.updateValues(tfOutput, config.clusterType)
	newValuesMapJSON, err := json.Marshal(&newValuesMap)
	if err != nil {
		return err
	}

	if err := ioutil.WriteFile(config.configPath[api.InfraJsonFile].Path, newValuesMapJSON, 0644); err != nil {
		return err
	}

	return nil
}

func (i *infraStruct) updateValues(tfOutput interface{}, clusterType api.ClusterType) {
	var currentCluster *infraClusterStruct
	var clusterTypeString string
	switch clusterType {
	case api.WorkloadCluster:
		currentCluster = &i.WorkloadCluster
		clusterTypeString = "wc"
		break
	case api.ServiceCluster:
		currentCluster = &i.ServiceCluster
		clusterTypeString = "sc"
		break
	}

	//Prepare for a really ugly parsing (since this is going away this is okey)
	tfOutputSlice := tfOutput.(map[string]interface{})

	currentCluster.DNSName = tfOutputSlice[clusterTypeString+"_dns_name"].(map[string]interface{})["value"]
	currentCluster.DomainName = tfOutputSlice["domain_name"].(map[string]interface{})["value"]
	currentCluster.LBIPAddress = tfOutputSlice[clusterTypeString+"_ingress_controller_lb_ip_address"].(map[string]interface{})["value"]
	currentCluster.MasterCount = len(tfOutputSlice[clusterTypeString+"_master_ips"].(map[string]interface{})["value"].(map[string]interface{}))
	currentCluster.MasterIPAddress = tfOutputSlice[clusterTypeString+"_master_ips"].(map[string]interface{})["value"]
	currentCluster.WorkerCount = len(tfOutputSlice[clusterTypeString+"_worker_ips"].(map[string]interface{})["value"].(map[string]interface{}))
	currentCluster.WorkerIPAddress = tfOutputSlice[clusterTypeString+"_worker_ips"].(map[string]interface{})["value"]
	currentCluster.NFSIPAddress = tfOutputSlice[clusterTypeString+"_nfs_ips"].(map[string]interface{})["value"]
}
