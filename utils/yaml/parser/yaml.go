// Functions used to parse a YAML file.
package yaml

import (
	"fmt"
	"reflect"
	"strings"
)

// TODO:
func ExtractYaml(yamlSchema interface{}, query string) error {
	value := reflect.ValueOf(yamlSchema)
	if query == "package" {
		source := value.FieldByName("Source")
		if !source.IsValid() {
			return fmt.Errorf("missing attribute Source")
		}

		pkgPath := strings.Split(source.Elem().String(), "/")
		fmt.Printf("%s\n", strings.Replace(
			strings.Replace(pkgPath[len(pkgPath)-1], ".tar.xz", "", -1), ".tar.gz", "", -1),
		)
	}

	return nil
}
