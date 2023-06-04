// Common utilities that can be reused by other modules.
package common

import (
	"fmt"
	"io"
	"net/http"
	"os"
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

	err = yaml.Unmarshal(data, yamlSchema)
	if err != nil {
		return err
	}

	return nil
}

// DownloadFile attempts to extract a filename from a given url
// and downloads the contents of the file to downloadPath.
func DownloadFile(url string, downloadPath string) error {
	resp, err := http.Get(url)
	if err != nil {
		return err
	}

	defer resp.Body.Close()

	paths := strings.Split(url, "/")
	filepath := fmt.Sprintf("%s/%s", downloadPath, paths[len(paths)-1])
	_, err = os.Stat(filepath)
	if os.IsExist(err) {
		fmt.Printf("%s exists, skipping download", filepath)
		return nil
	}

	out, err := os.Create(filepath)
	if err != nil {
		return err
	}

	defer out.Close()
	_, err = io.Copy(out, resp.Body)

	return err
}
