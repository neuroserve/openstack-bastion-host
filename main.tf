variable "auth_url" {
  type    = string
  default = "https://api.gx-scs.sovereignit.cloud:5000" 
}

variable "user_name" {
  type    = string
  default = "username" 
}

variable "password" {
  type    = string
  default = "totalgeheim" 
}

data "openstack_images_image_v2" "os" {
  name        = "Debian 11"
  most_recent = true
}

resource "openstack_compute_keypair_v2" "user_keypair" {
  name       = "tf_postgresql"
  public_key = file("${var.config.keypair}")
}

resource "openstack_networking_secgroup_v2" "sg_bastionhost" {
  name        = "sg_bastionhost"
  description = "Security Group for bastionhost"
}

resource "openstack_networking_secgroup_rule_v2" "sr_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_bastionhost.id
}

resource "openstack_networking_secgroup_rule_v2" "sr_dns1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_bastionhost.id
}

resource "openstack_networking_secgroup_rule_v2" "sr_dns2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_bastionhost.id
}

resource "openstack_networking_secgroup_rule_v2" "sr_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  port_range_min    = "1"
  port_range_max    = "65535"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sg_bastionhost.id
}

resource "openstack_networking_network_v2" "backnet" {
  name              = "backnet"
  admin_state_up    = "true"
}

resource "openstack_networking_subnet_v2" "subbacknet" {
  name              = "subbacknet"
  network_id        = "${openstack_networking_network_v2.backnet.id}"
  cidr              = "192.168.13.0/24"
  ip_version        = 4
}

resource "openstack_compute_instance_v2" "bastionhost" {
  name            = "bastionhost"
  image_id        = data.openstack_images_image_v2.os.id
  flavor_name     = var.config.flavor_name
  key_pair        = openstack_compute_keypair_v2.user_keypair.name
  security_groups = ["sg_bastionhost", "default"]   

  network {
    name = var.config.instance_network_name
  }

  network {
    name = "${openstack_networking_network_v2.backnet.name}"
  }
}

resource "openstack_networking_floatingip_v2" "bastion_flip" {
  pool = "ext01"
}

resource "openstack_compute_floatingip_associate_v2" "bastion_flip" {
  floating_ip = "${openstack_networking_floatingip_v2.bastion_flip.address}"
  instance_id = "${openstack_compute_instance_v2.bastionhost.id}"
}
