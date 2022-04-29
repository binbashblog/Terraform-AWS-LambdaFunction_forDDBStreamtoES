variable "stream_arn" {
  description = "The dynamo db stream arn"
}

variable "ddb_arn" {
  description = "The dynamo db arn"
}

variable "domain_arn" {
  description = "The ElasticSearch Domain to populate with the data"
}

variable "es_host" {
  description = "the host for submiting index, search requests"
}

variable "sync_subnet_ids" {
  type = "list",
  default = [""]
}

variable "sync_azs" {
  description = "(Optional) The availability zones the instance should be launched in."
  type = "list"
  default = [ "1a", "1b", "1c"]
}

variable "sync_multi_az" {}

variable "subnets_name" {
  description = "(Optional) The name of the subnets to launch the instances in."
}

variable "subnet_env" {
  description = "The name of the data subnets created for the instances."
  default = "example-1-2-3-4-5"
}
