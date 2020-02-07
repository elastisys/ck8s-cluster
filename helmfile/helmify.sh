#!/usr/bin/env bash

set -e

cmd=$1
chart=$2
env=$3

chart=${chart/.\//}
chartname=$(echo $chart | rev | cut -d'/' -f 1 | rev)
dir=./kustomize/$chartname

build() {
  if [ ! -d "$dir" ]; then
    echo "directory \"$dir\" does not exist. make a kustomize project there in order to generate a local helm chart at $chart/ from it!" 1>&2
    exit 1
  fi

  mkdir -p $chart/templates

  echo "running kustomize" 1>&2

  (cd $dir; kustomize build --enable_alpha_plugins overlays/$env) > $chart/templates/all.yaml

  echo "running helm lint" 1>&2

  helm lint $chart


}

clean() {
  rm $chart/templates/*.yaml
}

case "$cmd" in
  "build" ) build ;;
  "clean" ) clean ;;
  * ) echo "unsupported command: $cmd" 1>&2; exit 1 ;;
esac