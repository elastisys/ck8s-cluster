region="us-west-1"
public_ingress_cidr_whitelist=["194.132.164.168/32", "194.132.164.169/32"] # Elastisys office
prefix_sc=""
prefix_wc=""

worker_nodes_sc={
    "worker-0" : "t3.xlarge",
    "worker-1" : "t3.large"
}
worker_nodes_wc={
    "worker-0" : "t3.large",
    "worker-1" : "t3.large"
}
master_nodes_sc={
    "master-0" : "t3.small"
}
master_nodes_wc={
    "master-0" : "t3.small"
}
