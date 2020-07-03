package client

import (
	"fmt"
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

	currentCluster.DNSName = getValue(tfOutputSlice, clusterTypeString+"_dns_name")
	currentCluster.DomainName = getValue(tfOutputSlice, "domain_name")
	currentCluster.LBIPAddress = getValue(tfOutputSlice, clusterTypeString+"_ingress_controller_lb_ip_address")
	currentCluster.MasterCount = len(getValue(tfOutputSlice, clusterTypeString+"_master_ips").(map[string]interface{}))
	currentCluster.MasterIPAddress = getValue(tfOutputSlice, clusterTypeString+"_master_ips")
	currentCluster.WorkerCount = len(getValue(tfOutputSlice, clusterTypeString+"_worker_ips").(map[string]interface{}))
	currentCluster.WorkerIPAddress = getValue(tfOutputSlice, clusterTypeString+"_worker_ips")
	currentCluster.NFSIPAddress = getValue(tfOutputSlice, clusterTypeString+"_nfs_ips")
}

func getValue(slice map[string]interface{}, key string) interface{} {
	if val, ok := slice[key]; ok {
		return val.(map[string]interface{})["value"]
	}
	fmt.Printf("Warning: Skipping key %s since it doesn't exist\n", key)
	return nil
}
