// Downloads a specific version of a package using a YAML file.
package main

import (
	"errors"
	"fmt"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/massimo-cannavo/linux-from-scratch/utils/download-pkg/cmd"
)

type YamlSchema struct {
	Source   *string
	Checksum *string
}

func main() {
	cmd.Execute()
	yamlSchema := YamlSchema{}
	err := common.ParseYaml(cmd.Filename, &yamlSchema)
	if err != nil {
		common.HandleError(err)
	}

	err = validateSchema(yamlSchema)
	if err != nil {
		common.HandleError(fmt.Errorf("%s in %s", err, cmd.Filename))
	}
}

// validateSchema validates that the required attributes
// exist in yamlSchema.
func validateSchema(yamlSchema YamlSchema) error {
	if yamlSchema.Source == nil {
		return errors.New("missing property: source")
	}
	if yamlSchema.Checksum == nil {
		return errors.New("missing property: checksum")
	}

	return nil
}
