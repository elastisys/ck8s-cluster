package main

import (
	"fmt"

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

// Attribution: https://github.com/uber-go/zap/blob/3e4a6c3d072da3b0fa6f84c116325b887514b344/internal/color/color.go
type Color uint8

const (
	Black Color = iota + 30
	Red
	Green
	Yellow
	Blue
	Magenta
	Cyan
	White
)

func (c Color) Fmt(s string) string {
	return fmt.Sprintf("\x1b[%dm%s\x1b[0m", uint8(c), s)
}
