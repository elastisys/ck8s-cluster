package openstack

type TfvarsMachinePart struct {
	NameSlice *[]string
	SizeMap   map[string]string
}

type OpenstackTFVars struct {
	PrefixSC string `hcl:"prefix_sc"`
	PrefixWC string `hcl:"prefix_wc"`

	// TODO: Combine these
	MasterNamesSC       []string          `hcl:"master_names_sc" validate:"required,min=1"`
	MasterNameSizeMapSC map[string]string `hcl:"master_name_flavor_map_sc" validate:"required"`

	// TODO: Combine these
	WorkerNamesSC       []string          `hcl:"worker_names_sc"`
	WorkerNameSizeMapSC map[string]string `hcl:"worker_name_flavor_map_sc"`

	// TODO: Combine these
	MasterNamesWC       []string          `hcl:"master_names_wc" validate:"required,min=1"`
	MasterNameSizeMapWC map[string]string `hcl:"master_name_flavor_map_wc" validate:"required"`

	// TODO: Combine these
	WorkerNamesWC       []string          `hcl:"worker_names_wc" validate:"required"`
	WorkerNameSizeMapWC map[string]string `hcl:"worker_name_flavor_map_wc" validate:"required"`

	MasterAntiAffinityPolicySC string `hcl:"master_anti_affinity_policy_sc"`
	WorkerAntiAffinityPolicySC string `hcl:"worker_anti_affinity_policy_sc"`
	MasterAntiAffinityPolicyWC string `hcl:"master_anti_affinity_policy_wc"`
	WorkerAntiAffinityPolicyWC string `hcl:"worker_anti_affinity_policy_wc"`

	PublicIngressCIDRWhitelist []string `hcl:"public_ingress_cidr_whitelist" validate:"required"`

	APIServerWhitelist []string `hcl:"api_server_whitelist" validate:"required"`

	AWSDNSZoneID  string `hcl:"aws_dns_zone_id" validate:"required"`
	AWSDNSRoleARN string `hcl:"aws_dns_role_arn" validate:"required"`

	ExternalNetworkID   string `hcl:"external_network_id" validate:"required"`
	ExternalNetworkName string `hcl:"external_network_name" validate:"required"`
}
