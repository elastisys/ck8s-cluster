package citycloud

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

const (
	FlavorDevelopment api.ClusterFlavor = "dev"
	FlavorProduction  api.ClusterFlavor = "prod"
)

// Common sizes
// +--------------------------------------+----------------------------+--------+------+-----------+-------+-----------+
// | ID                                   | Name                       |    RAM | Disk | Ephemeral | VCPUs | Is Public |
// +--------------------------------------+----------------------------+--------+------+-----------+-------+-----------+
// | 0ac5307a-c4e8-4d06-9516-8ddbdeb43507 | 2C-2GB-50GB                |   2048 |   50 |         0 |     2 | True      |
// | 30b5bb1c-e544-4c27-bb22-2a08e653f1fa | 4C-2GB-50GB                |   2048 |   50 |         0 |     4 | True      |
// | 96c7903e-32f0-421d-b6a2-a45c97b15665 | 2C-4GB-50GB                |   4096 |   50 |         0 |     2 | True      |
// | a7074ddb-fae6-4029-8052-bea94d109e81 | 8C-4GB-50GB                |   4096 |   50 |         0 |     8 | True      |
// | c83b7ac9-ede5-476c-8bbd-00a4be6e50da | 4C-4GB-50GB                |   4096 |   50 |         0 |     4 | True      |
// | 572a3b2e-6329-4053-b872-aecb1e70d8a6 | 4C-8GB-50GB                |   8192 |   50 |         0 |     4 | True      |
// | 73e99a76-a55c-402f-83e6-72dee465c675 | 2C-8GB-50GB                |   8192 |   50 |         0 |     2 | True      |
// | b8d5317f-db27-4c94-bd40-f62f842a5031 | 8C-8GB-50GB                |   8192 |   50 |         0 |     8 | True      |
// | 80c21068-032e-40b2-b02f-f06715b4de8a | 8C-16GB-50GB               |  16384 |   50 |         0 |     8 | True      |
// | bdf83a6c-47ff-43f2-a79b-be09a4e4eba0 | 16C-16GB-50GB              |  16384 |   50 |         0 |    16 | True      |
// | d430b3cd-0216-43ff-878c-c08689c0001b | 4C-16GB-50GB               |  16384 |   50 |         0 |     4 | True      |
// | 0bc9ea27-e912-4d1b-be6c-daca18d3f51e | 8C-32GB-50GB               |  32768 |   50 |         0 |     8 | True      |
// +--------------------------------------+----------------------------+--------+------+-----------+-------+-----------+

func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	cluster := &Cluster{
		openstack.Default(clusterType, api.CityCloud, clusterName),
	}

	cluster.Cluster.Config.IdentityAPIVersion = "3"
	cluster.Cluster.Config.AuthURL = "https://kna1.citycloud.com:5000"
	cluster.Cluster.Config.RegionName = "Kna1"
	cluster.Cluster.Config.S3RegionAddress = "s3-kna1.citycloud.com:8080"

	cluster.Cluster.TFVars.ExternalNetworkID = "fba95253-5543-4078-b793-e2de58c31378"
	cluster.Cluster.TFVars.ExternalNetworkName = "ext-net"

	return cluster
}

func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		// 2C-4GB-50GB
		"96c7903e-32f0-421d-b6a2-a45c97b15665",
	).MustBuild()
	worker4C16GB50GB := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-16GB-50GB
		"d430b3cd-0216-43ff-878c-c08689c0001b",
	).MustBuild()
	worker4C8GB50GB := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-8GB-50GB
		"572a3b2e-6329-4053-b872-aecb1e70d8a6",
	).MustBuild()

	cluster.Cluster.TFVars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": worker4C16GB50GB,
		"worker-1": worker4C8GB50GB,
	}

	cluster.Cluster.TFVars.MachinesWC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": worker4C8GB50GB,
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
		// 2C-4GB-50GB
		"96c7903e-32f0-421d-b6a2-a45c97b15665",
	).MustBuild()
	worker8C16GB50GB := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 8C-16GB-50GB
		"80c21068-032e-40b2-b02f-f06715b4de8a",
	).MustBuild()
	worker4C8GB50GB := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-8GB-50GB
		"572a3b2e-6329-4053-b872-aecb1e70d8a6",
	).MustBuild()

	cluster.Cluster.TFVars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"master-1": master,
		"master-2": master,
		"worker-0": worker8C16GB50GB,
		"worker-1": worker4C8GB50GB,
		"worker-2": worker4C8GB50GB,
		"worker-3": worker4C8GB50GB,
	}

	cluster.Cluster.TFVars.MachinesWC = map[string]*api.Machine{
		"master-0":      master,
		"master-1":      master,
		"master-2":      master,
		"worker-ck8s-0": worker4C8GB50GB,
		"worker-0":      worker4C8GB50GB,
		"worker-1":      worker4C8GB50GB,
		"worker-2":      worker4C8GB50GB,
	}

	cluster.Cluster.TFVars.MasterAntiAffinityPolicySC = "anti-affinity"
	cluster.Cluster.TFVars.MasterAntiAffinityPolicyWC = "anti-affinity"

	return cluster
}
