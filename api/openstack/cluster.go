package openstack

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
)

type Cluster struct {
	Config Config
	Secret Secret
	TFVars TFVars
}

func Default(
	clusterType api.ClusterType,
	cloudProviderType api.CloudProviderType,
	clusterName string,
) *Cluster {
	return &Cluster{
		Config: Config{
			BaseConfig: *api.DefaultBaseConfig(
				clusterType,
				cloudProviderType,
				clusterName,
			),

			ProjectID:         "changeme",
			ProjectDomainName: "changeme",
			UserDomainName:    "changeme",
		},
		Secret: Secret{
			Username: "changeme",
			Password: "changeme",
		},
		TFVars: TFVars{
			PublicIngressCIDRWhitelist: []string{},
			APIServerWhitelist:         []string{},
			NodeportWhitelist:          []string{},
		},
	}
}

func (e *Cluster) CloudProvider() api.CloudProviderType {
	return e.Config.CloudProviderType
}

func (e *Cluster) Name() string {
	switch e.Config.ClusterType {
	case api.ServiceCluster:
		if e.TFVars.PrefixSC != "" {
			return e.TFVars.PrefixSC
		}
	case api.WorkloadCluster:
		if e.TFVars.PrefixWC != "" {
			return e.TFVars.PrefixWC
		}
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.Config.ClusterType))
	}

	return api.NameHelper(&e.Config.BaseConfig)
}

func (e *Cluster) OIDCConfig() map[string]string {
	config := map[string]string{}

	config["oidc_issuer_url"] = e.Config.OIDCIssuerURL
	config["oidc_client_id"] = e.Config.OIDCClientId
	config["oidc_username_claim"] = e.Config.OIDCUsernameClaim
	config["oidc_groups_claim"] = e.Config.OIDCGroupsClaim
	return config
}

func (e *Cluster) TerraformWorkspace() string {
	return e.Config.EnvironmentName
}

func (e *Cluster) TerraformEnv(sshPublicKey string) map[string]string {
	env := api.TerraformEnvHelper(&e.Config.BaseConfig, sshPublicKey)

	env["OS_USERNAME"] = e.Secret.Username
	env["OS_PASSWORD"] = e.Secret.Password
	env["OS_IDENTITY_API_VERSION"] = e.Config.IdentityAPIVersion
	env["OS_AUTH_URL"] = e.Config.AuthURL
	env["OS_REGION_NAME"] = e.Config.RegionName
	env["OS_USER_DOMAIN_NAME"] = e.Config.UserDomainName
	env["OS_PROJECT_DOMAIN_NAME"] = e.Config.ProjectDomainName
	env["OS_PROJECT_ID"] = e.Config.ProjectID

	return env
}

func (e *Cluster) AnsibleEnv() map[string]string {
	env := map[string]string{}

	env["OS_USERNAME"] = e.Secret.Username
	env["OS_PASSWORD"] = e.Secret.Password
	env["OS_IDENTITY_API_VERSION"] = e.Config.IdentityAPIVersion
	env["OS_AUTH_URL"] = e.Config.AuthURL
	env["OS_REGION_NAME"] = e.Config.RegionName
	env["OS_USER_DOMAIN_NAME"] = e.Config.UserDomainName
	env["OS_PROJECT_DOMAIN_NAME"] = e.Config.ProjectDomainName
	env["OS_PROJECT_ID"] = e.Config.ProjectID

	return env
}
