// Functions used to mount partitions from parsing a YAML file.
package mountdev

import "errors"

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

	for _, partition := range yamlSchema.Partitions {
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
	}

	return nil
}
