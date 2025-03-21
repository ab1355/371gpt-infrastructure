# network.tf
resource "openstack_networking_network_v2" "network" {
  name           = "371minds-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name       = "371minds-subnet"
  network_id = openstack_networking_network_v2.network.id
  cidr       = "192.168.1.0/24"
  ip_version = 4
}

# Create a security group for our instances
resource "openstack_compute_secgroup_v2" "secgroup" {
  name        = "371minds-secgroup"
  description = "Security group for 371GPT instances"

  # SSH access
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # HTTP access
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # HTTPS access
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # Supabase PostgreSQL port
  rule {
    from_port   = 5432
    to_port     = 5432
    ip_protocol = "tcp"
    cidr        = "192.168.1.0/24"  # Limit to internal network
  }

  # Supabase REST API port
  rule {
    from_port   = 3000
    to_port     = 3000
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# instances.tf - Start with core components
resource "openstack_compute_instance_v2" "gpt_core" {
  name            = "371gpt-core"
  image_name      = "Ubuntu 20.04"  # Use appropriate image
  flavor_name     = "s1-8"  # Adjust as needed
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

resource "openstack_compute_instance_v2" "xpipe_server" {
  name            = "xpipe-server"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "s1-4"
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}