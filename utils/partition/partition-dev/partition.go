// Functions used to create partitions from a YAML file.
package partition

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"math"
	"os"
	"os/exec"
	"strings"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
)

var unitSystem = map[string]int{
	"B":   1024,
	"Kib": 1024,
	"MiB": 1024,
	"GiB": 1024,
	"TiB": 1024,
	"KB":  1000,
	"MB":  1000,
	"GB":  1000,
	"TB":  1000,
}

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

// TODO: finish.
func DisplayChanges(yamlSchema common.PartitionSchema, devPath string) error {
	fmt.Printf("%sDevice will be wiped and formatted:%s\n",
		common.Colors.Yellow, common.Colors.Reset)
	fmt.Printf("Partition Table: %s%s%s\n",
		common.Colors.Blue, *yamlSchema.PartitionScheme, common.Colors.Reset)

	dev := strings.Replace(devPath, "/dev/", "", 1)
	for partitionName, partition := range yamlSchema.Partitions {
		start := toBytes(int(*partition.Start), *yamlSchema.Unit)
		end := *partition.End
		if end == -1 {
			data, err := os.ReadFile(fmt.Sprintf("/sys/block/%s/size", dev))
			if err != nil {
				return err
			}

			reader := bytes.NewReader(data)
			devSize, err := binary.ReadVarint(reader)
			if err != nil {
				return err
			}

			end = 512 * devSize
		}

		fmt.Printf("Partition %d\n", *partition.Number)
		fmt.Printf("  Name: %s%s%s\n",
			common.Colors.Blue, partitionName, common.Colors.Reset)
		fmt.Printf("  Filesystem: %s%s%s\n",
			common.Colors.Blue, *partition.Filesystem, common.Colors.Reset)
		fmt.Printf("  Start %s%d%s\n",
			common.Colors.Blue, start, common.Colors.Reset)
	}
}

// toBytes converts size to bytes from the given unit.
func toBytes(size int, unit string) int64 {
	bytes, ok := unitSystem[unit]
	if !ok {
		common.HandleError(fmt.Errorf("invalid unit %s", unit))
	}

	units := map[string]int{
		"B": 1,
		"K": bytes,
		"M": int(math.Pow(float64(bytes), 2)),
		"G": int(math.Pow(float64(bytes), 3)),
		"T": int(math.Pow(float64(bytes), 4)),
	}

	return int64(size * units[string(unit[0])])
}
