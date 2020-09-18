package api

import (
	"errors"
	"fmt"
)

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

// PathError is any general errors related to a Path.
type PathError struct {
	Path Path

	Err error
}

func NewPathError(p Path, e error) *PathError {
	return &PathError{p, e}
}

func (e *PathError) Error() string {
	return fmt.Sprintf("path error (%s): %s", e.Path, e.Err)
}

func (e *PathError) Unwrap() error {
	return e.Err
}

// PathNotFoundErr is returned if a file or directory is not found.
var PathNotFoundErr = errors.New("not found")

// MachineStateNotFoundError is returned if a machine is not found.
type MachineStateNotFoundError struct {
	Name string
}

func (e *MachineStateNotFoundError) Error() string {
	return fmt.Sprintf("machine not found: %s", e.Name)
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

type UnsupportedImageError struct {
	CloudProvider CloudProviderType
	Image         string
}

func NewUnsupportedImageError(
	c CloudProviderType,
	i string,
) *UnsupportedImageError {
	return &UnsupportedImageError{c, i}
}

func (e *UnsupportedImageError) Error() string {
	return fmt.Sprintf(
		"unsupported image for cloud provider '%s': %s",
		e.CloudProvider, e.Image,
	)
}

type MachineAlreadyExistsError struct {
	name string
}

func NewMachineAlreadyExistsError(n string) *MachineAlreadyExistsError {
	return &MachineAlreadyExistsError{n}
}

func (e *MachineAlreadyExistsError) Error() string {
	return fmt.Sprintf("machine already exists: %s", e.name)
}
