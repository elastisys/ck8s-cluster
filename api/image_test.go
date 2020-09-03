package api

import (
	"testing"
)

func TestImageIsSupported(t *testing.T) {
	assert := func(err error, supported bool) {
		if supported && err != nil {
			t.Error(err)
		} else if !supported && err == nil {
			t.Errorf("expected error")
		}
	}

	image := NewImage("test", "v1.17.1")

	assert(image.IsSupported("v1.16.0"), false)
	assert(image.IsSupported("v1.16.9"), false)
	assert(image.IsSupported("v1.17.0"), true)
	assert(image.IsSupported("v1.17.1"), true)
	assert(image.IsSupported("v1.17.2"), true)
	assert(image.IsSupported("v1.18.0"), true)
	assert(image.IsSupported("v1.19.0"), true)
	assert(image.IsSupported("v1.19.1"), true)
	assert(image.IsSupported("v1.20.0"), false)
	assert(image.IsSupported("v1.20.1"), false)

	assert(image.IsSupported("not a version"), false)
}
