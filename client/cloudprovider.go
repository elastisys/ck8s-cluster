package client

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/api/safespring"
)

func CloudProviderFromType(
	cloudProviderType api.CloudProviderType,
) (api.CloudProvider, error) {
	switch cloudProviderType {
	case api.Exoscale:
		return exoscale.NewCloudProvider(), nil
	case api.Safespring:
		return safespring.NewCloudProvider(), nil
	}
	return nil, api.NewUnsupportedCloudProviderError(cloudProviderType)
}
