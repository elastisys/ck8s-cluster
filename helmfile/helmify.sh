#!/usr/bin/env bash

cmd=$1
chart=$2
env=$3
dir=${chart}-kustomize

chart=${chart/.\//}
chart_dir=charts/$chart

build() {
  if [ ! -d "$dir" ]; then
    echo "directory \"$dir\" does not exist. make a kustomize project there in order to generate a local helm chart at $chart_dir/ from it!" 1>&2
    exit 1
  fi

  mkdir -p $chart_dir/templates

  echo "generating $chart_dir/Chart.yaml" 1>&2

  cat <<EOF > $chart_dir/Chart.yaml
apiVersion: v1
appVersion: "1.0"
description: A Helm chart for Kubernetes
name: $chart
version: 0.1.0
EOF

  echo "generating $chart_dir/templates/NOTES.txt" 1>&2

  cat <<EOF > $chart_dir/templates/NOTES.txt
$chart has been installed as release {{ .Release.Name }}.

Run \`helm status {{ .Release.Name }}\` for more information.
Run \`helm delete --purge {{.Release.Name}}\` to uninstall.
EOF

  echo "running kustomize" 1>&2

  (cd $dir; kustomize build --enable_alpha_plugins overlays/$env) > $chart_dir/templates/all.yaml

  echo "running helm lint" 1>&2

  helm lint $chart_dir

}

clean() {
  rm $chart_dir/Chart.yaml
  rm $chart_dir/templates/*.yaml
  rm $chart_dir/templates/NOTES.txt
}

case "$cmd" in
  "build" ) build ;;
  "clean" ) clean ;;
  * ) echo "unsupported command: $cmd" 1>&2; exit 1 ;;
esac