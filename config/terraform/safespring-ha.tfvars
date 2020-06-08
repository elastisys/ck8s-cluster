#Leaving these blank will generate a default prefix
prefix_sc = ""
prefix_wc = ""

worker_names_sc = [
  "worker-0",
  "worker-1",
]

worker_name_flavor_map_sc = {
  "worker-0" : "ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf", # lb.xlarge.1d
  "worker-1" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

worker_anti_affinity_policy_sc = ""

worker_names_wc = [
  "worker-0",
]

worker_name_flavor_map_wc = {
  "worker-0" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

worker_anti_affinity_policy_wc = ""

master_names_sc = [
  "master-0",
  "master-1",
  "master-2",
]

master_name_flavor_map_sc = {
  # TODO: could go with smaller flavor here if made available
  "master-0" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
  "master-1" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
  "master-2" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

master_anti_affinity_policy_sc = "anti-affinity"

master_names_wc = [
  "master-0",
  "master-1",
  "master-2",
]

master_name_flavor_map_wc = {
  # TODO: could go with smaller flavor here if made available
  "master-0" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
  "master-1" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
  "master-2" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

master_anti_affinity_policy_wc = "anti-affinity"

loadbalancer_names_sc=[
  "loadbalancer-0"
]

loadbalancer_name_flavor_map_sc={
    "loadbalancer-0" : "51d480b8-2517-4ba8-bfe0-c649ac93eb61" # lb.tiny
}

loadbalancer_names_wc=[
  "loadbalancer-0"
]

loadbalancer_name_flavor_map_wc={
    "loadbalancer-0" : "51d480b8-2517-4ba8-bfe0-c649ac93eb61" # lb.tiny
}

# TODO: Remove Elastisys range before making repository public
public_ingress_cidr_whitelist = ["194.132.164.168/32", "194.132.164.169/32"] # Elastisys office
api_server_whitelist = ["194.132.164.168/32", "194.132.164.169/32"] # Elastisys office

aws_dns_zone_id="Z2STJRQSJO5PZ0" # elastisys.se
aws_dns_role_arn="arn:aws:iam::248119176842:role/a1-pipeline"

external_network_id="71b10496-2617-47ae-abbc-36239f0863bb"
external_network_name="public-v4"
