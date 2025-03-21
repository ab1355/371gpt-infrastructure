# storage.tf
# Persistent storage volumes for our instances

# Volume for GPT Core data
resource "openstack_blockstorage_volume_v2" "gpt_core_volume" {
  name        = "gpt-core-data"
  description = "Storage for 371GPT Core data"
  size        = 100  # Size in GB
  volume_type = "classic"  # Adjust based on available volume types
}

# Volume for XPipe server data
resource "openstack_blockstorage_volume_v2" "xpipe_volume" {
  name        = "xpipe-data" 
  description = "Storage for XPipe server data"
  size        = 50  # Size in GB
  volume_type = "classic"  # Adjust based on available volume types
}

# Attach volumes to instances
resource "openstack_compute_volume_attach_v2" "gpt_core_volume_attach" {
  instance_id = openstack_compute_instance_v2.gpt_core.id
  volume_id   = openstack_blockstorage_volume_v2.gpt_core_volume.id
}

resource "openstack_compute_volume_attach_v2" "xpipe_volume_attach" {
  instance_id = openstack_compute_instance_v2.xpipe_server.id
  volume_id   = openstack_blockstorage_volume_v2.xpipe_volume.id
} 