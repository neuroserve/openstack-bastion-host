# OpenStack Bastion Host

It can be a good idea to deploy one instance (or two) as a bastion host into your environment. Especially, if you want to deploy services, which should only be available internally.

## Prerequisites

1. You need to create the required image first. Try the openstack-packer repo.

## Deployment

Deploying with `terraform plan` and `terraform apply` you should get an instance as a bastion host with a floating ip address attached. 
