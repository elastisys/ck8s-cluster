package api

import (
	"fmt"
	"os"
	"path"
)

type Path struct {
	Path   string
	Format string
}

func (p Path) String() string {
	return fmt.Sprintf("[path: %s, format: %s]", p.Path, p.Format)
}

func (p Path) Exists() error {
	if _, err := os.Stat(p.Path); err != nil {
		if os.IsNotExist(err) {
			return &PathNotFoundError{p}
		}
		return fmt.Errorf("error checking path %s: %w", p, err)
	}
	return nil
}

type ConfigPathID int

const (
	ConfigFile ConfigPathID = iota
	SecretsFile
	TFBackendConfigFile
	TFVarsFile
	SSHPublicKeyFile
	SSHPrivateKeyFile
	TFDataDir
	AnsibleInventoryFile
	SOPSConfigFile
	KubeconfigFile
	S3CfgFile
)

type CodePathID int

const (
	AnsibleConfigFile CodePathID = iota
	AnsiblePlaybookDeployKubernetesFile
	AnsiblePlaybookPrepareNodesFile
	AnsiblePlaybookJoinClusterFile
	ManageS3BucketsScriptFile
	CRDFile
)

var relativeConfigPaths = map[ConfigPathID]Path{
	ConfigFile:          {"config.sh", "dotenv"},
	SecretsFile:         {"secrets.env", "dotenv"},
	TFBackendConfigFile: {"backend_config.hcl", "hclv2"},
	TFVarsFile:          {"config.tfvars", "hclv2"},
	TFDataDir:           {".state/.terraform", ""},
	SOPSConfigFile:      {".sops.yaml", "yaml"},
	S3CfgFile:           {".state/s3cfg.ini", "ini"},
}

var clusterSpecificRelativeConfigPaths = map[ClusterType]map[ConfigPathID]Path{
	ServiceCluster: {
		AnsibleInventoryFile: {".state/ansible_hosts_sc.ini", "ini"},
		KubeconfigFile:       {".state/kube_config_sc.yaml", "yaml"},
		SSHPublicKeyFile:     {"ssh/id_rsa_sc.pub", ""},
		SSHPrivateKeyFile:    {"ssh/id_rsa_sc", "binary"},
	},
	WorkloadCluster: {
		AnsibleInventoryFile: {".state/ansible_hosts_wc.ini", "ini"},
		SSHPublicKeyFile:     {"ssh/id_rsa_wc.pub", ""},
		SSHPrivateKeyFile:    {"ssh/id_rsa_wc", "binary"},
		KubeconfigFile:       {".state/kube_config_wc.yaml", "yaml"},
	},
}

var relativeTFPaths = map[CloudProviderType]string{
	Exoscale:   "terraform/exoscale",
	Safespring: "terraform/safespring",
}

var relativeCodePaths = map[CodePathID]Path{
	AnsibleConfigFile: {
		"ansible/ansible.cfg", "ini",
	},
	AnsiblePlaybookDeployKubernetesFile: {
		"ansible/deploy-kubernetes.yml", "yaml",
	},
	AnsiblePlaybookPrepareNodesFile: {
		"ansible/prepare-nodes.yml", "yaml",
	},
	ManageS3BucketsScriptFile: {
		"scripts/manage-s3-buckets.sh", "",
	},
}

var clusterSpecificRelativeCodePaths = map[ClusterType]map[CodePathID]Path{
	ServiceCluster: {
		CRDFile: {"crds/crds-sc.txt", ""},
	},
	WorkloadCluster: {
		CRDFile: {"crds/crds-wc.txt", ""},
	},
}

type ConfigPath map[ConfigPathID]Path

func NewConfigPath(configRootPath string, clusterType ClusterType) ConfigPath {
	configPath := make(
		ConfigPath,
		len(relativeConfigPaths)+
			len(clusterSpecificRelativeConfigPaths[clusterType]),
	)
	for id, p := range relativeConfigPaths {
		configPath[id] = Path{
			Path:   path.Join(configRootPath, p.Path),
			Format: p.Format,
		}
	}
	for id, p := range clusterSpecificRelativeConfigPaths[clusterType] {
		configPath[id] = Path{
			Path:   path.Join(configRootPath, p.Path),
			Format: p.Format,
		}
	}
	return configPath
}

type CodePath map[CodePathID]Path

func NewCodePath(codeRootPath string, clusterType ClusterType) CodePath {
	codePath := make(CodePath, len(relativeCodePaths))
	for id, p := range relativeCodePaths {
		codePath[id] = Path{
			Path:   path.Join(codeRootPath, p.Path),
			Format: p.Format,
		}
	}
	for id, p := range clusterSpecificRelativeCodePaths[clusterType] {
		codePath[id] = Path{
			Path:   path.Join(codeRootPath, p.Path),
			Format: p.Format,
		}
	}
	return codePath
}

func TerraformPath(
	codeRootPath string,
	cloudProvider CloudProviderType,
) (Path, error) {
	relativePath, ok := relativeTFPaths[cloudProvider]
	if !ok {
		return Path{}, NewUnsupportedCloudProviderError(cloudProvider)
	}

	return Path{
		Path:   path.Join(codeRootPath, relativePath),
		Format: "hclv2",
	}, nil
}
