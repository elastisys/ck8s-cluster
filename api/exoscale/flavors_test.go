package exoscale

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"

	"github.com/elastisys/ck8s/api"
)

func TestFlavors(t *testing.T) {
	clusterType := api.ServiceCluster
	clusterName := "foo"

	latestImage := supportedImages[len(supportedImages)-1]

	type testCase struct {
		want, got api.Cluster
	}

	testCases := []testCase{{
		want: &Cluster{
			config: ExoscaleConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.Exoscale,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3RegionAddress: "sos-ch-gva-2.exo.io",
			},
			secret: ExoscaleSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				APIKey:    "changeme",
				SecretKey: "changeme",
			},
			tfvars: ExoscaleTFVars{
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},
			},
		},
		got: Default(clusterType, clusterName),
	}, {
		want: &Cluster{
			config: ExoscaleConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.Exoscale,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3RegionAddress: "sos-ch-gva-2.exo.io",
			},
			secret: ExoscaleSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				APIKey:    "changeme",
				SecretKey: "changeme",
			},
			tfvars: ExoscaleTFVars{
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},
				MachinesSC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "Small",
						Image:    latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "Extra-large",
						Image:    latestImage,
						ProviderSettings: &MachineSettings{
							ESLocalStorageCapacity: 12,
							DiskSize:               50,
						},
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "Large",
						Image:    latestImage,
						ProviderSettings: &MachineSettings{
							ESLocalStorageCapacity: 12,
							DiskSize:               50,
						},
					},
				},
				MachinesWC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "Small",
						Image:    latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "Large",
						Image:    latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
				},
				NFSSize:     "Small",
				NFSDiskSize: 200,
			},
		},
		got: Development(clusterType, clusterName),
	}, {
		want: &Cluster{
			config: ExoscaleConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.Exoscale,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3RegionAddress: "sos-ch-gva-2.exo.io",
			},
			secret: ExoscaleSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				APIKey:    "changeme",
				SecretKey: "changeme",
			},
			tfvars: ExoscaleTFVars{
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},

				MachinesSC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "Medium",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"master-1": {
						NodeType: api.Master,
						Size:     "Medium",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"master-2": {
						NodeType: api.Master,
						Size:     "Medium",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "Extra-large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							ESLocalStorageCapacity: 140,
							DiskSize:               200,
						},
					},
					"worker-2": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							ESLocalStorageCapacity: 140,
							DiskSize:               200,
						},
					},
					"worker-3": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
				},
				MachinesWC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "Medium",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"master-1": {
						NodeType: api.Master,
						Size:     "Medium",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"master-2": {
						NodeType: api.Master,
						Size:     "Medium",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-ck8s-0": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
					"worker-2": {
						NodeType: api.Worker,
						Size:     "Large",

						Image: latestImage,
						ProviderSettings: &MachineSettings{
							DiskSize: 50,
						},
					},
				},
				NFSSize:     "Small",
				NFSDiskSize: 200,
			},
		},
		got: Production(clusterType, clusterName),
	}}

	for _, tc := range testCases {
		if diff := cmp.Diff(
			tc.want,
			tc.got,
			cmp.AllowUnexported(Cluster{}),
			cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
		); diff != "" {
			t.Errorf("flavor mismatch (-want +got):\n%s", diff)
		}
	}
}
