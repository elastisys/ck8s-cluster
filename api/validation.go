package api

import (
	"errors"
	"fmt"

	"github.com/go-playground/locales/en"
	ut "github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
	en_translations "github.com/go-playground/validator/v10/translations/en"
	"github.com/hashicorp/go-multierror"
)

var (
	validate   *validator.Validate
	translator ut.Translator
)

func init() {
	en := en.New()
	validate = validator.New()
	var ok bool
	if translator, ok = ut.New(en, en).GetTranslator("en"); !ok {
		panic("failed to get translator")
	}
	if err := en_translations.RegisterDefaultTranslations(
		validate,
		translator,
	); err != nil {
		panic(err)
	}
}

func ValidateCluster(cluster Cluster) error {
	if err := validate.Struct(cluster); err != nil {
		var validationErrors validator.ValidationErrors
		if errors.As(err, &validationErrors) {
			var errorChain error
			for _, err := range validationErrors {
				errorChain = multierror.Append(
					errorChain,
					fmt.Errorf(err.Translate(translator)),
				)
			}
			return errorChain
		}
		return err
	}
	return nil
}
