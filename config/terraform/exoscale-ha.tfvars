prefix_sc = ""
prefix_wc = ""

worker_names_sc = [
  "worker-0",
  "worker-1",
]

worker_name_size_map_sc = {
  "worker-0" : "Extra-large",
  "worker-1" : "Large",
}

worker_names_wc = [
  "worker-0",
]

worker_name_size_map_wc = {
  "worker-0" : "Large",
}

master_names_sc = [
  "master-0",
  "master-1",
  "master-2",
]

master_name_size_map_sc = {
  "master-0" : "Small",
  "master-1" : "Small",
  "master-2" : "Small",
}

master_names_wc = [
  "master-0",
  "master-1",
  "master-2",
]

master_name_size_map_wc = {
  "master-0" : "Small",
  "master-1" : "Small",
  "master-2" : "Small",
}

nfs_size = "Small"

# TODO: Remove Elastisys and A1 ranges before making repository public
public_ingress_cidr_whitelist = [
  # Elastisys office
  "194.132.164.168/32",
  "194.132.164.169/32",
  # A1 office
  "193.187.219.4/32",
]
