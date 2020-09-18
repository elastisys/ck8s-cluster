package client

import (
	"errors"
	"io/ioutil"
	"os"
	"path"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
	"go.uber.org/zap"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/runner"
	"github.com/elastisys/ck8s/testutil"
)

type fakeRunner struct{}

func (r *fakeRunner) Run(*runner.Command) error {
	return nil
}

func (r *fakeRunner) Background(*runner.Command) error {
	return nil
}

func (r *fakeRunner) Output(*runner.Command) error {
	return nil
}

func setupClusterClient(
	t *testing.T,
	logger *zap.Logger,
	clusterType api.ClusterType,
	cluster api.Cluster,
) (*ClusterClient, string) {
	// TODO: Get around needing filesystem access.
	dir, err := ioutil.TempDir("/tmp", "ck8s-test")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(path.Join(dir, "terraform/tfe"), 0755); err != nil {
		t.Fatal(err)
		os.RemoveAll(dir)
	}
	if err := os.MkdirAll(
		path.Join(dir, "terraform/exoscale"),
		0755,
	); err != nil {
		t.Fatal(err)
		os.RemoveAll(dir)
	}

	configHandler := NewConfigHandler(
		logger,
		api.ServiceCluster,
		api.NewConfigPath(dir, api.ServiceCluster),
		api.NewCodePath(dir, api.ServiceCluster),
	)

	c, err := NewClusterClient(
		logger,
		cluster,
		configHandler,
		&fakeRunner{},
		false,
		false,
	)
	if err != nil {
		t.Fatal(err)
	}

	return c, dir
}

func teardownClusterClient(dir string) {
	os.RemoveAll(dir)
}

func TestAddMachine(t *testing.T) {
	clusterType := api.ServiceCluster

	cloudProvider := exoscale.NewCloudProvider()

	cluster := cloudProvider.Default(clusterType, "test")

	size := "size"
	latestImageMaster := api.LatestImage(cloudProvider, api.Master)
	latestImageWorker := api.LatestImage(cloudProvider, api.Master)
	firstImageMaster := cloudProvider.MachineImages(api.Master)[0]
	esLocalStorageCapacity := 10
	providerSettings := &exoscale.MachineSettings{
		ESLocalStorageCapacity: esLocalStorageCapacity,
	}

	for _, testCase := range []struct {
		machine          *api.Machine
		name             string
		nodeType         api.NodeType
		size             string
		image            string
		providerSettings map[string]interface{}
	}{{
		&api.Machine{
			NodeType: api.Master,
			Size:     size,
			Image:    latestImageMaster,
		},
		"",
		api.Master,
		size,
		"",
		nil,
	}, {
		&api.Machine{
			NodeType: api.Worker,
			Size:     size,
			Image:    latestImageWorker,
		},
		"",
		api.Worker,
		size,
		"",
		nil,
	}, {
		&api.Machine{
			NodeType: api.Master,
			Size:     size,
			Image:    firstImageMaster,
		},
		"",
		api.Master,
		size,
		firstImageMaster,
		nil,
	}, {
		&api.Machine{
			NodeType:         api.Master,
			Size:             size,
			Image:            firstImageMaster,
			ProviderSettings: providerSettings,
		},
		"",
		api.Master,
		size,
		firstImageMaster,
		map[string]interface{}{
			"es_local_storage_capacity": esLocalStorageCapacity,
		},
	}, {
		&api.Machine{
			NodeType:         api.Master,
			Size:             size,
			Image:            firstImageMaster,
			ProviderSettings: providerSettings,
		},
		"master-1",
		api.Master,
		size,
		firstImageMaster,
		map[string]interface{}{
			"es_local_storage_capacity": esLocalStorageCapacity,
		},
	}} {
		logTest, logger := testutil.NewTestLogger([]string{
			"client_machine_add",
			"client_terraform_plan_no_diff",
			"terraform_init",
			"terraform_plan_no_diff",
		})

		clusterClient, dir := setupClusterClient(
			t,
			logger,
			clusterType,
			cluster,
		)
		defer teardownClusterClient(dir)

		gotName, err := clusterClient.AddMachine(
			testCase.name,
			testCase.nodeType,
			testCase.size,
			testCase.image,
			testCase.providerSettings,
		)
		if err != nil {
			t.Errorf("error adding machine: %s", err)
		}

		gotMachine, ok := cluster.Machines()[gotName]
		if !ok {
			t.Errorf("machine not found after adding: %s", gotName)
		}

		if diff := cmp.Diff(testCase.machine, gotMachine); diff != "" {
			t.Errorf("cloned machine mismatch (-want +got):\n%s", diff)
		}

		if testCase.name != "" {
			if gotName != testCase.name {
				t.Errorf("name want: %s, got: %s", testCase.name, gotName)
			}
		}

		logTest.Diff(t)
	}
}

func TestAddMachineUnsupportedImageError(t *testing.T) {
	clusterType := api.ServiceCluster

	logTest, logger := testutil.NewTestLogger([]string{
		"client_machine_add",
		"client_terraform_plan_no_diff",
		"terraform_init",
		"terraform_plan_no_diff",
	})

	cloudProvider := exoscale.NewCloudProvider()

	cluster := cloudProvider.Default(clusterType, "test")

	clusterClient, dir := setupClusterClient(t, logger, clusterType, cluster)
	defer teardownClusterClient(dir)

	_, err := clusterClient.AddMachine("", api.Master, "size", "foo", nil)

	var imageErr *api.UnsupportedImageError
	if !errors.As(err, &imageErr) {
		t.Errorf("expected api.UnsupportedImageError, got: %s", err)
	}

	logTest.Diff(t)
}

func TestCloneMachine(t *testing.T) {
	clusterType := api.ServiceCluster

	logTest, logger := testutil.NewTestLogger([]string{
		"client_machine_clone",
		"client_terraform_plan_no_diff",
		"terraform_init",
		"terraform_plan_no_diff",
		"client_configured_machines",
	})

	cloudProvider := exoscale.NewCloudProvider()

	cluster := cloudProvider.Default(clusterType, "test")

	machineName := "foo"

	if _, err := cluster.AddMachine(machineName, &api.Machine{
		NodeType: api.Master,
		Size:     "size",
		Image:    "image",
		ProviderSettings: &exoscale.MachineSettings{
			ESLocalStorageCapacity: 10,
		},
	}); err != nil {
		t.Fatal(err)
	}

	clusterClient, dir := setupClusterClient(t, logger, clusterType, cluster)
	defer teardownClusterClient(dir)

	cloneMachineName, err := clusterClient.CloneMachine(machineName, "")
	if err != nil {
		t.Errorf("error cloning machine: %s", err)
	}

	wantMachines := map[string]*api.Machine{
		machineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    "image",
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
		cloneMachineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    "image",
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
	}

	if diff := cmp.Diff(wantMachines, cluster.Machines()); diff != "" {
		t.Errorf("cloned machine mismatch (-want +got):\n%s", diff)
	}

	logTest.Diff(t)
}

func TestCloneMachineWithImage(t *testing.T) {
	clusterType := api.ServiceCluster

	logTest, logger := testutil.NewTestLogger([]string{
		"client_machine_clone",
		"client_terraform_plan_no_diff",
		"terraform_init",
		"terraform_plan_no_diff",
		"client_configured_machines",
	})

	cloudProvider := exoscale.NewCloudProvider()

	cluster := cloudProvider.Default(clusterType, "test")

	machineName := "foo"

	image := cloudProvider.MachineImages(api.Master)[0]

	if _, err := cluster.AddMachine(
		machineName,
		&api.Machine{
			NodeType: api.Master,
			Size:     "size",
			Image:    "image",
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
	); err != nil {
		t.Fatal(err)
	}

	clusterClient, dir := setupClusterClient(t, logger, clusterType, cluster)
	defer teardownClusterClient(dir)

	cloneMachineName, err := clusterClient.CloneMachine(machineName, image)
	if err != nil {
		t.Errorf("error cloning machine: %s", err)
	}

	wantMachines := map[string]*api.Machine{
		machineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    "image",
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
		cloneMachineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    image,
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
	}

	if diff := cmp.Diff(wantMachines, cluster.Machines()); diff != "" {
		t.Errorf("cloned machine mismatch (-want +got):\n%s", diff)
	}

	logTest.Diff(t)
}

func TestCloneMachineNotFoundError(t *testing.T) {
	clusterType := api.ServiceCluster

	logTest, logger := testutil.NewTestLogger([]string{
		"client_machine_clone",
		"client_terraform_plan_no_diff",
		"terraform_init",
		"terraform_plan_no_diff",
		"client_configured_machines",
	})

	cloudProvider := exoscale.NewCloudProvider()

	cluster := cloudProvider.Default(clusterType, "test")

	clusterClient, dir := setupClusterClient(t, logger, clusterType, cluster)
	defer teardownClusterClient(dir)

	_, err := clusterClient.CloneMachine("foo", "")

	// TODO: Create custom machine not found error
	if err == nil || !strings.Contains(err.Error(), "machine not found") {
		t.Errorf("expected 'machine not found' error, got: %s", err)
	}

	logTest.Diff(t)
}

func TestCloneMachineUnsupportedImageError(t *testing.T) {
	clusterType := api.ServiceCluster

	logTest, logger := testutil.NewTestLogger([]string{
		"client_machine_clone",
		"client_terraform_plan_no_diff",
		"terraform_init",
		"terraform_plan_no_diff",
		"client_configured_machines",
	})

	cloudProvider := exoscale.NewCloudProvider()

	cluster := cloudProvider.Default(clusterType, "test")

	machineName := "foo"

	if _, err := cluster.AddMachine(machineName, &api.Machine{
		NodeType: api.Master,
		Size:     "size",
		Image:    "image",
		ProviderSettings: &exoscale.MachineSettings{
			ESLocalStorageCapacity: 10,
		},
	}); err != nil {
		t.Fatal(err)
	}

	clusterClient, dir := setupClusterClient(t, logger, clusterType, cluster)
	defer teardownClusterClient(dir)

	_, err := clusterClient.CloneMachine(machineName, "foo")

	var imageErr *api.UnsupportedImageError
	if !errors.As(err, &imageErr) {
		t.Errorf("expected api.UnsupportedImageError, got: %s", err)
	}

	logTest.Diff(t)
}
