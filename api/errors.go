package api

import "fmt"

// UnsupportedCloudProviderError is returned if an operation is not supported
// by the cloud provider.
type UnsupportedCloudProviderError struct {
	CloudProvider CloudProviderType
}

func NewUnsupportedCloudProviderError(c CloudProviderType) error {
	return &UnsupportedCloudProviderError{c}
}

func (e *UnsupportedCloudProviderError) Error() string {
	return fmt.Sprintf("unsupported cloud provider: %s", e.CloudProvider)
}

// PathNotFoundError is returned if a file or directory is not found.
type PathNotFoundError struct {
	Path Path
}

func (e *PathNotFoundError) Error() string {
	return fmt.Sprintf("path not found: %s", e.Path.Path)
}

// MachineStateNotFoundError is returned if a machine is not found.
type MachineStateNotFoundError struct {
	NodeType NodeType
	Name     string
}

func (e *MachineStateNotFoundError) Error() string {
	return fmt.Sprintf(
		"machine not found (node type '%s'): %s",
		e.NodeType, e.Name,
	)
}

type UnsupportedClusterFlavorError struct {
	CloudProvider CloudProviderType
	ClusterFlavor ClusterFlavor
}

func NewUnsupportedClusterFlavorError(
	c CloudProviderType,
	f ClusterFlavor,
) *UnsupportedClusterFlavorError {
	return &UnsupportedClusterFlavorError{c, f}
}

func (e *UnsupportedClusterFlavorError) Error() string {
	return fmt.Sprintf(
		"unsupported cluster flavor for cloud provider '%s': %s",
		e.CloudProvider, e.ClusterFlavor,
	)
}
