// Functions used to mount partitions from parsing a YAML file.
package mount

import (
	"fmt"
	"io"
	"os"
	"os/exec"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
)

// MountDev will mount all partitions from yamlSchema to the
// specified devPath.
func MountDev(yamlSchema common.PartitionSchema, devPath string) error {
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
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf(string(output[:]))
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
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf(string(output[:]))
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
	output, err := cmd.CombinedOutput()
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			return fmt.Errorf(string(output[:]))
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

		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf(string(output[:]))
		}

		fmt.Print(string(output[:]))
	}

	return nil
}
