#!/bin/bash

set -eu

if [ -f ~/.terraformrc ]; then
    echo "~/.terraformrc already exists. Skipping."
else
    echo 'credentials "app.terraform.io" {
      token = "'"${TF_TOKEN}"'"
    }' > ~/.terraformrc
fi
