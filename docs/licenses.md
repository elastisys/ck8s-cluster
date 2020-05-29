### Licenses
This table lists the licenses that are used by the different software components in ck8s.

#### License description
| license | link | summary | OK for ck8s | comment |
| :-- | :-- | :-- | :-- | :-- |
| apache 2.0 | https://www.apache.org/licenses/LICENSE-2.0 | https://tldrlegal.com/license/apache-license-2.0-(apache-2.0) | YES | Permissive license |
| BSD (4-clause) | https://directory.fsf.org/wiki/License:BSD-4-Clause | https://tldrlegal.com/license/4-clause-bsd | YES | Need to credit the copyright holders |
| BSD (3-clause) | https://directory.fsf.org/wiki/License:BSD-3-Clause | https://tldrlegal.com/license/bsd-3-clause-license-(revised) | YES | Need to credit the copyright holders |
| BSD (2-clause) | https://directory.fsf.org/wiki/License:BSD-2-Clause | https://tldrlegal.com/license/bsd-2-clause-license-(freebsd) | YES | Need to credit the copyright holders |
| Elastic | https://github.com/elastic/elasticsearch/blob/master/licenses/ELASTIC-LICENSE.txt | | NO | Disallows SaaS |
| MIT | https://opensource.org/licenses/MIT | https://tldrlegal.com/license/mit-license | YES | Permissive license |
| GreenSock | https://greensock.com/standard-license/ | | NO | Disallows paid SaaS |
| postgresql | https://opensource.org/licenses/postgresql | https://tldrlegal.com/license/postgresql-license-(postgresql) | YES | Permissive license |  
| GPL | https://www.gnu.org/licenses/gpl-3.0.txt | https://tldrlegal.com/license/gnu-lesser-general-public-license-v3-(lgpl-3) | YES | Permissive license |

#### License table
This table contains a list of all software components in ck8s and theire respective licenses. If a component is added, removed, or replaced, this list should be uptated accordingly.

| component          | type                      | used in    | license            | link |
| :-- | :--| :-- | :-- | :-- |
| k8s                | container orchestration   | ck8s       | apache 2.0         | [https://kubernetes.io/](https://kubernetes.io/) |
| elasticsearch      | logs search/analytics     | ck8s       | apache 2.0/elastic | [https://www.elastic.co/](https://www.elastic.co/) |
| kibana             | dashboard                 | ck8s       | apache 2.0/elastic | [https://www.elastic.co/](https://www.elastic.co/) |
| nginx              | webbserver/proxy          | ck8s       | BSD 4-clause       | [https://www.nginx.com/](https://www.nginx.com/) |
| nfs                | nfs provisioner           | ck8s       | apache 2.0         | [https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client) |
| cert-manager       | encryption                | ck8s       | apache 2.0         | [https://cert-manager.io/](https://cert-manager.io/) |
| prometheus         | metrics                   | ck8s       | apache 2.0         | [https://github.com/coreos/prometheus-operator](https://github.com/coreos/prometheus-operator) |
| ck8sdash           | web gui                   | ck8s       | apache 2.0         | [https://github.com/elastisys/ck8s-dash](https://github.com/elastisys/ck8s-dash) |
| node-local-dns     | dns                       | ck8s       | apache 2.0         | [https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/) |
| metrics-server     | resource usage aggregator | ck8s       | apache 2.0         | [https://github.com/kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server) |
| dex                | oauth 2.0 provider        | ck8s       | apache 2.0         | [https://github.com/dexidp/dex](https://github.com/dexidp/dex) |
| grafana            | dashboard                 | ck8s       | apache 2.0         | [https://grafana.com/](https://grafana.com/) |
| harbor             | image registry            | ck8s       | apache 2.0         | [https://goharbor.io/](https://goharbor.io/) |
| influxdb           | time series database      | ck8s       | MIT                | [https://www.influxdata.com/](https://www.influxdata.com/) |
| fluentd            | data collector            | ck8s       | apache 2.0         | [https://www.fluentd.org/](https://www.fluentd.org/) |
| velero             | backup tool               | ck8s       | apache 2.0         | [https://velero.io/](https://velero.io/) |
| falco              | runtime security          | ck8s       | apache 2.0         | [https://falco.org/](https://falco.org/) |
| opa                | admission controller      | ck8s       | apache 2.0         | [https://www.openpolicyagent.org/](https://www.openpolicyagent.org/) |
| opa gatekeeper     | adminssion webhook        | ck8s       | apache 2.0         | [https://github.com/open-policy-agent/gatekeeper](https://github.com/open-policy-agent/gatekeeper) |
| haproxy            | load balancer             | ck8s       | LGPL               | [http://www.haproxy.org/](http://www.haproxy.org/) |
| terraform          | infrastrucutre as code    | ck8s       | MPL 2.0            | [https://www.terraform.io/](https://www.terraform.io/) |
| ansible (CLI only) | configuration management  | ck8s       | GPL                | [https://www.ansible.com/](https://www.ansible.com/) |
| postgresql         | relational database       | postgresql | postgresql         | [https://www.postgresql.org/](https://www.postgresql.org/) |
| babel              | JS compiler               | ck8sdash   | MIT                | [https://github.com/babel/babel](https://github.com/babel/babel) |
| go-idc             | Open ID connect client    | ck8sdash   | apache 2.0         | [https://github.com/coreos/go-oidc/](https://github.com/coreos/go-oidc/blob/v2/LICENSE) |
| go-chi             | router                    | ck8sdash   | apache 2.0         | [https://github.com/go-chi](https://github.com/go-chi) |
| pkg-errors         | error handling            | ck8sdash   | BSD 2-clause       | [github.com/pkg/errors](http://github.com/pkg/errors) |
| go-elasticsearch   | elasticsearch client      | ck8sdash   | apache 2.0         | [github.com/elastic/go-elasticsearch](http://github.com/elastic/go-elasticsearch) |
| cachecontrol       | http caching parser       | ck8sdash   | apache 2.0         | [github.com/pquerna/cachecontrol](http://github.com/pquerna/cachecontrol) |
| oauth2             | oauth2 client             | ck8sdash   | BSD 3-clause       | [https://pkg.go.dev/golang.org/x/oauth2](https://pkg.go.dev/golang.org/x/oauth2) |
| go-jose            | JS signing and encryption | ck8sdash   | apache 2.0         | [https://github.com/square/go-jose](https://github.com/square/go-jose) |
| ansi-to-react      | ansi -> react converter   | ck8sdash   | BSD 3-clause       | [https://github.com/nteract/ansi-to-react](https://github.com/nteract/ansi-to-react) |
| antd               | UI library                | ck8sdash   | MIT                | [https://www.npmjs.com/package/antd](https://www.npmjs.com/package/antd) |
| lodash             | JS library                | ck8sdash   | MIT                | [https://github.com/lodash/lodash](https://github.com/lodash/lodash) |
| gsap               | JS library                | ck8sdash   | GreenSock          | [https://github.com/greensock/GSAP](https://github.com/greensock/GSAP) |
| query-string       | URL parser                | ck8sdash   | MIT                | [https://www.npmjs.com/package/query-string](https://www.npmjs.com/package/query-string) |
| react              | JS library                | ck8sdash   | MIT                | [https://github.com/facebook/react](https://github.com/facebook/react) |
| redux              | state container           | ck8sdash   | MIT                | [https://github.com/reduxjs/redux](https://github.com/reduxjs/redux) |
| style-components   | JS library                | ck8sdash   | MIT                | [https://github.com/styled-components/styled-components](https://github.com/styled-components/styled-components) |
| swagger-parser     | parser                    | ck8sdash   | apache 2.0         | [https://github.com/swagger-api/swagger-parser](https://github.com/swagger-api/swagger-parser) |
| time-ago           | JS library                | ck8sdash   | MIT                | [https://github.com/hustcc/timeago](https://github.com/hustcc/timeago) |
| xtermjs            | xterm frontend            | ck8sdash   | MIT                | [https://github.com/xtermjs/xterm.js/](https://github.com/xtermjs/xterm.js/) |
| yamljs             | yaml parser               | ck8sdash   | MIT                | [https://www.npmjs.com/package/yamljs](https://www.npmjs.com/package/yamljs) |
| enzyme             | test library              | ck8sdash   | MIT                | [https://github.com/enzymejs/enzyme](https://github.com/enzymejs/enzyme) |
| prettier           | code formatter            | ck8sdash   | MIT                | [https://github.com/prettier/prettier](https://github.com/prettier/prettier) |
| proptypes          | type checking             | ck8sdash   | MIT                | [https://www.npmjs.com/package/prop-types](https://www.npmjs.com/package/prop-types) |
| eslint             | JS linter                 | ck8sdash   | MIT                | [https://github.com/eslint/eslint](https://github.com/eslint/eslint) |
