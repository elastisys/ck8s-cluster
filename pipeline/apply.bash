#!/bin/bash

set -e

ckctl apply --cluster sc
ckctl apply --cluster wc
