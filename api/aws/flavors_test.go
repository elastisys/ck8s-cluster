package aws

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"

	"github.com/elastisys/ck8s/api"
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
					ClusterType:       clusterType,
					CloudProviderType: api.AWS,
					EnvironmentName:   clusterName,
					OIDCIssuerURL:     "set-me",
					OIDCClientId:      "kubelogin",
					OIDCUsernameClaim: "email",
					OIDCGroupsClaim:   "groups",
				},
			},
			secret: AWSSecret{
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
				ExtraTags:                  map[string]string{},
			},
		},
		got: Default(clusterType, clusterName),
	}, {
		want: &Cluster{
			config: AWSConfig{
				BaseConfig: api.BaseConfig{
					ClusterType:       clusterType,
					CloudProviderType: api.AWS,
					EnvironmentName:   clusterName,
					OIDCIssuerURL:     "set-me",
					OIDCClientId:      "kubelogin",
					OIDCUsernameClaim: "email",
					OIDCGroupsClaim:   "groups",
				},
			},
			secret: AWSSecret{
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
				ExtraTags:                  map[string]string{},

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
					ClusterType:       clusterType,
					CloudProviderType: api.AWS,
					EnvironmentName:   clusterName,
					OIDCIssuerURL:     "set-me",
					OIDCClientId:      "kubelogin",
					OIDCUsernameClaim: "email",
					OIDCGroupsClaim:   "groups",
				},
			},
			secret: AWSSecret{
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
				ExtraTags:                  map[string]string{},

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
