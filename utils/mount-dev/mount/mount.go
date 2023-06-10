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

// Mount will mount all partitions from yamlSchema to the
// specified devPath.
func Mount(yamlSchema YamlSchema, devPath string) error {
	root := yamlSchema.Partitions["root"]
	rootPath := fmt.Sprintf("%s%d", devPath, *root.Number)
	if *root.Encrypted {
		decryptPartition(rootPath)
		rootPath = "/dev/mapper/root"
	}

	lfsPath := "/mnt/lfs"
	if _, err := os.Stat(lfsPath); os.IsNotExist(err) {
		os.MkdirAll(lfsPath, 0750)
		fmt.Printf("created directory %s\n", lfsPath)
	}

	cmd := exec.Command("mount", rootPath, lfsPath)
	if err := cmd.Run(); err != nil {
		return err
	}

	fmt.Printf("%s mounted on %s\n", rootPath, lfsPath)
	for partitionName, partition := range yamlSchema.Partitions {
		if partitionName == "root" {
			continue
		}

		partitionPath := fmt.Sprintf("%s%d", devPath, *partition.Number)
		mountPath := fmt.Sprintf("%s/%s", lfsPath, partitionName)
		if _, err := os.Stat(mountPath); os.IsNotExist(err) {
			os.MkdirAll(mountPath, 0750)
			fmt.Printf("created directory %s\n", mountPath)
		}

		cmd := exec.Command("mount", partitionPath, mountPath)
		if err := cmd.Run(); err != nil {
			return err
		}

		fmt.Printf("%s mounted on %s\n", partitionPath, mountPath)
	}

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
