// The command line interface of the application.
package cmd

import (
	"os"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/spf13/cobra"
)

var (
	filename string
	whatIf   bool

	rootCmd = &cobra.Command{
		Use:   "partition",
		Short: "Partitions a device using a YAML file",
		Run: func(cmd *cobra.Command, args []string) {

		},
	}
)

// Execute runs the root command and exits gracefully if an
// error occured during execution.
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

// init configures and initializes the flags that are
// supported by the application.
func init() {
	rootCmd.Flags().StringVarP(&filename, "file", "f", common.PartitionsFile,
		"YAML file that contains partitions to create")
	rootCmd.Flags().BoolVar(&whatIf, "what-if", false,
		"displays a preview of the operations to perform")
}
