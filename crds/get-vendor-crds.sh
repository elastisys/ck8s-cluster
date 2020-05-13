###pulls vendors crds from githup. If the chart version is changed (updated) in helmfile, the crd version needs to be changed here to reflect the change.
echo downloading vendor crds
echo elasticsearch
curl 'https://raw.githubusercontent.com/elastic/cloud-on-k8s/1.0/config/crds/all-crds.yaml' -o elasticsearch-operator.yaml
echo cert-manager
curl 'https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml' -o cert-manager.yaml
echo prometheus-operator
curl 'https://raw.githubusercontent.com/coreos/prometheus-operator/v0.38.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml' -o alertmanager.yaml
curl 'https://raw.githubusercontent.com/coreos/prometheus-operator/v0.38.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml' -o prometheus.yaml
curl 'https://raw.githubusercontent.com/coreos/prometheus-operator/v0.38.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml' -o prometheusrule.yaml
curl 'https://raw.githubusercontent.com/coreos/prometheus-operator/v0.38.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml' -o servicemonitor.yaml
curl 'https://raw.githubusercontent.com/coreos/prometheus-operator/v0.38.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml' -o podmonitor.yaml
curl 'https://raw.githubusercontent.com/coreos/prometheus-operator/v0.38.1/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml' -o thanosrulers.yaml
echo velero
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/backups.yaml' -o backups.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/backupstoragelocations.yaml' -o backupstoragelocations.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/deletebackuprequests.yaml' -o deletebackuprequests.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/downloadrequests.yaml' -o downloadrequests.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/podvolumebackups.yaml' -o podvolumebackups.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/podvolumerestores.yaml' -o podvolumerestores.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/resticrepositories.yaml' -o resticrepositories.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/restores.yaml' -o restores.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/schedules.yaml' -o schedules.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/serverstatusrequests.yaml' -o serverstatusrequests.yaml
curl 'https://raw.githubusercontent.com/vmware-tanzu/helm-charts/velero-2.8.2/charts/velero/crds/volumesnapshotlocations.yaml' -o volumesnapshotlocations.yaml
echo dex
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/authcodes.yaml' -o authcodes.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/authrequests.yaml' -o authrequests.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/connectors.yaml' -o connectors.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/oauth2clients.yaml' -o oauth2clients.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/offlinesessionses.yaml' -o offlinesessionses.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/passwords.yaml' -o passwords.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/refreshtokens.yaml' -o refreshtokens.yaml
curl 'https://raw.githubusercontent.com/dexidp/dex/v2.16.x/scripts/manifests/crds/signingkeies.yaml' -o signingkeies.yaml
echo Patching the dex crds with scope
sed -i 's/spec:/spec:\n  scope: Namespaced/' authcodes.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' authrequests.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' connectors.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' oauth2clients.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' offlinesessionses.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' passwords.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' refreshtokens.yaml
sed -i 's/spec:/spec:\n  scope: Namespaced/' signingkeies.yaml
