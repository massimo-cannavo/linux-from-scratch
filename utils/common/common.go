// Common utilities that can be reused by other modules.
package common

import (
	"fmt"
	"os"

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

// HandleError prints a formatted error message to Stderr
// and exits gracefully.
func HandleError(err error) {
	os.Stderr.WriteString(fmt.Sprintf("%s[ ERROR ]%s %s\n", color.red, color.reset, err))
	os.Exit(1)
}

// ParseYaml extracts the specified attributes from yamlSchema
// in the given YAML file filename.
func ParseYaml(filename string, yamlSchema interface{}) {
	data, err := os.ReadFile(filename)
	if err != nil {
		HandleError(err)
	}

	err = yaml.Unmarshal(data, yamlSchema)
	if err != nil {
		HandleError(err)
	}
}
