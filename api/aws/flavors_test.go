package aws

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

				MasterNodesSC: map[string]string{"master-0": "t3.small"},
				WorkerNodesSC: map[string]string{"worker-0": "t3.xlarge", "worker-1": "t3.large"},
				MasterNodesWC: map[string]string{"master-0": "t3.small"},
				WorkerNodesWC: map[string]string{"worker-0": "t3.large", "worker-1": "t3.large"},
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
				Region:                     "",
				PublicIngressCIDRWhitelist: []string{},
				APIServerWhitelist:         []string{},
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
