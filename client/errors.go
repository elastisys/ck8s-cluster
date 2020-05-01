package client

import "fmt"

// UnknownCloudProviderError is returned if a cloud provider is not defined
// in the API.
type UnknownCloudProviderError struct {
	CloudProviderName string
}

func (e *UnknownCloudProviderError) Error() string {
	return fmt.Sprintf("unknown cloud provider: %s", e.CloudProviderName)
}
