package client

import (
	"path"
	"strings"
)

func splitPath(fullPath string) (dir, name, ext string) {
	dir, filename := path.Split(fullPath)

	parts := strings.Split(filename, ".")
	name = parts[0]

	if len(parts) == 1 {
		ext = ""
	} else {
		ext = parts[1]
	}

	return
}
