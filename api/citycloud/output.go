package citycloud

import (
	"github.com/elastisys/ck8s/api/openstack"
)

type tfOutputStringValue struct {
	Value string `json:"value"`
}

type terraformOutput struct {
	openstack.TerraformOutput

	SCLBSubnetID tfOutputStringValue `json:"sc_lb_subnet_id"`
	WCLBSubnetID tfOutputStringValue `json:"wc_lb_subnet_id"`

	SCSecurityGroupID tfOutputStringValue `json:"sc_secgroup_id"`
	WCSecurityGroupID tfOutputStringValue `json:"wc_secgroup_id"`
}
