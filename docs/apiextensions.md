#### API Extensions
This document contains a list of all custom apiextensions in ck8s. If a component is added, removed, or replaced, this list should be updated accordingly. The "used by" column lists which components directly use this crd. Please note that it does not include the component itself, i.e. promethus-operator uses the servicemonitor crd.

### Cert-manager
cert-manager is a Kubernetes add-on to automate the management and issuance of TLS certificates from various issuing source. It will ensure certificates are valid and up to date periodically, and attempt to renew certificates at an appropriate time before expiry.

| crd | apigroup | kind | used by | description |
| :-- | :-- | :-- | :-- | :-- |
| certificaterequests | cert-manager.io | CertificateRequest | ck8sdash, dex, harbor, elasticsearch, kibana, grafana | An "advanced" and mostly internal resource for cert-manager. |
| certificates | cert-manager.io | Certificate | ck8sdash, dex, harbor, elasticsearch, kibana, grafana | The certificate "spec" basically. This does not contain the actual certificate but instead the specification with a reference to the Secret that holds the actual certificate data. |
| clusterissuers | cert-manager.io | ClusterIssuer | | A cluster scoped issuer. See `issuers`. |
| issuers | cert-manager.io | Issuer | dex, harbor, prometheus-instance, elasticsearch, kibana, grafana-customer, ck8sdash, customer-alertmanager  | An issuer describes how or from where a certificate should be produced. For example, create a self signed certificate or get one from Let's Encrypt. |
| orders | acme.cert-manager.io | Order | ck8sdash, dex, elasticsearch, harbor, grafana | Order resources are used by the ACME issuer to manage the lifecycle of an ACME ‘order’ for a signed TLS certificate. | 
| challenges | acme.cert-manager.io | Challenge | | The ACME Issuer type represents a single Account registered with the ACME server. | 

### Elasticsearch ECK
Elastic Cloud on Kubernetes automates the deployment, provisioning, management, and orchestration of Elasticsearch, Kibana and APM Server on Kubernetes based on the operator pattern.

| crd | apigroup | kind | used by | description | 
| :-- | :-- | :-- | :-- | :-- |
| elasticsearches | elasticsearch.k8s.elastic.co | Elasticsearch | elasticsearch-operator | Open source search and analytics solution, used for logs in ck8s | 
| apmservers | apm.k8s.elastic.co | ApmServer | elasticsearch-operator | The APM Server receives data from the Elastic APM agents and stores the data into Elasticsearch. |
| kibanas | kibana.k8s.elastic.co | Kibana | elasticsearch-operator | Open source frontend application for the Elastic Stack |

### Project Calico
Calico is an open source networking and network security solution for containers, virtual machines, and native host-based workloads. Calico supports a broad range of platforms including Kubernetes, OpenShift, Docker EE, OpenStack, and bare metal services.

| crd | apigroup | kind | used by | description | 
| :-- | :-- | :-- | :-- | :-- |
| bgpconfigurations | crd.projectcalico.org | BGPConfiguration | | | |
| bgppeers | crd.projectcalico.org | BGPPeer| 
| blockaffinities | crd.projectcalico.org | BlockAffinity | | |
| clusterinformations | crd.projectcalico.org | ClusterInformation| | |
| felixconfigurations | crd.projectcalico.org | FelixConfiguration | | |
| globalnetworkpolicies | crd.projectcalico.org | GlobalNetworkPolicy| | |
| globalnetworksets | crd.projectcalico.org | GlobalNetworkSet| | |
| hostendpoints | crd.projectcalico.org | HostEndpoint| | |
| ipamblocks | crd.projectcalico.org | IPAMBlock| | |
| ipamconfigs | crd.projectcalico.org | IPAMConfig | | |
| ipamhandles | crd.projectcalico.org | IPAMHandle | k8s-pod-network | |
| ippools | crd.projectcalico.org | IPPool| | |
| networkpolicies | crd.projectcalico.org | NetworkPolicy| | |
| networksets | crd.projectcalico.org | NetworkSet| | |

### Dex
Dex is an identity service that uses  [OpenID Connect](https://openid.net/connect/)  to drive authentication for other apps. Dex acts as a portal to other identity providers through  ["connectors."](https://github.com/dexidp/dex#connectors)  This lets dex defer authentication to LDAP servers, SAML providers, or established identity providers like GitHub, Google, and Active Directory. Clients write their authentication logic once to talk to dex, then dex handles the protocols for a given backend.

| crd | apigroup | kind | used by | description | 
| :-- | :-- | :-- | :-- | :-- |
| authcodes| dex.coreos.com| AuthCode | | |
| authrequests	| dex.coreos.com | AuthRequest | | |
| connectors | dex.coreos.com | Connector | dex | |
| oauth2clients	| dex.coreos.com | OAuth2Client | | |
| offlinesessionses | dex.coreos.com | OfflineSessions | | |
| passwords | dex.coreos.com | Password | | |
| refreshtokens | dex.coreos.com | RefreshToken | | |
| signingkeies | dex.coreos.com | SigningKey | | |

### prometheus-operator
The Prometheus Operator for Kubernetes provides easy monitoring definitions for Kubernetes services and deployment and management of Prometheus instances as it can create/configure/manage Prometheus clusters atop Kubernetes. 

| crd | apigroup | kind | used by | description | 
| :-- | :-- | :-- | :-- | :-- |
| alertmanagers	| monitoring.coreos.com | Alertmanager | prometheus-alerts | |
| podmonitors | monitoring.coreos.com | PodMonitor | customer-rbac | |
| prometheuses | monitoring.coreos.com | Prometheus | | |
| prometheusrules | monitoring.coreos.com | PrometheusRule | customer-rbac, elasticsearch | |
| servicemonitors | monitoring.coreos.com | ServiceMonitor | customer-rbac, dex, grafana, kibana, elastisearch, influxdb | |
| thanosrulers | monitoring.coreos.com | ThanosRuler | | |

### velero
Velero is an open source tool to safely backup and restore, perform disaster recovery, and migrate Kubernetes cluster resources and persistent volumes.

| crd | apigroup | kind | used by | description | 
| :-- | :-- | :-- | :-- | :-- |
| backups | velero.io | Backup | harbor-backup, influxdb | | 
| backupstoragelocations | velero.io | BackupStorageLocation | | |
| deletebackuprequests | velero.io | DeleteBackupRequest | | |
| downloadrequests | velero.io | DownloadRequest | | |
| podvolumebackups | velero.io | PodVolumeBackup | | |
| podvolumerestores | velero.io | PodVolumeRestore | | |
| resticrepositories | velero.io | ResticRepository | | |
| restores | velero.io | Restore | | |
| schedules | velero.io | Schedule | | |
| serverstatusrequests | velero.io | ServerStatusRequest | | |
| volumesnapshotlocations | velero.io | VolumeSnapshotLocation | | |

### gatekeeper-operator
Gatekeeper is currently an implementation of a Kubernetes Operator for installing, configuring and managing Open Policy Agent to provide dynamic admission controllers in a cluster.

| crd | apigroup | kind | used by | description | 
| :-- | :-- | :-- | :-- | :-- |
| configs | config.gatekeeper.sh | Config |  | Instantiates the policy library. | 
| constrainttemplates | templates.gatekeeper.sh | ConstraintTemplate | | Extends the policy library. |
| k8sallowedrepos | constraints.gatekeeper.sh | K8sAllowedRepos | | OPA policy. | 
| k8srequirenetworkpolicy | constraints.gatekeeper.sh | K8sRequireNetworkPolicy | | OPA policy. |
| k8sresourcerequests | constraints.gatekeeper.sh | K8sResourceRequests | | OPA policy. |
