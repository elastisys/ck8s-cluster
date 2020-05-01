package client

import (
	"io/ioutil"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
)

var roundTripTests = map[string]api.Cluster{
	// TODO: clusterType
	"testdata/exoscale.tfvars": exoscale.Empty(api.ServiceCluster),
	// TODO
	// "testdata/safespring.tfvars": &api.SafespringTFVars{},
}

func TestTFVarsRoundTrip(t *testing.T) {
	for path, cluster := range roundTripTests {
		input, err := ioutil.ReadFile(path)
		if err != nil {
			t.Fatalf("error reading test data: %s", err)
		}

		if err := tfvarsDecode(input, cluster.TFVars()); err != nil {
			t.Fatalf("error parsing tfvars: %s", err)
		}

		output := tfvarsEncode(cluster.TFVars())

		if diff := cmp.Diff(input, output); diff != "" {
			t.Errorf("mismatch (-input +output):\n%s", diff)
		}
	}
}
