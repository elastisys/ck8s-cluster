package client

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io"

	"golang.org/x/crypto/ssh"
)

func generateSSHKeyPair(pubKeyWriter, privKeyWriter io.Writer) error {
	privKey, err := rsa.GenerateKey(rand.Reader, 4096)
	if err != nil {
		return fmt.Errorf("failed to generate private SSH key: %w", err)
	}

	if err := privKey.Validate(); err != nil {
		return fmt.Errorf("failed to validate private SSH key: %w", err)
	}

	privKeyPEM := &pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: x509.MarshalPKCS1PrivateKey(privKey),
	}

	pubKey, err := ssh.NewPublicKey(&privKey.PublicKey)
	if err != nil {
		return err
	}

	pubKeyAuthorizedKey := ssh.MarshalAuthorizedKey(pubKey)

	if err := pem.Encode(privKeyWriter, privKeyPEM); err != nil {
		return fmt.Errorf("error PEM encoding private SSH key: %w", err)
	}

	if _, err := pubKeyWriter.Write(pubKeyAuthorizedKey); err != nil {
		return fmt.Errorf("error writing public SSH key: %w", err)
	}

	return nil
}
