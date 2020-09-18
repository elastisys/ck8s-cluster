package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "completion SHELL",
		Short: "Generates completion scripts",
		Long: `Output shell completion code for the specified shell (bash or zsh). The shell code must be evaluated to provide
interactive completion of ck8s commands.  This can be done by sourcing it from the .bash_profile.

Examples:
  # Installing bash completion on Linux
  ## If bash-completion is not installed on Linux, please install the 'bash-completion' package
  ## via your distribution's package manager.
  ## Load the ck8s completion code for bash into the current shell
  source <(ck8s completion bash)
  ## Write bash completion code to a file and source if from .bash_profile
  ck8s completion bash > ~/.ck8s/completion.bash.inc
  printf "
  # ck8s shell completion
  source '$HOME/.ck8s/completion.bash.inc'
  " >> $HOME/.bash_profile
  source $HOME/.bash_profile

  # Load the ck8s completion code for zshinto the current shell
  source <(ck8s completion zsh)
  # Set the ck8s completion code for zsh to autoload on startup
  ck8s completion zsh > "${fpath[1]}/_ck8s"`,
		Args: ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			switch args[0] {
			case "bash":
				rootCmd.GenBashCompletion(os.Stdout)
			case "zsh":
				rootCmd.GenZshCompletion(os.Stdout)
			default:
				fmt.Fprintf(os.Stderr, "ERROR: Shell %s not supported\n", args[0])
			}
		},
	})
}
