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
			return NewPathError(p, PathNotFoundErr)
		}
		return NewPathError(p, err)
	}
	return nil
}

type CodePath map[CodePathID]Path
type ConfigPath map[ConfigPathID]Path

type CodePathID int
type ConfigPathID int

const (
	ConfigFile ConfigPathID = iota
	SecretsFile
	TFBackendConfigFile
	TFVarsFile
	SSHPublicKeyFile
	SSHPrivateKeyFile
	TFDataDir
	TFEDataDir
	TFEStateFile
	AnsibleInventoryFile
	SOPSConfigFile
	KubeconfigFile
	S3CfgFile
	InfraJsonFile
)

const (
	AnsibleConfigFile CodePathID = iota
	AnsiblePlaybookDeployKubernetesFile
	AnsiblePlaybookPrepareNodesFile
	AnsiblePlaybookJoinClusterFile
	AnsiblePlaybookInfrustructureFiles
	ManageS3BucketsScriptFile
	TerraformTFEDir
	// TODO: Would be nice to get rid of this and only have one single main
	//		 Terraform module.
	TerraformExoscaleDir
	TerraformSafespringDir
	TerraformCityCloudDir
	TerraformAWSDir
)

var relativeConfigPaths = ConfigPath{
	ConfigFile:          {"config.yaml", "yaml"},
	SecretsFile:         {"secrets.yaml", "yaml"},
	TFBackendConfigFile: {"backend_config.hcl", "hclv2"},
	TFVarsFile:          {"tfvars.json", "json"},
	TFDataDir:           {".state/.terraform", ""},
	TFEDataDir:          {".state/.terraform-tfe", ""},
	TFEStateFile:        {".state/terraform-tfe.tfstate", ""},
	SOPSConfigFile:      {".sops.yaml", "yaml"},
	S3CfgFile:           {".state/s3cfg.ini", "ini"},
	InfraJsonFile:       {".state/infra.json", "json"},
}

var clusterSpecificRelativeConfigPaths = map[ClusterType]ConfigPath{
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

var relativeCodePaths = CodePath{
	AnsibleConfigFile: {
		"ansible/ansible.cfg", "ini",
	},
	AnsiblePlaybookDeployKubernetesFile: {
		"ansible/deploy-kubernetes.yml", "yaml",
	},
	AnsiblePlaybookPrepareNodesFile: {
		"ansible/prepare-nodes.yml", "yaml",
	},
	AnsiblePlaybookInfrustructureFiles: {
		"ansible/infrastructure.yml", "yaml",
	},
	AnsiblePlaybookJoinClusterFile: {
		"ansible/join-cluster.yml", "yaml",
	},
	ManageS3BucketsScriptFile: {
		"scripts/manage-s3-buckets.sh", "",
	},
	TerraformTFEDir: {
		"terraform/tfe", "",
	},
	TerraformExoscaleDir: {
		"terraform/exoscale", "",
	},
	TerraformSafespringDir: {
		"terraform/safespring", "",
	},
	TerraformCityCloudDir: {
		"terraform/citycloud", "",
	},
	TerraformAWSDir: {
		"terraform/aws", "",
	},
}

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

func NewCodePath(codeRootPath string, clusterType ClusterType) CodePath {
	codePath := make(CodePath, len(relativeCodePaths))
	for id, p := range relativeCodePaths {
		codePath[id] = Path{
			Path:   path.Join(codeRootPath, p.Path),
			Format: p.Format,
		}
	}
	return codePath
}
