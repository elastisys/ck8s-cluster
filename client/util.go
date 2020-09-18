package client

import (
	"errors"
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/elastisys/ck8s/api"
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

func mkdirAllIfNotExists(p api.Path) (bool, error) {
	if err := p.Exists(); err != nil {
		if !errors.Is(err, api.PathNotFoundErr) {
			return false, err
		}
	} else {
		return true, nil
	}

	rootPath, _, _ := splitPath(p.Path)
	if err := os.MkdirAll(rootPath, 0755); err != nil {
		return false, fmt.Errorf("error creating dir %s: %w", rootPath, err)
	}

	return false, nil
}
