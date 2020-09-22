package azure

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
			config: AzureConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.Azure,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3RegionAddress: "sos-ch-gva-2.exo.io",

				TenantID:       "changeme",
				SubscriptionID: "changeme",
				Location:       "changeme",
			},
			secret: AzureSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				ClientID:     "changeme",
				ClientSecret: "changeme",
			},
			tfvars: AzureTFVars{
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},
			},
		},
		got: Default(clusterType, clusterName),
	}, {
		want: &Cluster{
			config: AzureConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.Azure,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3RegionAddress: "sos-ch-gva-2.exo.io",

				TenantID:       "changeme",
				SubscriptionID: "changeme",
				Location:       "changeme",
			},
			secret: AzureSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				ClientID:     "changeme",
				ClientSecret: "changeme",
			},
			tfvars: AzureTFVars{
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},
				MachinesSC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "Standard_D2_v3",
						Image:    latestImage,
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "Standard_D4_v3",
						Image:    latestImage,
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "Standard_D4_v3",
						Image:    latestImage,
					},
				},
				MachinesWC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "Standard_D2_v3",
						Image:    latestImage,
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "Standard_D4_v3",
						Image:    latestImage,
					},
				},
			},
		},
		got: Development(clusterType, clusterName),
	},
		{
			want: &Cluster{
				config: AzureConfig{
					BaseConfig: api.BaseConfig{
						ClusterType:               clusterType,
						CloudProviderType:         api.Azure,
						EnvironmentName:           clusterName,
						DNSPrefix:                 clusterName,
						S3BucketNameHarbor:        clusterName + "-harbor",
						S3BucketNameVelero:        clusterName + "-velero",
						S3BucketNameElasticsearch: clusterName + "-es-backup",
						S3BucketNameInfluxDB:      clusterName + "-influxdb",
						S3BucketNameFluentd:       clusterName + "-sc-logs",
					},
					S3RegionAddress: "sos-ch-gva-2.exo.io",

					TenantID:       "changeme",
					SubscriptionID: "changeme",
					Location:       "changeme",
				},
				secret: AzureSecret{
					BaseSecret: api.BaseSecret{
						S3AccessKey: "changeme",
						S3SecretKey: "changeme",
					},
					ClientID:     "changeme",
					ClientSecret: "changeme",
				},
				tfvars: AzureTFVars{
					PublicIngressCIDRWhitelist: []string{},
					APIServerWhitelist:         []string{},
					NodeportWhitelist:          []string{},

					MachinesSC: map[string]*api.Machine{
						"master-0": {
							NodeType: api.Master,
							Size:     "Standard_D2_v3",

							Image: latestImage,
						},
						"master-1": {
							NodeType: api.Master,
							Size:     "Standard_D2_v3",

							Image: latestImage,
						},
						"master-2": {
							NodeType: api.Master,
							Size:     "Standard_D2_v3",

							Image: latestImage,
						},
						"worker-0": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
						"worker-1": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
						"worker-2": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
						"worker-3": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
					},
					MachinesWC: map[string]*api.Machine{
						"master-0": {
							NodeType: api.Master,
							Size:     "Standard_D2_v3",

							Image: latestImage,
						},
						"master-1": {
							NodeType: api.Master,
							Size:     "Standard_D2_v3",

							Image: latestImage,
						},
						"master-2": {
							NodeType: api.Master,
							Size:     "Standard_D2_v3",

							Image: latestImage,
						},
						"worker-ck8s-0": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
						"worker-0": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
						"worker-1": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
						"worker-2": {
							NodeType: api.Worker,
							Size:     "Standard_D4_v3",

							Image: latestImage,
						},
					},
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
