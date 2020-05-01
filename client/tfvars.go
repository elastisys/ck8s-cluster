package client

import (
	"fmt"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/gohcl"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/hashicorp/hcl/v2/hclwrite"
)

func tfvarsEncode(data interface{}) []byte {
	f := hclwrite.NewEmptyFile()
	gohcl.EncodeIntoBody(data, f.Body())
	return f.Bytes()
}

func tfvarsDecode(data []byte, tfVars interface{}) error {
	file, diags := hclsyntax.ParseConfig(
		data,
		"",
		hcl.Pos{Line: 1, Column: 1},
	)
	if diags.HasErrors() {
		return fmt.Errorf("failed to parse tfvars config: %s", diags)
	}

	diags = gohcl.DecodeBody(file.Body, nil, tfVars)
	if diags.HasErrors() {
		return fmt.Errorf("failed to decode tfvars config: %s", diags)
	}

	return nil
}
