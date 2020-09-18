package client

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/aws"
	"github.com/elastisys/ck8s/api/citycloud"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/api/openstack"
	"github.com/elastisys/ck8s/api/safespring"
	"github.com/elastisys/ck8s/testutil"
)

func TestTFVarsRead(t *testing.T) {
	clusterType := api.ServiceCluster

	type testCase struct {
		path string
		want interface{}
		got  api.Cluster
	}

	for _, tc := range []testCase{{
		path: "testdata/exoscale-tfvars.json",
		want: &exoscale.ExoscaleTFVars{
			MachinesSC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "Small",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "Extra-large",
					ProviderSettings: &exoscale.MachineSettings{
						ESLocalStorageCapacity: 26,
					},
				},
				"worker-1": {
					NodeType: api.Worker,
					Size:     "Large",
					ProviderSettings: &exoscale.MachineSettings{
						ESLocalStorageCapacity: 26,
					},
				},
			},
			MachinesWC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "Small",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "Large",
				},
			},
			NFSSize:                    "Small",
			PublicIngressCIDRWhitelist: []string{"1.2.3.4/32", "4.3.2.1/32"},
			APIServerWhitelist:         []string{"1.2.3.4/32", "4.3.2.1/32"},
			NodeportWhitelist:          []string{"1.2.3.4/32", "4.3.2.1/32"},
		},
		got: exoscale.Default(clusterType, ""),
	}, {
		path: "testdata/citycloud-tfvars.json",
		want: &openstack.TFVars{
			MachinesSC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "96c7903e-32f0-421d-b6a2-a45c97b15665",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "d430b3cd-0216-43ff-878c-c08689c0001b",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"worker-1": {
					NodeType: api.Worker,
					Size:     "572a3b2e-6329-4053-b872-aecb1e70d8a6",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
			},
			MachinesWC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "96c7903e-32f0-421d-b6a2-a45c97b15665",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "572a3b2e-6329-4053-b872-aecb1e70d8a6",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
			},
			MasterAntiAffinityPolicySC: "anti-affinity",
			MasterAntiAffinityPolicyWC: "anti-affinity",
			PublicIngressCIDRWhitelist: []string{"1.2.3.4/32", "4.3.2.1/32"},
			APIServerWhitelist:         []string{"1.2.3.4/32", "4.3.2.1/32"},
			NodeportWhitelist:          []string{"1.2.3.4/32", "4.3.2.1/32"},
			ExternalNetworkID:          "2aec7a99-3783-4e2a-bd2b-bbe4fef97d1c",
			ExternalNetworkName:        "ext-net",
			AWSDNSZoneID:               "testAWSDNSZoneID",
			AWSDNSRoleARN:              "testAWSDNSRoleARN",
		},
		got: citycloud.Default(clusterType, ""),
	}, {
		path: "testdata/safespring-tfvars.json",
		want: &openstack.TFVars{
			MachinesSC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "dc67a9eb-0685-4bb6-9383-a01c717e02e8",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"worker-1": {
					NodeType: api.Worker,
					Size:     "dc67a9eb-0685-4bb6-9383-a01c717e02e8",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"loadbalancer-0": {
					NodeType: api.LoadBalancer,
					Size:     "51d480b8-2517-4ba8-bfe0-c649ac93eb61",
					Image:    "3afb071a-ac91-4713-8c86-9fab4e78b863",
				},
			},
			MachinesWC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "dc67a9eb-0685-4bb6-9383-a01c717e02e8",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "dc67a9eb-0685-4bb6-9383-a01c717e02e8",
					Image:    "3092f981-a271-4f93-add3-fcc8742ceb0e",
				},
				"loadbalancer-0": {
					NodeType: api.LoadBalancer,
					Size:     "51d480b8-2517-4ba8-bfe0-c649ac93eb61",
					Image:    "3afb071a-ac91-4713-8c86-9fab4e78b863",
				},
			},
			MasterAntiAffinityPolicySC: "anti-affinity",
			MasterAntiAffinityPolicyWC: "anti-affinity",
			WorkerAntiAffinityPolicySC: "anti-affinity",
			WorkerAntiAffinityPolicyWC: "anti-affinity",
			PublicIngressCIDRWhitelist: []string{"1.2.3.4/32", "4.3.2.1/32"},
			APIServerWhitelist:         []string{"1.2.3.4/32", "4.3.2.1/32"},
			NodeportWhitelist:          []string{"1.2.3.4/32", "4.3.2.1/32"},
			ExternalNetworkID:          "2aec7a99-3783-4e2a-bd2b-bbe4fef97d1c",
			ExternalNetworkName:        "ext-net",
			AWSDNSZoneID:               "testAWSDNSZoneID",
			AWSDNSRoleARN:              "testAWSDNSRoleARN",
		},
		got: safespring.Default(clusterType, ""),
	}, {
		path: "testdata/aws-tfvars.json",
		want: &aws.AWSTFVars{
			Region: "us-west-1",
			MachinesSC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "t3.small",
					Image:    "ami-025fd2f1456a0e2e5",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "t3.xlarge",
					Image:    "ami-025fd2f1456a0e2e5",
				},
				"worker-1": {
					NodeType: api.Worker,
					Size:     "t3.large",
					Image:    "ami-025fd2f1456a0e2e5",
				},
			},
			MachinesWC: map[string]*api.Machine{
				"master-0": {
					NodeType: api.Master,
					Size:     "t3.small",
					Image:    "ami-025fd2f1456a0e2e5",
				},
				"worker-0": {
					NodeType: api.Worker,
					Size:     "t3.large",
					Image:    "ami-025fd2f1456a0e2e5",
				},
				"worker-1": {
					NodeType: api.Worker,
					Size:     "t3.large",
					Image:    "ami-025fd2f1456a0e2e5",
				},
			},
			PublicIngressCIDRWhitelist: []string{"1.2.3.4/32", "4.3.2.1/32"},
			APIServerWhitelist:         []string{"1.2.3.4/32", "4.3.2.1/32"},
			NodeportWhitelist:          []string{"1.2.3.4/32", "4.3.2.1/32"},
		},
		got: aws.Default(clusterType, ""),
	}} {
		logTest, logger := testutil.NewTestLogger([]string{
			"config_handler_tfvars_read",
		})

		configHandler := NewConfigHandler(
			logger,
			clusterType,
			api.ConfigPath{
				api.TFVarsFile: {
					Path:   tc.path,
					Format: "json",
				},
			},
			api.CodePath{},
		)

		if err := configHandler.readTFVars(tc.got); err != nil {
			t.Fatalf("error reading tfvars (%s): %s", tc.path, err)
		}

		if diff := cmp.Diff(tc.want, tc.got.TFVars()); diff != "" {
			t.Errorf("%s mismatch (-want +got):\n%s", tc.path, diff)
		}

		logTest.Diff(t)
	}
}
