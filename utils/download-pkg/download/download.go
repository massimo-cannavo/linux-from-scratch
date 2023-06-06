// Functions used to download a package from parsing a YAML file.
package downloadpkg

import (
	"crypto/sha512"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
)

type YamlSchema struct {
	Name     *string
	Source   *string
	Checksum *string

	Patches []string
}

// DownloadFile attempts to extract a filename from a given url
// and downloads the contents of the file to downloadPath. A
// SHA512 checksum of the file is calculated and returned.
func DownloadFile(url string, downloadPath string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}

	defer resp.Body.Close()

	paths := strings.Split(url, "/")
	filepath := fmt.Sprintf("%s/%s", downloadPath, paths[len(paths)-1])
	if _, err = os.Stat(filepath); os.IsExist(err) {
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
	if _, err = io.Copy(hash, resp.Body); err != nil {
		return "", err
	}

	_, err = io.Copy(out, resp.Body)
	return string(hash.Sum(nil)), err
}

// ValidateSchema validates that the required attributes
// exist in yamlSchema.
func ValidateSchema(yamlSchema YamlSchema) error {
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
