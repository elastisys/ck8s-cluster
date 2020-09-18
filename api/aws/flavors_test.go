package aws

import (
	"testing"

	"github.com/elastisys/ck8s/api"
	"github.com/google/go-cmp/cmp"
)

func TestFlavors(t *testing.T) {
	clusterType := api.ServiceCluster
	clusterName := "foo"

	latestImage := supportedImages["us-west-1"][len(supportedImages["us-west-1"])-1]

	type testCase struct {
		want, got api.Cluster
	}

	testCases := []testCase{{
		want: &Cluster{
			config: AWSConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.AWS,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3Region: "us-west-1",
			},
			secret: AWSSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				AWSAccessKeyID:     "changeme",
				AWSSecretAccessKey: "changeme",
				DNSAccessKeyID:     "changeme",
				DNSSecretAccessKey: "changeme",
			},
			tfvars: AWSTFVars{
				Region:                     "",
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},
			},
		},
		got: Default(clusterType, clusterName),
	}, {
		want: &Cluster{
			config: AWSConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.AWS,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3Region: "us-west-1",
			},
			secret: AWSSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				AWSAccessKeyID:     "changeme",
				AWSSecretAccessKey: "changeme",
				DNSAccessKeyID:     "changeme",
				DNSSecretAccessKey: "changeme",
			},
			tfvars: AWSTFVars{
				Region:                     "us-west-1",
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},

				MachinesSC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "t3.xlarge",
						Image:    latestImage,
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
				},

				MachinesWC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
				},
			},
		},
		got: Development(clusterType, clusterName),
	}, {
		want: &Cluster{
			config: AWSConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:               clusterType,
					CloudProviderType:         api.AWS,
					EnvironmentName:           clusterName,
					DNSPrefix:                 clusterName,
					S3BucketNameHarbor:        clusterName + "-harbor",
					S3BucketNameVelero:        clusterName + "-velero",
					S3BucketNameElasticsearch: clusterName + "-es-backup",
					S3BucketNameInfluxDB:      clusterName + "-influxdb",
					S3BucketNameFluentd:       clusterName + "-sc-logs",
				},
				S3Region: "us-west-1",
			},
			secret: AWSSecret{
				BaseSecret: api.BaseSecret{
					S3AccessKey: "changeme",
					S3SecretKey: "changeme",
				},
				AWSAccessKeyID:     "changeme",
				AWSSecretAccessKey: "changeme",
				DNSAccessKeyID:     "changeme",
				DNSSecretAccessKey: "changeme",
			},
			tfvars: AWSTFVars{
				Region:                     "us-west-1",
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
				NodeportWhitelist:          []string{},

				MachinesSC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"master-1": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"master-2": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "t3.xlarge",
						Image:    latestImage,
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
					"worker-2": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
					"worker-3": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
				},

				MachinesWC: map[string]*api.Machine{
					"master-0": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"master-1": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"master-2": {
						NodeType: api.Master,
						Size:     "t3.small",
						Image:    latestImage,
					},
					"worker-0": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
					"worker-1": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
					"worker-2": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
					"worker-ck8s-0": {
						NodeType: api.Worker,
						Size:     "t3.large",
						Image:    latestImage,
					},
				},
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
