// The command line interface of the application.
package cmd

import (
	"fmt"
	"os"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	yaml "github.com/massimo-cannavo/linux-from-scratch/utils/yaml/parser"
	"github.com/spf13/cobra"
)

var (
	filename string
	query    string

	rootCmd = &cobra.Command{
		Use:   "partition",
		Short: "Partitions a device using a YAML file",
		Run: func(cmd *cobra.Command, args []string) {
			parseYaml()
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
	rootCmd.Flags().StringVarP(&filename, "file", "f", "",
		"YAML file to parse and extract attributes (required)")
	rootCmd.Flags().StringVarP(&query, "query", "q", "",
		"query used to get specifc attributes")

	rootCmd.MarkFlagRequired("file")
}

// TODO:
func parseYaml() {
	yamlSchema := common.PackageSchema{}
	if err := common.ParseYaml(filename, &yamlSchema); err != nil {
		common.HandleError(err)
	}
	if err := common.ValidatePackageSchema(yamlSchema); err != nil {
		common.HandleError(fmt.Errorf("%s in %s", err, filename))
	}
	if err := yaml.ExtractYaml(yamlSchema, query); err != nil {
		common.HandleError(err)
	}
}
