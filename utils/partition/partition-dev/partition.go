// Functions used to create partitions from a YAML file.
package partition

import (
	"fmt"
	"io"
	"math"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

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

var mkfsCmd = map[string][]string{
	"ext2":     {"mkfs.ext2"},
	"ext3":     {"mkfs.ext3"},
	"ext4":     {"mkfs.ext4"},
	"xfs":      {"mkfs.xfs"},
	"btrfs":    {"mkfs.btrfs"},
	"reiserfs": {"mkreiserfs"},
	"fat12":    {"mkfs.fat", "-F", "12"},
	"fat16":    {"mkfs.fat", "-F", "16"},
	"fat32":    {"mkfs.fat", "-F", "32"},
}

// DisplayPartitions outputs the current partition table of
// the device located at devPath.
func DisplayPartitions(devPath string) error {
	cmd := exec.Command("parted", "--script", devPath, "print")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to run: %s", cmd.Args[:])
	}

	return nil
}

// DisplayChanges outputs the partitions that will be created
// from the yamlSchema that was parsed for the device located
// at devPath.
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

			devSize, err := strconv.Atoi(strings.Replace(string(data), "\n", "", -1))
			if err != nil {
				return err
			}

			end = 512 * int64(devSize)
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

// PartitionDev partitions a device located at devPath
// using yamlSchema data parsed from the YAML file.
func PartitionDev(yamlSchema common.PartitionSchema, devPath string) error {
	if err := unmountDev(devPath); err != nil {
		return err
	}

	args := []string{
		"parted", "--script", "--align", "optimal", devPath,
		"mklabel", *yamlSchema.PartitionScheme, "unit", *yamlSchema.Unit,
	}
	for partitionName, partition := range yamlSchema.Partitions {
		args = append(args, "mkpart", partitionName, *partition.Filesystem,
			fmt.Sprint(*partition.Start),
		)
		end := *partition.End
		if end == -1 {
			args = append(args, "--")
		}

		args = append(args, fmt.Sprint(end))
		for _, flag := range partition.Flags {
			args = append(args, "set", fmt.Sprint(*partition.Number), flag, "on")
		}
	}

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to run: %s", cmd.Args[:])
	}

	return nil
}

// unmountDev unmounts all filesystems from the device
// located at devPath.
func unmountDev(devPath string) error {
	cmd := exec.Command("lsblk", devPath, "--noheadings", "--raw", "--output", "MOUNTPOINT")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf(string(output[:]))
	}

	mountPoints := strings.TrimSpace(string(output[:]))
	if mountPoints != "" {
		for _, mount := range strings.Split(mountPoints, "\n") {
			cmd := exec.Command("umount", mount)
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			if err := cmd.Run(); err != nil {
				return fmt.Errorf("failed to run: %s", cmd.Args[:])
			}
		}
	}

	return err
}

// FormatPartitions formats all the partitions parsed from
// yamlSchema of the device located at devPath.
func FormatPartitions(yamlSchema common.PartitionSchema, devPath string) error {
	for partitionName, partition := range yamlSchema.Partitions {
		partitionPath := fmt.Sprintf("%s%d", devPath, *partition.Number)
		if *partition.Encrypted {
			err := encryptPartition(partitionPath, partitionName, os.Getenv("LUKS_PASSPHRASE"))
			if err != nil {
				return err
			}

			partitionPath = fmt.Sprintf("/dev/mapper/%s", partitionName)
		}

		args := mkfsCmd[*partition.Filesystem]
		args = append(args, partitionPath)
		cmd := exec.Command(args[0], args[1:]...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to run: %s", cmd.Args[:])
		}

		if *partition.Encrypted {
			time.Sleep(5 * time.Second)
			cmd := exec.Command("cryptsetup", "close", partitionName)
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			if err := cmd.Run(); err != nil {
				return fmt.Errorf("failed to run: %s", cmd.Args[:])
			}
		}
	}

	return nil
}

// encryptPartition encrypts a partition located at
// partitionPath using passphrase.
func encryptPartition(partitionPath string, partitionName string, passphrase string) error {
	cmd := exec.Command("cryptsetup", "--verbose", "luksFormat", partitionPath)
	stdin, err := cmd.StdinPipe()
	if err != nil {
		return err
	}

	go func() {
		defer stdin.Close()
		io.WriteString(stdin, passphrase)
	}()

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to run: %s", cmd.Args[:])
	}

	cmd = exec.Command("cryptsetup", "open", partitionPath, partitionName)
	stdin, err = cmd.StdinPipe()
	if err != nil {
		return err
	}

	go func() {
		defer stdin.Close()
		io.WriteString(stdin, os.Getenv("LUKS_PASSPHRASE"))
	}()

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to run: %s", cmd.Args[:])
	}

	return err
}
