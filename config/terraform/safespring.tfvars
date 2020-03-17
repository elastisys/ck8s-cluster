prefix_sc = ""
prefix_wc = ""

public_v4_network = "71b10496-2617-47ae-abbc-36239f0863bb"

worker_names_sc = [
  "worker-0",
  "worker-1",
]

worker_name_flavor_map_sc = {
  "worker-0" : "fce2b54d-c0ef-4ad4-aa81-bcdcaa54f7cb",
  "worker-1" : "16d11558-62fe-4bce-b8de-f49a077dc881",
}

worker_names_wc = [
  "worker-0",
]

worker_name_flavor_map_wc = {
  "worker-0" : "16d11558-62fe-4bce-b8de-f49a077dc881",
}

master_names_sc = [
  "master-0",
]

master_name_flavor_map_sc = {
  "master-0" : "9d82d1ee-ca29-4928-a868-d56e224b92a1",
}

master_names_wc = [
  "master-0",
]

master_name_flavor_map_wc = {
  "master-0" : "9d82d1ee-ca29-4928-a868-d56e224b92a1",
}

worker_extra_volume_sc = []

worker_extra_volume_wc = []

worker_extra_volume_size_sc = {}

worker_extra_volume_size_wc = {}

# TODO: Remove Elastisys range before making repository public
public_ingress_cidr_whitelist = "194.132.164.168/32" # Elastisys office
