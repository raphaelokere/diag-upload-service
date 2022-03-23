variable "cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}

variable "subnets" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

}

variable "repo_name" {
  type    = string
  default = "dev"
}

variable "branch_name" {
  type    = string
  default = "master"
}

variable "build_project" {
  type    = string
  default = "dev-build-repo"
}

variable "uri_repo" {
  type = string
  #The URI_REPO value is in a TF_VAR in my PC
}
