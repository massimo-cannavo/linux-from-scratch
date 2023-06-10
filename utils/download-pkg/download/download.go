// Functions used to download a package from parsing a YAML file.
package downloadpkg

import (
	"crypto/sha512"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

type YamlSchema struct {
	Name     *string
	Source   *string
	Checksum *string

	Patches []string
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

// DownloadFile attempts to extract a filename from a given url
// and downloads the contents of the file to downloadPath. A
// SHA512 checksum of the file is calculated and returned.
func DownloadFile(url string, downloadPath string) (string, error) {
	paths := strings.Split(url, "/")
	filepath := fmt.Sprintf("%s/%s", downloadPath, paths[len(paths)-1])
	if _, err := os.Stat(filepath); err == nil {
		fmt.Printf("%s exists, skipping download\n", filepath)
		return "", nil
	}

	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}

	defer resp.Body.Close()

	fmt.Printf("downloading %s -> %s\n", filepath, downloadPath)
	out, err := os.Create(filepath)
	if err != nil {
		return "", err
	}

	defer out.Close()

	data := io.TeeReader(resp.Body, out)
	hash := sha512.New()
	_, err = io.Copy(hash, data)

	return fmt.Sprintf("%x", hash.Sum(nil)), err
}

// Extract attempts to extract a tar archive given by
// filepath to destPath.
func Extract(filepath string, destPath string) error {
	fmt.Printf("extracting %s\n", filepath)
	cmd := exec.Command("tar", "-xvf", filepath, "-C", destPath)
	stdout, err := cmd.Output()
	if err != nil {
		return err
	}

	fmt.Print(string(stdout[:]))
	return nil
}
