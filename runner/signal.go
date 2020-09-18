package runner

import (
	"os"
	"os/signal"

	"go.uber.org/zap"
)

type SignalHandler func(os.Signal) error
type SignalsHandler chan os.Signal

func NewSignalsHandler(
	logger *zap.Logger,
	handler SignalHandler,
	signals ...os.Signal,
) SignalsHandler {
	signalCh := make(chan os.Signal, 1)
	signal.Notify(signalCh, signals...)

	go func() {
		for {
			s, ok := <-signalCh
			if !ok {
				return
			}

			signalLogger := logger.With(zap.String("signal", s.String()))

			signalLogger.Debug("signal_caught")

			if err := handler(s); err != nil {
				signalLogger.Error("signal_handler_error", zap.Error(err))
			}
		}
	}()

	return signalCh
}

func (sh *SignalsHandler) Close() {
	signal.Stop(*sh)
	close(*sh)
}
