# Elastic Stack Performance Benchmark

We use [Rally](https://esrally.readthedocs.io/) to benchmark our Elasticsearch cluster.

A full ck8s deployment is required.

## Running benchmark

In order to run the benchmark follow the steps below.

*Remarks: [http_logs](https://github.com/elastic/rally-tracks/tree/master/http_logs) track requires over 30 GiB of storage space (that is a local storage by default, so we might need to run it on a node with more storage than normal or add a persistent volume for it). The execution takes approx. 2.5 hour.*

1. Get IP addresses of Elasticsearch nodes

        kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get pod -n elastic-system -l common.k8s.elastic.co/type=elasticsearch -o jsonpath='{.items[*].status.podIP}'

    or check in the Kibana Stack Monitoring dashboard

1. Get Elastic password:

        kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode

1. Run Rally (set `Elasticsearch version`, `IP addresses` and `password`):

        kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" run --image=elastic/rally --restart=Never rally -n elastic-system -- --distribution-version=<Elasticsearch version> --track=http_logs --target-hosts=<IP addresses with 9200 port> --pipeline=benchmark-only --client-options="use_ssl:true,verify_certs:false,basic_auth_user:'elastic',basic_auth_password:'<password>'"

    For example:

        kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" run --image=elastic/rally --restart=Never rally -n elastic-system -- --distribution-version=7.3.1 --track=http_logs --target-hosts=10.42.1.16:9200,10.42.2.12:9200,10.42.3.15:9200 --pipeline=benchmark-only --client-options="use_ssl:true,verify_certs:false,basic_auth_user:'elastic',basic_auth_password:'677qlhsrsdtrj9sbnknwjtps'"

    To check the benchmark run progress:

        kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" logs -n elastic-system rally; echo

## Ideas for extensions/improvements
* Create a tailored Rally track based on logs (documents) from an actual ck8s cluster (add additional output in fluentd) read more about [adding tracks in Rally](https://esrally.readthedocs.io/en/latest/adding_tracks.html) and [file output in fluentd](https://docs.fluentd.org/output/file)
* Increase the number of Elasticsearch nodes and introduce specialized nodes (ingest or data) [read more](https://www.elastic.co/guide/en/elasticsearch/reference/6.2/modules-node.html)
* Execute Rally outside of the Service Cluster (maybe in the Workload Cluster?)
