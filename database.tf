# database.tf
# Database resources for 371GPT

# Supabase instance (replaces separate PostgreSQL and MongoDB)
resource "openstack_compute_instance_v2" "supabase" {
  name            = "supabase"
  image_name      = "Ubuntu 20.04" 
  flavor_name     = "s1-8"  # Larger instance for Supabase
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

# Storage volume for Supabase
resource "openstack_blockstorage_volume_v2" "supabase_volume" {
  name        = "supabase-data"
  description = "Storage for Supabase (PostgreSQL + Vector DB)"
  size        = 200  # Size in GB
  volume_type = "classic"
}

# Attach volume to instance
resource "openstack_compute_volume_attach_v2" "supabase_volume_attach" {
  instance_id = openstack_compute_instance_v2.supabase.id
  volume_id   = openstack_blockstorage_volume_v2.supabase_volume.id
}

# Kespa automation instance
resource "openstack_compute_instance_v2" "kespa" {
  name            = "kespa-automation"
  image_name      = "Ubuntu 20.04"
  flavor_name     = "s1-4"
  key_pair        = var.ssh_key_pair
  security_groups = ["default", openstack_compute_secgroup_v2.secgroup.name]

  network {
    name = openstack_networking_network_v2.network.name
  }
}

# Storage volume for Kespa
resource "openstack_blockstorage_volume_v2" "kespa_volume" {
  name        = "kespa-data"
  description = "Storage for Kespa automation"
  size        = 50  # Size in GB
  volume_type = "classic"
}

# Attach volume to instance
resource "openstack_compute_volume_attach_v2" "kespa_volume_attach" {
  instance_id = openstack_compute_instance_v2.kespa.id
  volume_id   = openstack_blockstorage_volume_v2.kespa_volume.id
} 