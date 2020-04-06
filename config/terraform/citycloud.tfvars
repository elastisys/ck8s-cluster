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

worker_names_wc = [
  "worker-0",
]

worker_name_flavor_map_wc = {
  "worker-0" : "ecd976c3-c71c-4096-b138-e4d964c0b27f", #4core 8gb mem 50gb storage
}

master_names_sc = [
  "master-0",
]

master_name_flavor_map_sc = {
  "master-0" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
}

master_names_wc = [
  "master-0",
]

master_name_flavor_map_wc = {
  "master-0" : "89afeed0-9e41-4091-af73-727298a5d959" #2core 4gb mem 50gb storage
}

# TODO: Remove Elastisys range before making repository public
public_ingress_cidr_whitelist = "194.132.164.168/32" # Elastisys office
