package api

import (
	"encoding/json"
)

func DecodeTFVars(
	cloudProvider CloudProvider,
	data []byte,
	cluster Cluster,
) error {
	if err := json.Unmarshal(data, cluster.TFVars()); err != nil {
		return err
	}

	// This is required to decode the provider specific machine settings.
	// TODO: It would be nice if we could find a nicer way to decode the full
	// tfvars other than doing a second pass on each machine like this.
	for _, machine := range cluster.Machines() {
		if err := decodeMachine(cloudProvider, machine); err != nil {
			return err
		}
	}

	return nil
}
