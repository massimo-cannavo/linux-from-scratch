// The command line interface of the application.
package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

const sourcesPath = "/mnt/lfs/sources"

var (
	Filename     string
	DownloadPath string

	rootCmd = &cobra.Command{
		Use:   "download-pkg",
		Short: "Downloads a specific version of a package using a YAML file",
		Run:   func(cmd *cobra.Command, args []string) {},
	}
)

// Execute runs the root command and exits gracefully if an
// error occured during execution.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

// init configures and initializes the flags that are
// supported by the application.
func init() {
	rootCmd.Flags().StringVarP(&Filename, "file", "f", "",
		"package file used for downloading the package. (required)")
	rootCmd.Flags().StringVarP(&DownloadPath, "destination", "d", sourcesPath,
		"destination path to download the package.")

	rootCmd.MarkFlagRequired("file")
}
