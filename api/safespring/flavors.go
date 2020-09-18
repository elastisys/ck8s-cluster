package safespring

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

const (
	// FlavorDevelopment TODO
	FlavorDevelopment api.ClusterFlavor = "dev"

	// FlavorProduction TODO
	FlavorProduction api.ClusterFlavor = "prod"
)

// Common sizes
// +--------------------------------------+---------------+--------+------+-----------+-------+
// | ID                                   | Name          |    RAM | Disk | Ephemeral | VCPUs |
// +--------------------------------------+---------------+--------+------+-----------+-------+
// | 51d480b8-2517-4ba8-bfe0-c649ac93eb61 | lb.tiny       |   1024 |   10 |         0 |     1 |
// | 670a1fb5-520e-4669-8937-84daedac0779 | b.tiny        |   1024 |   40 |         0 |     1 |
// | 1493be98-d150-4f69-8154-4d59ea49681c | b.small       |   2048 |   40 |         0 |     1 |
// | 9d82d1ee-ca29-4928-a868-d56e224b92a1 | b.medium      |   4096 |   40 |         0 |     2 |
// | d84c84d6-6ff1-48d9-b5a0-e3fced6ded68 | m.small       |   4096 |   40 |         0 |     1 |
// | 16d11558-62fe-4bce-b8de-f49a077dc881 | b.large       |   8192 |   40 |         0 |     4 |
// | 2c1708d1-3974-4ab8-97cc-cbf58aa27ad9 | m.medium      |   8192 |   40 |         0 |     2 |
// | dc67a9eb-0685-4bb6-9383-a01c717e02e8 | lb.large.1d   |   8192 |   80 |       170 |     4 |
// | de5c366e-3e84-4d64-b973-235b23777574 | lm.large.1d   |  16384 |   80 |       170 |     4 |
// | ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf | lb.xlarge.1d  |  16384 |   80 |       170 |     8 |
// | f2a75ad2-259e-4c8b-b7e9-5695a572c68e | m.large       |  16384 |   40 |         0 |     4 |
// | fce2b54d-c0ef-4ad4-aa81-bcdcaa54f7cb | b.xlarge      |  16384 |   40 |         0 |     8 |
// | 2b3614e5-0b9f-4d98-bd55-b121bab78505 | lm.xlarge.1d  |  32768 |   80 |       170 |     8 |
// | 4065dd50-0cb4-4771-a056-646552dbf268 | lm.xlarge.2d  |  32768 |   80 |       420 |     8 |
// | 6fb03845-4ac3-496a-84f4-a599b10a12d3 | lb.2xlarge.4d |  32768 |   80 |       920 |    16 |
// | 7018a4d3-654f-46d1-b361-cae1687a12d4 | lb.2xlarge.2d |  32768 |   80 |       420 |    16 |
// | a9419181-843c-4001-a518-1512ba86703b | m.xlarge      |  32768 |   40 |         0 |     8 |
// | ae5ad60f-5df5-4125-be4d-5a628ae6fa3a | lb.2xlarge.1d |  32768 |   80 |       170 |    16 |
// | bb9ee5de-db6e-4252-86ea-76ecc2a4024a | lm.xlarge.4d  |  32768 |   80 |       920 |     8 |
// | c2d5dec5-8756-449d-9c6b-3b347f5af662 | b.2xlarge     |  32768 |   40 |         0 |    16 |
// | 175b724d-0068-4a7e-9a71-316a13bbd082 | lb.4xlarge.2d |  65536 |   80 |       420 |    32 |
// | 3af7587d-c330-4e44-96aa-8f845f9b5dbe | lm.2xlarge.2d |  65536 |   80 |       420 |    16 |
// | 53649fcb-139f-4182-8007-7b5e04daa48b | lb.4xlarge.1d |  65536 |   80 |       170 |    32 |
// | 554cc342-86c1-4fb2-9605-b526a34b4d02 | lm.2xlarge.4d |  65536 |   80 |       920 |    16 |
// | 5576ccc2-c189-4969-b6fc-5bd343a186d4 | lb.4xlarge.4d |  65536 |   80 |       920 |    32 |
// | 9af9be8a-b34f-4e1e-bdc0-0b30ce25da3a | m.2xlarge     |  65536 |   40 |         0 |    16 |
// | bbe805ca-1dd5-4f80-a70f-c8bc75d45ea9 | lm.2xlarge.1d |  65536 |   80 |       170 |    16 |
// | 259c224f-57ca-4d8a-88ef-be0e8e264c4c | lm.4xlarge.4d | 131070 |   80 |       920 |    32 |
// | ad5dd719-96dd-406e-bf44-d156df5f6a09 | lm.4xlarge.2d | 131070 |   80 |       420 |    32 |
// | ce566ff9-b82b-4681-a064-ba31eae5928e | lm.4xlarge.1d | 131070 |   80 |       170 |    32 |
// +--------------------------------------+---------------+--------+------+-----------+-------+

// Default TODO
func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	cluster := &Cluster{
		openstack.Default(clusterType, api.Safespring, clusterName),
	}

	cluster.Cluster.Config.IdentityAPIVersion = "3"
	cluster.Cluster.Config.AuthURL = "https://keystone.api.cloud.ipnett.se/v3"
	cluster.Cluster.Config.RegionName = "se-east-1"
	cluster.Cluster.Config.S3RegionAddress = "s3.sto1.safedc.net"

	cluster.Cluster.TFVars.ExternalNetworkID = "71b10496-2617-47ae-abbc-36239f0863bb"
	cluster.Cluster.TFVars.ExternalNetworkName = "public-v4"

	return cluster
}

func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		// b.medium
		"9d82d1ee-ca29-4928-a868-d56e224b92a1",
	).MustBuild()
	workerExtraLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// lb.xlarge.1d
		"ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf",
	).MustBuild()
	workerLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// lb.large.1d
		"dc67a9eb-0685-4bb6-9383-a01c717e02e8",
	).MustBuild()
	loadbalancer := api.NewMachineFactory(
		cloudProvider,
		api.LoadBalancer,
		// lb.tiny
		"51d480b8-2517-4ba8-bfe0-c649ac93eb61",
	).MustBuild()

	cluster.Cluster.TFVars.MachinesSC = map[string]*api.Machine{
		"master-0":       master,
		"worker-0":       workerExtraLarge,
		"worker-1":       workerLarge,
		"loadbalancer-0": loadbalancer,
	}

	cluster.Cluster.TFVars.MachinesWC = map[string]*api.Machine{
		"master-0":       master,
		"worker-0":       workerLarge,
		"loadbalancer-0": loadbalancer,
	}

	cluster.Cluster.TFVars.MasterAntiAffinityPolicySC = "anti-affinity"
	cluster.Cluster.TFVars.MasterAntiAffinityPolicyWC = "anti-affinity"

	return cluster
}

func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		// b.medium
		"9d82d1ee-ca29-4928-a868-d56e224b92a1",
	).MustBuild()
	workerExtraLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// lb.xlarge.1d
		"ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf",
	).MustBuild()
	workerLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// lb.large.1d
		"dc67a9eb-0685-4bb6-9383-a01c717e02e8",
	).MustBuild()
	loadbalancer := api.NewMachineFactory(
		cloudProvider,
		api.LoadBalancer,
		// lb.tiny
		"51d480b8-2517-4ba8-bfe0-c649ac93eb61",
	).MustBuild()

	cluster.Cluster.TFVars.MachinesSC = map[string]*api.Machine{
		"master-0":       master,
		"master-1":       master,
		"master-2":       master,
		"worker-0":       workerExtraLarge,
		"worker-1":       workerLarge,
		"worker-2":       workerLarge,
		"worker-3":       workerLarge,
		"loadbalancer-0": loadbalancer,
	}

	cluster.Cluster.TFVars.MachinesWC = map[string]*api.Machine{
		"master-0":       master,
		"master-1":       master,
		"master-2":       master,
		"worker-ck8s-0":  workerLarge,
		"worker-0":       workerLarge,
		"worker-1":       workerLarge,
		"worker-2":       workerLarge,
		"loadbalancer-0": loadbalancer,
	}

	cluster.Cluster.TFVars.MasterAntiAffinityPolicySC = "anti-affinity"
	cluster.Cluster.TFVars.MasterAntiAffinityPolicyWC = "anti-affinity"

	return cluster
}
