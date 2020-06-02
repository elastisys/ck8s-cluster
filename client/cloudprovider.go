package client

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
)

func CloudProviderFromType(
	cloudProviderType api.CloudProviderType,
) (api.CloudProvider, error) {
	switch cloudProviderType {
	case api.Exoscale:
		return exoscale.NewCloudProvider(), nil
	}
	return nil, api.NewUnsupportedCloudProviderError(cloudProviderType)
}
