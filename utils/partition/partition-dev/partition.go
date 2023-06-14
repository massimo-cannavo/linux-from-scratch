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
		start := toBytes(*partition.Start, *yamlSchema.Unit)
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
		} else {
			end = toBytes(end, *yamlSchema.Unit)
		}

		size, unit := toUnit(end-start, *yamlSchema.Unit)

		fmt.Printf("Partition %d\n", *partition.Number)
		fmt.Printf("  Name: %s%s%s\n",
			common.Colors.Blue, partitionName, common.Colors.Reset)
		fmt.Printf("  Filesystem: %s%s%s\n",
			common.Colors.Blue, *partition.Filesystem, common.Colors.Reset)
		fmt.Printf("  Start %s%d%s\n",
			common.Colors.Blue, *partition.Start, common.Colors.Reset)
		fmt.Printf("  End %s%d%s\n",
			common.Colors.Blue, *partition.End, common.Colors.Reset)
		fmt.Printf("  Size %s%d %s%s\n",
			common.Colors.Blue, size, unit, common.Colors.Reset)
	}

	return nil
}

// toBytes converts size to bytes from the given unit.
func toBytes(size int64, unit string) int64 {
	bytes, ok := unitSystem[unit]
	if !ok {
		common.HandleError(fmt.Errorf("invalid unit %s", unit))
	}

	units := map[string]int64{
		"B": 1,
		"K": int64(bytes),
		"M": int64(math.Pow(float64(bytes), 2)),
		"G": int64(math.Pow(float64(bytes), 3)),
		"T": int64(math.Pow(float64(bytes), 4)),
	}

	return int64(size * units[string(unit[0])])
}

// toUnit converts bytes into the specified unit.
func toUnit(size int64, unit string) (int64, string) {
	bytes, ok := unitSystem[unit]
	if !ok {
		common.HandleError(fmt.Errorf("invalid unit %s", unit))
	}

	i := int(math.Floor(math.Log10(float64(size)) / math.Log10(float64(bytes))))
	x := int64(math.Round(float64(size) / math.Pow(float64(bytes), float64(i))))
	units := [5]string{"B", "K", "M", "G", "T"}
	suffix := ""
	if bytes == 1024 {
		suffix = "iB"
	} else if bytes == 1000 {
		suffix = "B"
	}

	return x, fmt.Sprintf("%s%s", units[i], suffix)
}
