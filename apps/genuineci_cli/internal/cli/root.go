package cli

import (
	"fmt"
	"io"

	"github.com/spf13/cobra"
)

func NewRootCommand(version string, stdout, stderr io.Writer) *cobra.Command {
	root := &cobra.Command{
		Use:          "go-genuine",
		Short:        "GenuineCI command-line tools",
		Version:      version,
		SilenceUsage: true,
	}
	root.SetOut(stdout)
	root.SetErr(stderr)
	root.AddCommand(&cobra.Command{
		Use:   "version",
		Short: "Print the CLI version",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			_, err := fmt.Fprintf(command.OutOrStdout(), "%s version %s\n", root.Name(), version)
			return err
		},
	})
	return root
}
