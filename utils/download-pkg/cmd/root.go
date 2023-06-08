// The command line interface of the application.
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/spf13/cobra"

	downloadpkg "github.com/massimo-cannavo/linux-from-scratch/utils/download-pkg/download"
)

const sourcesPath = "/mnt/lfs/sources"

var (
	filename     string
	downloadPath string

	rootCmd = &cobra.Command{
		Use:   "download-pkg",
		Short: "Downloads a specific version of a package using a YAML file",
		Run: func(cmd *cobra.Command, args []string) {
			download()
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
		"package file used for downloading the package. (required)")
	rootCmd.Flags().StringVarP(&downloadPath, "destination", "d", sourcesPath,
		"destination path to download the package.")

	rootCmd.MarkFlagRequired("file")
}

// download will call all the functions defined in downloadpkg.
func download() {
	yamlSchema := downloadpkg.YamlSchema{}

	if err := common.ParseYaml(filename, &yamlSchema); err != nil {
		common.HandleError(err)
	}
	if err := downloadpkg.ValidateSchema(yamlSchema); err != nil {
		common.HandleError(fmt.Errorf("%s in %s", err, filename))
	}

	checksum, err := downloadpkg.DownloadFile(*yamlSchema.Source, downloadPath)
	if err != nil {
		common.HandleError(err)
	}
	if checksum == "" {
		os.Exit(0)
	} else if checksum != *yamlSchema.Checksum {
		common.HandleError(fmt.Errorf("checksum verification failed for %s", *yamlSchema.Name))
	}

	paths := strings.Split(*yamlSchema.Source, "/")
	filepath := paths[len(paths)-1]
	if err := downloadpkg.Extract(filepath, downloadPath); err != nil {
		common.HandleError(err)
	}
	for _, patch := range yamlSchema.Patches {
		if _, err := downloadpkg.DownloadFile(patch, downloadPath); err != nil {
			common.HandleError(err)
		}
	}
}
