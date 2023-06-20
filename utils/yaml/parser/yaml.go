// Functions used to parse a YAML file.
package yaml

import (
	"fmt"
	"reflect"
	"strings"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

// ExtractYaml extracts the specified attribute from
// yamlSchema using query.
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

	tokens := strings.Split(query, ".")
	if len(tokens) > 1 {
		for _, token := range tokens[1:] {
			field := value.FieldByName(cases.Title(language.AmericanEnglish).String(token))
			if !field.IsValid() {
				return fmt.Errorf("invalid attribute %s", token)
			}
			if field.Kind() == reflect.Pointer {
				fmt.Printf("%s\n", field.Elem())
			} else if field.Kind() == reflect.Slice {
				for i := 0; i < field.Len(); i++ {
					fmt.Printf("%s\n", field.Index(i))
				}
			}
		}
	}

	return nil
}
