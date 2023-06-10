// The command line interface of the application.
package cmd

import (
	"fmt"
	"os"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/spf13/cobra"

	mountdev "github.com/massimo-cannavo/linux-from-scratch/utils/mount-dev/mount"
)

var (
	filename string

	rootCmd = &cobra.Command{
		Use:   "mount",
		Short: "Mounts partitions from a YAML file.",
		Run: func(cmd *cobra.Command, args []string) {
			mount()
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
		"YAML file that contains partitions to mount")
}

// TODO: add comments.
func mount() {
	yamlSchema := mountdev.YamlSchema{}
	if err := common.ParseYaml(filename, &yamlSchema); err != nil {
		common.HandleError(err)
	}
	if err := mountdev.ValidateSchema(yamlSchema); err != nil {
		common.HandleError(fmt.Errorf("%s in %s", err, filename))
	}

	devPath, err := common.GetDevPath(*yamlSchema.Device)
	if err != nil {
		common.HandleError(err)
	} else if devPath == "" {
		common.HandleError(fmt.Errorf("device not found: %s", *yamlSchema.Device))
	}
	if err := mountdev.Mount(yamlSchema, devPath); err != nil {
		common.HandleError(err)
	}
}
