// Common utilities that can be reused by other modules.
package common

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"os/user"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type Color struct {
	Reset  string
	Red    string
	Green  string
	Yellow string
	Blue   string
}

var Colors = &Color{
	Reset:  "\033[0m",
	Red:    "\033[1;31m",
	Green:  "\033[1;32m",
	Yellow: "\033[1;33m",
	Blue:   "\033[1;34m",
}

type PackageSchema struct {
	Name     *string
	Source   *string
	Checksum *string
	Patches  []string
}

type Partition struct {
	Number     *int
	Filesystem *string
	Flags      []string
	Start      *int64
	End        *int64
	Encrypted  *bool
}

type PartitionSchema struct {
	Device          *string
	PartitionScheme *string `yaml:"partitionScheme"`
	Unit            *string
	Partitions      map[string]Partition
}

const PartitionsFile = "../partitions.yaml"

// HandleError prints a formatted error message to Stderr
// and exits gracefully.
func HandleError(err error) {
	os.Stderr.WriteString(fmt.Sprintf("%s[ ERROR ]%s %s\n", Colors.Red, Colors.Reset, err))
	os.Exit(1)
}

// IsUserRoot determines if the current user is root.
func IsUserRoot() bool {
	currentUser, err := user.Current()
	if err != nil {
		HandleError(err)
	}

	return currentUser.Username == "root"
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

// ValidatePartitionSchema validates that the required attributes
// exist in yamlSchema.
func ValidatePartitionSchema(yamlSchema PartitionSchema) error {
	if yamlSchema.Device == nil {
		return errors.New("missing property: device")
	}
	if yamlSchema.PartitionScheme == nil {
		return errors.New("missing property: partitionScheme")
	}
	if yamlSchema.Unit == nil {
		return errors.New("missing property: unit")
	}
	if yamlSchema.Partitions == nil {
		return errors.New("missing property: partitions")
	}

	rootExists := false
	for key, partition := range yamlSchema.Partitions {
		if partition.Number == nil {
			return errors.New("missing property: number")
		}
		if partition.Filesystem == nil {
			return errors.New("missing property: filesystem")
		}
		if partition.Start == nil {
			return errors.New("missing property: start")
		}
		if partition.End == nil {
			return errors.New("missing property: end")
		}
		if partition.Encrypted == nil {
			return errors.New("missing property: encrypted")
		}
		if key == "root" {
			rootExists = true
		}
	}

	if !rootExists {
		return errors.New("missing root partition")
	}

	return nil
}

// ValidatePackageSchema validates that the required attributes
// exist in yamlSchema.
func ValidatePackageSchema(yamlSchema PackageSchema) error {
	if yamlSchema.Name == nil {
		return errors.New("missing property: name")
	}
	if yamlSchema.Source == nil {
		return errors.New("missing property: source")
	}
	if yamlSchema.Checksum == nil {
		return errors.New("missing property: checksum")
	}

	return nil
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
