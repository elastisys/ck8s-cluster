package client

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	"go.uber.org/zap"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/runner"
	"github.com/elastisys/ck8s/testutil"
)

func setupClusterClient(
	t *testing.T,
	logger *zap.Logger,
	clusterType api.ClusterType,
	cluster api.Cluster,
) (*ClusterClient, *runner.TestRunner, string) {
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

	testRunner := runner.NewTestRunner(t)

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
		testRunner,
		false,
		false,
	)
	if err != nil {
		t.Fatal(err)
	}

	return c, testRunner, dir
}

func teardownClusterClient(dir string) {
	os.RemoveAll(dir)
}

func newTestKubectlServerVersionCommand(
	apiServerVersion string,
) *runner.TestCommand {
	return &runner.TestCommand{
		SkipDiff: true,
		Command:  runner.NewCommand("fake-kubectl-version"),
		Stdout: []byte(fmt.Sprintf(`{
  "clientVersion": {
    "major": "1",
    "minor": "16",
    "gitVersion": "v1.16.2",
    "gitCommit": "c97fe5036ef3df2967d086711e6c0c405941e14b",
    "gitTreeState": "clean",
    "buildDate": "2019-10-15T19:18:23Z",
    "goVersion": "go1.12.10",
    "compiler": "gc",
    "platform": "linux/amd64"
  },
  "serverVersion": {
    "major": "1",
    "minor": "17",
    "gitVersion": "%s",
    "gitCommit": "ea5f00d93211b7c80247bf607cfa422ad6fb5347",
    "gitTreeState": "clean",
    "buildDate": "2020-08-13T15:11:47Z",
    "goVersion": "go1.13.15",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}`, apiServerVersion)),
	}
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
		image            *api.Image
		providerSettings map[string]interface{}
	}{{
		// Master with default values
		&api.Machine{
			NodeType: api.Master,
			Size:     size,
			Image:    latestImageMaster,
		},
		"",
		api.Master,
		size,
		nil,
		nil,
	}, {
		// Worker with default values
		&api.Machine{
			NodeType: api.Worker,
			Size:     size,
			Image:    latestImageWorker,
		},
		"",
		api.Worker,
		size,
		nil,
		nil,
	}, {
		// Custom values
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
			"client_validate_machine",
			"kubectl_server_version",
		})

		clusterClient, testRunner, dir := setupClusterClient(
			t,
			logger,
			clusterType,
			cluster,
		)
		defer teardownClusterClient(dir)

		// terraform init
		testRunner.Push(&runner.TestCommand{SkipDiff: true})

		// terraform plan (no diff)
		testRunner.Push(&runner.TestCommand{SkipDiff: true})

		// kubectl version
		testRunner.Push(newTestKubectlServerVersionCommand(
			latestImageMaster.KubeletVersion.String(),
		))

		imageName := ""
		if testCase.image != nil {
			imageName = testCase.image.Name
		}
		gotName, err := clusterClient.AddMachine(
			testCase.name,
			testCase.nodeType,
			testCase.size,
			imageName,
			testCase.providerSettings,
		)
		if err != nil {
			t.Errorf("error adding machine: %s", err)
		}

		gotMachine, ok := cluster.Machines()[gotName]
		if !ok {
			t.Errorf("machine not found after adding: %s", gotName)
		}

		if diff := cmp.Diff(
			testCase.machine,
			gotMachine,
			cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
		); diff != "" {
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

	clusterClient, testRunner, dir := setupClusterClient(
		t,
		logger,
		clusterType,
		cluster,
	)
	defer teardownClusterClient(dir)

	// terraform init
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// terraform plan (no diff)
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

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
		Image:    api.NewImage("image", "v1.2.3"),
		ProviderSettings: &exoscale.MachineSettings{
			ESLocalStorageCapacity: 10,
		},
	}); err != nil {
		t.Fatal(err)
	}

	clusterClient, testRunner, dir := setupClusterClient(
		t,
		logger,
		clusterType,
		cluster,
	)
	defer teardownClusterClient(dir)

	// terraform init
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// terraform plan (no diff)
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// kubectl version
	testRunner.Push(newTestKubectlServerVersionCommand(
		"v1.2.3",
	))

	cloneMachineName, err := clusterClient.CloneMachine(machineName, "")
	if err != nil {
		t.Errorf("error cloning machine: %s", err)
	}

	wantMachines := map[string]*api.Machine{
		machineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    api.NewImage("image", "v1.2.3"),
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
		cloneMachineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    api.NewImage("image", "v1.2.3"),
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
	}

	if diff := cmp.Diff(
		wantMachines,
		cluster.Machines(),
		cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
	); diff != "" {
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
		"client_validate_machine",
		"kubectl_server_version",
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
			Image:    api.NewImage("image", image.KubeletVersion.String()),
			ProviderSettings: &exoscale.MachineSettings{
				ESLocalStorageCapacity: 10,
			},
		},
	); err != nil {
		t.Fatal(err)
	}

	clusterClient, testRunner, dir := setupClusterClient(
		t,
		logger,
		clusterType,
		cluster,
	)
	defer teardownClusterClient(dir)

	// terraform init
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// terraform plan (no diff)
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// kubectl version
	testRunner.Push(newTestKubectlServerVersionCommand(
		image.KubeletVersion.String(),
	))

	cloneMachineName, err := clusterClient.CloneMachine(
		machineName,
		image.Name,
	)
	if err != nil {
		t.Errorf("error cloning machine: %s", err)
	}

	wantMachines := map[string]*api.Machine{
		machineName: {
			NodeType: api.Master,
			Size:     "size",
			Image:    api.NewImage("image", "v1.2.3"),
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

	if diff := cmp.Diff(
		wantMachines,
		cluster.Machines(),
		cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
	); diff != "" {
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

	clusterClient, testRunner, dir := setupClusterClient(
		t,
		logger,
		clusterType,
		cluster,
	)
	defer teardownClusterClient(dir)

	// terraform init
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// terraform plan (no diff)
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

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
		Image:    api.NewImage("image", "v1.2.3"),
		ProviderSettings: &exoscale.MachineSettings{
			ESLocalStorageCapacity: 10,
		},
	}); err != nil {
		t.Fatal(err)
	}

	clusterClient, testRunner, dir := setupClusterClient(
		t,
		logger,
		clusterType,
		cluster,
	)
	defer teardownClusterClient(dir)

	// terraform init
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	// terraform plan (no diff)
	testRunner.Push(&runner.TestCommand{SkipDiff: true})

	_, err := clusterClient.CloneMachine(machineName, "foo")

	var imageErr *api.UnsupportedImageError
	if !errors.As(err, &imageErr) {
		t.Errorf("expected api.UnsupportedImageError, got: %s", err)
	}

	logTest.Diff(t)
}

func TestValidateMachineInvalidImage(t *testing.T) {
	clusterType := api.ServiceCluster

	for _, testCase := range []struct {
		apiServerVersion string
		wantErr          error
	}{{
		apiServerVersion: "v1.0.0",
		wantErr:          api.ErrInvalidImageKubeletNew,
	}, {
		apiServerVersion: "v1.999.0",
		wantErr:          api.ErrInvalidImageKubeletOld,
	}} {
		logTest, logger := testutil.NewTestLogger([]string{
			"client_validate_machine",
			"kubectl_server_version",
		})

		cloudProvider := exoscale.NewCloudProvider()

		cluster := cloudProvider.Default(clusterType, "test")

		clusterClient, testRunner, dir := setupClusterClient(
			t,
			logger,
			clusterType,
			cluster,
		)
		defer teardownClusterClient(dir)

		// kubectl version
		testRunner.Push(newTestKubectlServerVersionCommand(
			testCase.apiServerVersion,
		))

		// _, err := clusterClient.AddMachine("", api.Master, "size", "", nil)
		err := clusterClient.validateMachine(&api.Machine{
			Image: api.NewImage("testimage", "v1.17.11"),
		})

		if !errors.Is(err, testCase.wantErr) {
			t.Errorf("expected error %s, got: %s", testCase.wantErr, err)
		}

		logTest.Diff(t)
	}
}
