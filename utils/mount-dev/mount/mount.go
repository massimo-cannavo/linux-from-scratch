// Functions used to mount partitions from parsing a YAML file.
package mountdev

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
)

type Partition struct {
	Number     *int
	Filesystem *string
	Flags      []string
	Start      *int64
	End        *int64
	Encrypted  *bool
}

type YamlSchema struct {
	Device     *string
	Partitions map[string]Partition
}

// ValidateSchema validates that the required attributes
// exist in yamlSchema.
func ValidateSchema(yamlSchema YamlSchema) error {
	if yamlSchema.Device == nil {
		return errors.New("missing property: device")
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

func Mount(yamlSchema YamlSchema, devPath string) error {
	root := yamlSchema.Partitions["root"]
	if *root.Encrypted {
		decryptPartition(fmt.Sprintf("%s%d", devPath, *root.Number))
	}
	// for _, partition := range yamlSchema.Partitions {

	// }

	return nil
}

// decryptPartition uses cryptsetup to open and decrypt a
// LUKS encrypted partition located at partitionPath.
func decryptPartition(partitionPath string) error {
	exitCode := 0
	cmd := exec.Command("cryptsetup", "status", "root")
	if err := cmd.Run(); err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		}
	}
	if exitCode == 4 {
		cmd := exec.Command("cryptsetup", "-v", "open", partitionPath, "root")
		stdin, err := cmd.StdinPipe()
		if err != nil {
			return err
		}

		go func() {
			defer stdin.Close()
			io.WriteString(stdin, os.Getenv("LUKS_PASSPHRASE"))
		}()

		stdout, err := cmd.Output()
		if err != nil {
			return err
		}

		fmt.Print(string(stdout[:]))
	}

	return nil
}
