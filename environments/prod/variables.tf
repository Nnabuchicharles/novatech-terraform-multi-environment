variable "project" {
  type    = string
  default = "novatech"
}
variable "environment" { type = string }
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "availability_zone" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_cidr" { type = string }
variable "deploy_ec2" {
  type    = bool
  default = false
}
variable "allow_public_http" {
  type    = bool
  default = false
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
