package client

import (
	"fmt"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/gohcl"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/hashicorp/hcl/v2/hclwrite"
)

func hclEncode(data interface{}) []byte {
	f := hclwrite.NewEmptyFile()
	gohcl.EncodeIntoBody(data, f.Body())
	return f.Bytes()
}

func hclDecode(data []byte, target interface{}) error {
	file, diags := hclsyntax.ParseConfig(
		data,
		"",
		hcl.Pos{Line: 1, Column: 1},
	)
	if diags.HasErrors() {
		return fmt.Errorf("failed to parse hcl config: %s", diags)
	}

	diags = gohcl.DecodeBody(file.Body, nil, target)
	if diags.HasErrors() {
		return fmt.Errorf("failed to decode hcl config: %s", diags)
	}

	return nil
}
