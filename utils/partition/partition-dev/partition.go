// Functions used to create partitions from a YAML file.
package partition

import (
	"fmt"
	"os/exec"
)

// DisplayPartitions outputs the current partition table of
// the device located at devPath.
func DisplayPartitions(devPath string) error {
	cmd := exec.Command("parted", "--script", devPath, "print")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf(string(output[:]))
	}

	fmt.Print(string(output[:]))
	return err
}
