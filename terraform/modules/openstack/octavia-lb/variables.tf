
variable subnet_id {}

variable prefix {
  type        = string
  description = "Prefix to be used for naming resources in a human readable way"
}

variable loadbalancer_targets {
  type = map(object({
    port     = number
    protocol = string
    # There is no way to specify optional arguments :(
    # https://github.com/hashicorp/terraform/issues/19898
    # Set them to `ignore` if needed to ignore them (e.g. with TCP protocol).
    health_path        = string
    health_codes       = string
    health_delay       = number
    health_timeout     = number
    health_max_retries = number
    target_ips = map(object({
      private_ip = string
    }))
  }))

  ## Example
  # default = {
  #   http = {
  #     port               = 80
  #     protocol           = "HTTP"
  #     target_ips         = { "worker-0" = { "private_ip" = "127.0.0.1" } }
  #     health_path        = "/healthz"
  #     health_codes       = "200"
  #     health_delay       = 20
  #     health_timeout     = 10
  #     health_max_retries = 5
  #   }
  #   kube_api = {
  #     port               = 6443
  #     protocol           = "TCP"
  #     target_ips         = { "master-0" = { "private_ip" = "127.0.0.1" } }
  #     health_path        = "ignore"
  #     health_codes       = "ignore"
  #     health_delay       = 20
  #     health_timeout     = 10
  #     health_max_retries = 5
  #   }
  # }
}

variable external_network_name {
  description = "the name of the external network"
  type        = string
}
