// The command line interface of the application.
package cmd

import (
	"fmt"
	"os"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/massimo-cannavo/linux-from-scratch/utils/partition/partition-dev"
	"github.com/spf13/cobra"
)

var (
	filename string
	whatIf   bool

	rootCmd = &cobra.Command{
		Use:   "partition",
		Short: "Partitions a device using a YAML file",
		Run: func(cmd *cobra.Command, args []string) {
			partitionDev()
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

func partitionDev() {
	if !common.IsUserRoot() {
		common.HandleError(fmt.Errorf("run as root"))
	}

	yamlSchema := common.PartitionSchema{}
	if err := common.ParseYaml(filename, &yamlSchema); err != nil {
		common.HandleError(err)
	}
	if err := common.ValidatePartitionSchema(yamlSchema); err != nil {
		common.HandleError(fmt.Errorf("%s in %s", err, filename))
	}

	devPath, err := common.GetDevPath(*yamlSchema.Device)
	if err != nil {
		common.HandleError(err)
	} else if devPath == "" {
		common.HandleError(fmt.Errorf("device not found: %s", *yamlSchema.Device))
	}
	if err := partition.DisplayPartitions(devPath); err != nil {
		common.HandleError(err)
	}
	if whatIf {
		if err := partition.DisplayChanges(yamlSchema, devPath); err != nil {
			common.HandleError(err)
		}

		os.Exit(0)
	}
	if err := partition.PartitionDev(yamlSchema, devPath); err != nil {
		common.HandleError(err)
	}
}
