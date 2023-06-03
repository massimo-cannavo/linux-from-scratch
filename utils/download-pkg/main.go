// Downloads a specific version of a package using a YAML file.
package main

import (
	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/massimo-cannavo/linux-from-scratch/utils/download-pkg/cmd"
)

type YamlSchema struct {
	Source   string
	Checksum string
}

func main() {
	cmd.Execute()
	yamlSchema := YamlSchema{}
	common.ParseYaml(cmd.Filename, &yamlSchema)
}
