// The command line interface of the application.
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/massimo-cannavo/linux-from-scratch/utils/download/download-pkg"
	"github.com/spf13/cobra"
)

const sourcesPath = "/mnt/lfs/sources"

var (
	filename     string
	downloadPath string

	rootCmd = &cobra.Command{
		Use:   "download",
		Short: "Downloads a specific version of a package using a YAML file",
		Run: func(cmd *cobra.Command, args []string) {
			downloadPkg()
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
		"package file used for downloading the package (required)")
	rootCmd.Flags().StringVarP(&downloadPath, "destination", "d", sourcesPath,
		"destination path to download the package")

	rootCmd.MarkFlagRequired("file")
}

// downloadPkg attempts to download and extract a package.
func downloadPkg() {
	yamlSchema := common.PackageSchema{}
	if err := common.ParseYaml(filename, &yamlSchema); err != nil {
		common.HandleError(err)
	}
	if err := common.ValidatePackageSchema(yamlSchema); err != nil {
		common.HandleError(fmt.Errorf("%s in %s", err, filename))
	}

	checksum, err := download.DownloadFile(*yamlSchema.Source, downloadPath)
	if err != nil {
		common.HandleError(err)
	}
	if checksum == "" {
		os.Exit(0)
	} else if checksum != *yamlSchema.Checksum {
		common.HandleError(fmt.Errorf("checksum verification failed for %s", *yamlSchema.Name))
	}

	paths := strings.Split(*yamlSchema.Source, "/")
	filepath := fmt.Sprintf("%s/%s", downloadPath, paths[len(paths)-1])
	if err := download.Extract(filepath, downloadPath); err != nil {
		common.HandleError(err)
	}
	for _, patch := range yamlSchema.Patches {
		if _, err := download.DownloadFile(patch, downloadPath); err != nil {
			common.HandleError(err)
		}
	}
}
