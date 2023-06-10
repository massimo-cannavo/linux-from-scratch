// Common utilities that can be reused by other modules.
package common

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type Color struct {
	reset  string
	red    string
	green  string
	yellow string
	blue   string
}

var color = &Color{
	reset:  "\033[0m",
	red:    "\033[1;31m",
	green:  "\033[1;32m",
	yellow: "\033[1;33m",
	blue:   "\033[1;34m",
}

const PartitionsFile = "../partitions-schema.yaml"

// HandleError prints a formatted error message to Stderr
// and exits gracefully.
func HandleError(err error) {
	os.Stderr.WriteString(fmt.Sprintf("%s[ ERROR ]%s %s\n", color.red, color.reset, err))
	os.Exit(1)
}

// ParseYaml extracts the specified attributes from yamlSchema
// in the given YAML file filename.
func ParseYaml(filename string, yamlSchema interface{}) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	return yaml.Unmarshal(data, yamlSchema)
}

// GetDevPath looks for a device with the specified serialNo
// and returns the path of the device if found.
func GetDevPath(serialNo string) (string, error) {
	devPath := ""
	err := filepath.Walk("/dev/disk/by-id/", func(path string, info fs.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.Contains(info.Name(), "part") {
			return err
		} else if strings.Contains(info.Name(), serialNo) {
			devPath, err = filepath.EvalSymlinks(path)
			return err
		}

		return err
	})

	return devPath, err
}
