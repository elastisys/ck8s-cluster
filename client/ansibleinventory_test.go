package client

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/aws"
	"github.com/elastisys/ck8s/api/citycloud"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/api/safespring"
)

func TestRenderAnsibleInventory(t *testing.T) {
	type testCase struct {
		ansibleInventoryPath string
		// TODO: Currently the only reason we need tfvars for the Ansible
		// inventory is the cloud provider vars in citycloud. Let's try to get
		// rid of that.
		tfVarsPath          string
		terraformOutputPath string
		cluster             api.Cluster
	}

	testCases := []testCase{{
		"testdata/exoscale-ansible-hosts-sc.ini",
		"testdata/exoscale-tfvars.json",
		"testdata/exoscale-terraform-output.json",
		exoscale.Default(api.ServiceCluster, "ck8stest"),
	}, {
		"testdata/exoscale-ansible-hosts-wc.ini",
		"testdata/exoscale-tfvars.json",
		"testdata/exoscale-terraform-output.json",
		exoscale.Default(api.WorkloadCluster, "ck8stest"),
	}, {
		"testdata/safespring-ansible-hosts-sc.ini",
		"testdata/safespring-tfvars.json",
		"testdata/safespring-terraform-output.json",
		safespring.Default(api.ServiceCluster, "ck8stest"),
	}, {
		"testdata/safespring-ansible-hosts-wc.ini",
		"testdata/safespring-tfvars.json",
		"testdata/safespring-terraform-output.json",
		safespring.Default(api.WorkloadCluster, "ck8stest"),
	}, {
		"testdata/citycloud-ansible-hosts-sc.ini",
		"testdata/citycloud-tfvars.json",
		"testdata/citycloud-terraform-output.json",
		citycloud.Default(api.ServiceCluster, "ck8stest"),
	}, {
		"testdata/citycloud-ansible-hosts-wc.ini",
		"testdata/citycloud-tfvars.json",
		"testdata/citycloud-terraform-output.json",
		citycloud.Default(api.WorkloadCluster, "ck8stest"),
	}, {
		"testdata/aws-ansible-hosts-sc.ini",
		"testdata/aws-tfvars.json",
		"testdata/aws-terraform-output.json",
		aws.Default(api.ServiceCluster, "ck8stest"),
	}, {
		"testdata/aws-ansible-hosts-wc.ini",
		"testdata/aws-tfvars.json",
		"testdata/aws-terraform-output.json",
		aws.Default(api.WorkloadCluster, "ck8stest"),
	}}

	for _, tc := range testCases {
		var inventory bytes.Buffer

		tfvarsData, err := ioutil.ReadFile(tc.tfVarsPath)
		if err != nil {
			t.Fatal(err)
		}
		cloudProvider, err := CloudProviderFromType(tc.cluster.CloudProvider())
		if err != nil {
			t.Fatal(err)
		}
		if err := api.DecodeTFVars(
			cloudProvider,
			tfvarsData,
			tc.cluster,
		); err != nil {
			t.Fatal(err)
		}

		state, err := tc.cluster.State(func(state interface{}) error {
			tfOutputData, err := ioutil.ReadFile(tc.terraformOutputPath)
			if err != nil {
				return err
			}
			return json.Unmarshal(tfOutputData, state)
		})
		if err != nil {
			t.Fatal(err)
		}

		if err := renderAnsibleInventory(
			tc.cluster,
			state,
			&inventory,
		); err != nil {
			t.Fatal(err)
		}

		f, err := os.Open(tc.ansibleInventoryPath)
		if err != nil {
			t.Fatal(err)
		}

		want, err := ioutil.ReadAll(f)
		if err != nil {
			t.Fatal(err)
		}

		if diff := cmp.Diff(string(want), inventory.String()); diff != "" {
			t.Errorf("log mismatch (-want +got):\n%s", diff)
		}
	}
}
