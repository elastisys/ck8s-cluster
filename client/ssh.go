package client

import (
	"fmt"
	"io"
	"os"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/terminal"

	"github.com/elastisys/ck8s/api"
)

const dialTimeout = 3 * time.Second

type SSHClientConfig struct {
	Host           string
	Port           int
	User           string
	PrivateKeyPath api.Path
}

func (c *SSHClientConfig) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("host", c.Host)
	enc.AddInt("port", c.Port)
	enc.AddString("user", c.User)
	enc.AddString("private_key_path", c.PrivateKeyPath.Path)
	return nil
}

type SSHClient struct {
	client *ssh.Client

	config *SSHClientConfig

	logger *zap.Logger
}

func NewSSHClient(
	logger *zap.Logger,
	config *SSHClientConfig,
) *SSHClient {
	return &SSHClient{
		config: config,

		logger: logger.With(zap.Object("config", config)),
	}
}

// Connect opens a connection to the remote host.
func (s *SSHClient) Connect() error {
	s.logger.Debug("ssh_client_connect")

	signer, err := s.sopsParsePrivateKey()
	if err != nil {
		return err
	}

	config := &ssh.ClientConfig{
		User: s.config.User,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
		Timeout: dialTimeout,
	}

	// TODO: Make this opt-in and handle host key checking.
	config.HostKeyCallback = ssh.InsecureIgnoreHostKey()

	address := fmt.Sprintf("%s:%d", s.config.Host, s.config.Port)
	s.client, err = ssh.Dial("tcp", address, config)
	if err != nil {
		return err
	}

	return nil
}

func (s *SSHClient) SingleSession(fn func(*ssh.Session) error) error {
	s.logger.Debug("ssh_client_single_session")
	if err := s.Connect(); err != nil {
		return fmt.Errorf("error connecting to remote host: %w", err)
	}
	defer func() {
		s.logger.Debug("ssh_client_single_session_client_close")
		if err := s.client.Close(); err != nil {
			s.logger.Error(
				"ssh_client_single_session_client_close_error",
				zap.Error(err),
			)
		}
	}()

	session, err := s.client.NewSession()
	if err != nil {
		return fmt.Errorf("error creating session to remote host: %w", err)
	}
	defer func() {
		s.logger.Debug("ssh_client_single_session_session_close")
		if err := session.Close(); err != nil && err != io.EOF {
			s.logger.Error(
				"ssh_client_single_session_session_close_error",
				zap.Error(err),
			)
		}
	}()

	return fn(session)
}

// Shell opens a login shell on the remote host.
func (s *SSHClient) Shell() error {
	s.logger.Debug("ssh_client_shell")

	if err := s.Connect(); err != nil {
		return fmt.Errorf("error connecting: %w", err)
	}
	defer s.Close()

	session, err := s.client.NewSession()
	if err != nil {
		return fmt.Errorf("error creating session: %w", err)
	}
	defer func() {
		s.logger.Debug("ssh_client_shell_session_close")
		if err := session.Close(); err != nil && err != io.EOF {
			s.logger.Error(
				"ssh_client_shell_session_close_error",
				zap.Error(err),
			)
		}
	}()

	session.Stdin = os.Stdin
	session.Stdout = os.Stdout
	session.Stderr = os.Stderr

	modes := ssh.TerminalModes{
		ssh.ECHO:          1,
		ssh.TTY_OP_ISPEED: 14400,
		ssh.TTY_OP_OSPEED: 14400,
	}

	// TODO: $TERM?
	// TODO: update size
	if err := session.RequestPty("xterm", 40, 200, modes); err != nil {
		return fmt.Errorf("error requesting pty: %w", err)
	}

	stdinFd := int(os.Stdin.Fd())
	oldState, err := terminal.MakeRaw(stdinFd)
	if err != nil {
		return fmt.Errorf("error making terminal raw: %w", err)
	}
	defer terminal.Restore(stdinFd, oldState)

	if err := session.Shell(); err != nil {
		return fmt.Errorf("error creating shell: %w", err)
	}

	return session.Wait()
}

func (s *SSHClient) Close() {
	s.logger.Debug("ssh_client_close")
	if err := s.client.Close(); err != nil {
		s.logger.Error("ssh_client_shell_client_close_error", zap.Error(err))
	}
}

func (s *SSHClient) sopsParsePrivateKey() (ssh.Signer, error) {
	s.logger.Debug("ssh_client_private_key_decrypt")
	privateKeyData, err := sopsDecrypt(s.config.PrivateKeyPath)
	if err != nil {
		return nil, fmt.Errorf(
			"failed to decrypt private key %s: %w",
			s.config.PrivateKeyPath,
			err,
		)
	}

	s.logger.Debug("ssh_client_private_key_parse")
	signer, err := ssh.ParsePrivateKey(privateKeyData)
	if err != nil {
		return nil, fmt.Errorf("failed to parse private key data: %w", err)
	}

	return signer, nil
}
