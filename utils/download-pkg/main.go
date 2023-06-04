// Downloads a specific version of a package using a YAML file.
package main

import (
	"crypto/sha512"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/massimo-cannavo/linux-from-scratch/utils/common"
	"github.com/massimo-cannavo/linux-from-scratch/utils/download-pkg/cmd"
)

type YamlSchema struct {
	Name     *string
	Source   *string
	Checksum *string

	Patches []string
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

	checksum, err := downloadFile(*yamlSchema.Source, cmd.DownloadPath)
	if err != nil {
		common.HandleError(err)
	}
	if checksum != *yamlSchema.Checksum {
		common.HandleError(fmt.Errorf("checksum verification failed for %s", *yamlSchema.Checksum))
	}
}

// validateSchema validates that the required attributes
// exist in yamlSchema.
func validateSchema(yamlSchema YamlSchema) error {
	if yamlSchema.Name == nil {
		return errors.New("missing property: name")
	}
	if yamlSchema.Source == nil {
		return errors.New("missing property: source")
	}
	if yamlSchema.Checksum == nil {
		return errors.New("missing property: checksum")
	}

	return nil
}

// downloadFile attempts to extract a filename from a given url
// and downloads the contents of the file to downloadPath. A
// SHA512 checksum of the file is calculated and returned.
func downloadFile(url string, downloadPath string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}

	defer resp.Body.Close()

	paths := strings.Split(url, "/")
	filepath := fmt.Sprintf("%s/%s", downloadPath, paths[len(paths)-1])
	_, err = os.Stat(filepath)
	if os.IsExist(err) {
		fmt.Printf("%s exists, skipping download", filepath)
		return "", nil
	}

	fmt.Printf("downloading %s -> %s", filepath, downloadPath)
	out, err := os.Create(filepath)
	if err != nil {
		return "", err
	}

	defer out.Close()

	hash := sha512.New()
	_, err = io.Copy(hash, resp.Body)
	if err != nil {
		return "", err
	}

	_, err = io.Copy(out, resp.Body)
	return string(hash.Sum(nil)), err
}
