variable "region" {
  type    = string
  default = "eastus"
}

#https://learn.microsoft.com/en-us/azure/firewall/snat-private-range
variable "disable_snat_ip_range" {
  description = "The address space to be used to ensure that SNAT is disabled."
  default     = ["255.255.255.255/32"]
  type        = list(any)
}
