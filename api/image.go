package api

import (
	"fmt"

	versionutil "k8s.io/apimachinery/pkg/util/version"
)

type Image struct {
	Name string `json:"name"`

	KubeletVersion *versionutil.Version `json:"-"`
}

func NewImage(name string, kubeletVersionStr string) *Image {
	// TODO: This is needed to support non-Kubernetes images. Should we
	// implement different Image types?
	var kubeletVersion *versionutil.Version
	if kubeletVersionStr != "" {
		kubeletVersion = versionutil.MustParseSemantic(kubeletVersionStr)
	}
	return &Image{
		Name: name,

		KubeletVersion: kubeletVersion,
	}
}

// IsSupported returns an error if the image is not supported by the provided
// Kubernetes API server version.
// For more information, see:
// https://kubernetes.io/docs/setup/release/version-skew-policy/
func (i *Image) IsSupported(kubeAPIServerVersionStr string) error {
	kubeAPIServerVersion, err := versionutil.ParseSemantic(
		kubeAPIServerVersionStr,
	)
	if err != nil {
		return fmt.Errorf("unable to parse kube-apiserver version: %w", err)
	}

	// kubelet must not be newer than kube-apiserver
	if kubeAPIServerVersion.Minor() < i.KubeletVersion.Minor() {
		return ErrInvalidImageKubeletNew
	}
	// ... and may be up to two minor versions older.
	if kubeAPIServerVersion.Minor()-i.KubeletVersion.Minor() > 2 {
		return ErrInvalidImageKubeletOld
	}

	return nil
}
