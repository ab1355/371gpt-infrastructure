# outputs.tf
# Information about created resources

output "network_id" {
  value       = openstack_networking_network_v2.network.id
  description = "The ID of the main network"
}

output "subnet_id" {
  value       = openstack_networking_subnet_v2.subnet.id
  description = "The ID of the main subnet"
}

output "gpt_core_instance_id" {
  value       = openstack_compute_instance_v2.gpt_core.id
  description = "ID of the 371GPT Core instance"
}

output "gpt_core_ip" {
  value       = openstack_compute_instance_v2.gpt_core.access_ip_v4
  description = "IP address of the 371GPT Core instance"
}

output "xpipe_server_ip" {
  value       = openstack_compute_instance_v2.xpipe_server.access_ip_v4
  description = "IP address of the XPipe server"
}

output "supabase_ip" {
  value       = openstack_compute_instance_v2.supabase.access_ip_v4
  description = "IP address of the Supabase server"
}

output "kespa_ip" {
  value       = openstack_compute_instance_v2.kespa.access_ip_v4
  description = "IP address of the Kespa automation server"
} 