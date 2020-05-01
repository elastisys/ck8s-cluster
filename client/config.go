package client

import (
	"bytes"
	"fmt"
	"io/ioutil"

	"github.com/spf13/viper"
	"go.mozilla.org/sops/v3/decrypt"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
)

func ClusterFromConfigPath(
	clusterType api.ClusterType,
	path api.ConfigPath,
) (api.Cluster, error) {
	cluster, err := parseConfig(clusterType, path[api.ConfigFile])
	if err != nil {
		return nil, fmt.Errorf("error parsing config: %w", err)
	}

	if err = parseSecrets(cluster, path[api.SecretsFile]); err != nil {
		return nil, fmt.Errorf("error parsing secrets: %w", err)
	}

	if err := parseTFVars(cluster, path[api.TFVarsFile]); err != nil {
		return nil, fmt.Errorf("error parsing tfvars: %w", err)
	}

	if err := api.ValidateCluster(cluster); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	return cluster, nil
}

func parseConfig(
	clusterType api.ClusterType,
	configPath api.Path,
) (api.Cluster, error) {
	path, name, ext := splitPath(configPath.Path)

	v := viper.New()
	v.SetConfigName(name + "." + ext)
	v.SetConfigType(configPath.Format)
	v.AddConfigPath(path)

	if err := v.ReadInConfig(); err != nil {
		return nil, err
	}

	cloudProviderValue := v.GetString("cloud_provider")
	if cloudProviderValue == "" {
		return nil, fmt.Errorf("missing cloud provider in config")
	}

	var cluster api.Cluster

	switch api.CloudProviderType(cloudProviderValue) {
	case api.AWS:
		return nil, api.NewUnsupportedCloudProviderError(api.AWS)
	case api.CityCloud:
		return nil, api.NewUnsupportedCloudProviderError(api.CityCloud)
	case api.Exoscale:
		cluster = exoscale.Default(clusterType)
	case api.Safespring:
		return nil, api.NewUnsupportedCloudProviderError(api.Safespring)
	default:
		return nil, &UnknownCloudProviderError{cloudProviderValue}
	}

	if err := v.Unmarshal(&cluster); err != nil {
		return nil, fmt.Errorf("error decoding config: %w", err)
	}

	return cluster, nil
}

func parseSecrets(cluster api.Cluster, secretsPath api.Path) error {
	v := viper.New()
	v.SetConfigType(secretsPath.Format)

	cleartext, err := decrypt.File(secretsPath.Path, secretsPath.Format)
	if err != nil {
		return fmt.Errorf("failed to decrypt %s: %s", secretsPath, err)
	}

	if err := v.ReadConfig(bytes.NewBuffer(cleartext)); err != nil {
		return err
	}

	if err := v.Unmarshal(&cluster); err != nil {
		return fmt.Errorf("error decoding secrets: %w", err)
	}

	return nil
}

func parseTFVars(cluster api.Cluster, tfvarsPath api.Path) error {
	tfvarsData, err := ioutil.ReadFile(tfvarsPath.Path)
	if err != nil {
		return fmt.Errorf("error reading tfvars: %w", err)
	}

	if err := tfvarsDecode(tfvarsData, cluster.TFVars()); err != nil {
		return fmt.Errorf("error decoding tfvars: %w", err)
	}

	return nil
}
