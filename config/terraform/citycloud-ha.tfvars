#Leaving these blank will generate a default prefix
prefix_sc = ""
prefix_wc = ""

worker_names_sc = [
  "worker-0",
  "worker-1",
]

worker_name_flavor_map_sc = {
  "worker-0" : "f6a5e4d3-203d-45c0-a36a-dc5538580e1a", #4core 16gb mem 50gb storage
  "worker-1" : "ecd976c3-c71c-4096-b138-e4d964c0b27f" #4core 8gb mem 50gb storage
}

worker_anti_affinity_policy_sc = "soft-anti-affinity"

worker_names_wc = [
  "worker-0",
]

worker_name_flavor_map_wc = {
  "worker-0" : "ecd976c3-c71c-4096-b138-e4d964c0b27f", #4core 8gb mem 50gb storage
}

worker_anti_affinity_policy_wc = "soft-anti-affinity"

master_names_sc = [
  "master-0",
  "master-1",
  "master-2",
]

master_name_flavor_map_sc = {
  "master-0" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
  "master-1" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
  "master-2" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
}

master_anti_affinity_policy_sc = "anti-affinity"

master_names_wc = [
  "master-0",
  "master-1",
  "master-2",
]

master_name_flavor_map_wc = {
  "master-0" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
  "master-1" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
  "master-2" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
}

master_anti_affinity_policy_wc = "anti-affinity"

# TODO: Remove Elastisys range before making repository public
public_ingress_cidr_whitelist = ["194.132.164.168/32", "194.132.164.169/32"] # Elastisys office
api_server_whitelist = ["194.132.164.168/32", "194.132.164.169/32"]
nodeport_whitelist = ["194.132.164.168/32", "194.132.164.169/32"] # Elastisys office

aws_dns_zone_id="Z2STJRQSJO5PZ0" # elastisys.se
aws_dns_role_arn="arn:aws:iam::248119176842:role/a1-pipeline"

external_network_id="2aec7a99-3783-4e2a-bd2b-bbe4fef97d1c"
external_network_name="ext-net"
