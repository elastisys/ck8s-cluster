package exoscale

import (
	"testing"

	"github.com/elastisys/ck8s/api"
	"github.com/google/go-cmp/cmp"
)

func TestFlavors(t *testing.T) {
	clusterType := api.ServiceCluster
	clusterName := "foo"

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
				PublicIngressCIDRWhitelist:  []string{},
				APIServerWhitelist:          []string{},
				NodeportWhitelist:           []string{},
				MasterNamesSC:               []string{"master-0"},
				MasterNameSizeMapSC:         map[string]string{"master-0": "Small"},
				WorkerNamesSC:               []string{"worker-0", "worker-1"},
				WorkerNameSizeMapSC:         map[string]string{"worker-0": "Extra-large", "worker-1": "Large"},
				ESLocalStorageCapacityMapSC: map[string]int{"worker-0": 26, "worker-1": 26},
				MasterNamesWC:               []string{"master-0"},
				MasterNameSizeMapWC:         map[string]string{"master-0": "Small"},
				WorkerNamesWC:               []string{"worker-0"},
				WorkerNameSizeMapWC:         map[string]string{"worker-0": "Large"},
				ESLocalStorageCapacityMapWC: map[string]int{"worker-0": 0},
				NFSSize:                     "Small",
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
			},
		},
		got: Production(clusterType, clusterName),
	}}

	for _, tc := range testCases {
		if diff := cmp.Diff(tc.want, tc.got, cmp.AllowUnexported(Cluster{})); diff != "" {
			t.Errorf("flavor mismatch (-want +got):\n%s", diff)
		}
	}
}
