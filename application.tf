# application.tf
# Application-specific infrastructure for 371GPT

# FastAPI Gateway for agent communication
resource "openstack_compute_instance_v2" "fastapi_gateway" {
  name            = "fastapi-gateway"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "s1-4"  # 4 vCPUs, 4 GB RAM
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

# Agenta development environment
resource "openstack_compute_instance_v2" "agenta" {
  name            = "agenta-dev"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "s1-8"  # 8 vCPUs, 8 GB RAM for development
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

# NocoDB for configuration management
resource "openstack_compute_instance_v2" "nocodb" {
  name            = "nocodb"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "s1-4"
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

# NiceGUI admin interface
resource "openstack_compute_instance_v2" "nicegui" {
  name            = "nicegui-admin"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "s1-4"
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

# Storage volumes
resource "openstack_blockstorage_volume_v2" "agenta_volume" {
  name        = "agenta-data"
  description = "Storage for Agenta development environment"
  size        = 100  # Size in GB
  volume_type = "classic"
}

resource "openstack_blockstorage_volume_v2" "nocodb_volume" {
  name        = "nocodb-data"
  description = "Storage for NocoDB configuration database"
  size        = 50  # Size in GB
  volume_type = "classic"
}

# Attach volumes to instances
resource "openstack_compute_volume_attach_v2" "agenta_volume_attach" {
  instance_id = openstack_compute_instance_v2.agenta.id
  volume_id   = openstack_blockstorage_volume_v2.agenta_volume.id
}

resource "openstack_compute_volume_attach_v2" "nocodb_volume_attach" {
  instance_id = openstack_compute_instance_v2.nocodb.id
  volume_id   = openstack_blockstorage_volume_v2.nocodb_volume.id
} 