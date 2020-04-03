prefix_sc = ""
prefix_wc = ""

public_v4_network = "71b10496-2617-47ae-abbc-36239f0863bb"

worker_names_sc = [
  "worker-0",
  "worker-1",
]

worker_name_flavor_map_sc = {
  "worker-0" : "ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf", # lb.xlarge.1d
  "worker-1" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

worker_names_wc = [
  "worker-0",
]

worker_name_flavor_map_wc = {
  "worker-0" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

master_names_sc = [
  "master-0",
]

master_name_flavor_map_sc = {
  # TODO: could go with smaller flavor here if made available
  "master-0" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

master_names_wc = [
  "master-0",
]

master_name_flavor_map_wc = {
  # TODO: could go with smaller flavor here if made available
  "master-0" : "dc67a9eb-0685-4bb6-9383-a01c717e02e8", # lb.large.1d
}

# TODO: Remove Elastisys range before making repository public
public_ingress_cidr_whitelist = "194.132.164.168/32" # Elastisys office
