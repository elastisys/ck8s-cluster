package main

import (
	"github.com/spf13/cobra"
)

// ExactArgs TODO
func ExactArgs(n int) cobra.PositionalArgs {
	cobraExactArgsFunc := cobra.ExactArgs(n)

	return func(cmd *cobra.Command, args []string) error {
		if err := cobraExactArgsFunc(cmd, args); err != nil {
			cmd.Help()
			return err
		}

		return nil
	}
}

// NoArgs TODO
func NoArgs(cmd *cobra.Command, args []string) error {
	if err := cobra.NoArgs(cmd, args); err != nil {
		cmd.Help()
		return err
	}

	return nil
}
