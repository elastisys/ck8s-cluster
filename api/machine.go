package api

import (
	"encoding/json"
	"fmt"

	"github.com/mitchellh/mapstructure"
)

type NodeType string

const (
	Master       NodeType = "master"
	Worker       NodeType = "worker"
	LoadBalancer NodeType = "loadbalancer"
)

type Machine struct {
	NodeType NodeType `json:"node_type" validate:"required"`
	Size     string   `json:"size" validate:"required"`
	Image    string   `json:"image" validate:"required"`

	// TODO: Could add the omitempty json tag once Terraform supports optional
	// object arguments.
	// https://github.com/hashicorp/terraform/issues/19898
	ProviderSettings interface{} `json:"provider_settings"`
}

type MachineState struct {
	Machine

	PublicIP  string
	PrivateIP string
}

type MachineFactory struct {
	cloudProvider CloudProvider

	machine *Machine
}

// NewMachineFactoryFromExistingMachine returns a MachineFactory which starts
// with an existing Machine. This is useful when cloning or replacing a machine
// and some values needs to be changed.
func NewMachineFactoryFromExistingMachine(
	cloudProvider CloudProvider,
	machine *Machine,
) *MachineFactory {
	machineCopy := &Machine{
		NodeType: machine.NodeType,
		Size:     machine.Size,
		Image:    machine.Image,
	}

	// TODO: This is very ugly. Might want to introduce a deep copy library or
	// just find a better way to deal with provider specific machine settings.
	if machine.ProviderSettings != nil {
		data, err := json.Marshal(
			machine.ProviderSettings,
		)
		if err != nil {
			panic(err)
		}
		if err := json.Unmarshal(
			data,
			&machineCopy.ProviderSettings,
		); err != nil {
			panic(err)
		}
		if err := decodeMachine(cloudProvider, machineCopy); err != nil {
			panic(err)
		}
	}

	return &MachineFactory{
		cloudProvider: cloudProvider,
		machine:       machineCopy,
	}
}

// NewMachineFactory returns a MachineFactory which is used to build a Machine.
func NewMachineFactory(
	cloudProvider CloudProvider,
	nodeType NodeType,
	size string,
) *MachineFactory {
	return &MachineFactory{
		cloudProvider: cloudProvider,
		machine: &Machine{
			NodeType: nodeType,
			Size:     size,
			Image:    LatestImage(cloudProvider, nodeType),
		},
	}
}

// WithImage sets the image of the Machine.
func (f *MachineFactory) WithImage(image string) *MachineFactory {
	f.machine.Image = image
	return f
}

// WithProviderSettings sets cloud provider specific parameters on the Machine.
func (f *MachineFactory) WithProviderSettings(
	providerSettingsMap map[string]interface{},
) *MachineFactory {
	f.machine.ProviderSettings = providerSettingsMap
	return f
}

// Build returns the finished Machine. It returns an UnsupportedImageError if
// the image is not supported by the cloud provider.
func (f *MachineFactory) Build() (*Machine, error) {
	image := f.machine.Image
	if !ImageIsSupported(f.cloudProvider, f.machine.NodeType, image) {
		return f.machine, NewUnsupportedImageError(
			f.cloudProvider.Type(),
			image,
		)
	}

	if err := decodeMachine(
		f.cloudProvider,
		f.machine,
	); err != nil {
		return f.machine, fmt.Errorf(
			"error decoding machine: %w", err,
		)
	}

	return f.machine, nil
}

// MustBuild runs Build() except that it panics if there is an error.
func (f *MachineFactory) MustBuild() *Machine {
	machine, err := f.Build()
	if err != nil {
		panic(err)
	}
	return machine
}

// LatestImage returns the latest supported image for the cloud provider.
func LatestImage(cloudProvider CloudProvider, nodeType NodeType) string {
	images := cloudProvider.MachineImages(nodeType)
	return images[len(images)-1]
}

// ImageIsSupported returns true if the image is supported by the cloud
// provider.
func ImageIsSupported(
	cloudProvider CloudProvider,
	nodeType NodeType,
	image string,
) bool {
	for _, supportedImage := range cloudProvider.MachineImages(nodeType) {
		if image == supportedImage {
			return true
		}
	}
	return false
}

func decodeMachine(
	cloudProvider CloudProvider,
	machine *Machine,
) error {
	if machine.ProviderSettings == nil {
		return nil
	}

	providerSettings := cloudProvider.MachineSettings()

	decoder, err := mapstructure.NewDecoder(&mapstructure.DecoderConfig{
		Metadata: nil,
		Result:   providerSettings,
		TagName:  "json",
	})
	if err != nil {
		return err
	}

	if err := decoder.Decode(machine.ProviderSettings); err != nil {
		return fmt.Errorf("error decoding provider machine settings: %w", err)
	}

	machine.ProviderSettings = providerSettings

	return nil
}
