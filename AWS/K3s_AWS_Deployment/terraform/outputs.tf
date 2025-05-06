output "k3s_server_public_ip" {
  description = "Public IP address of the K3s server"
  value       = aws_instance.k3s_server.public_ip
}

output "k3s_server_public_dns" {
  description = "Public DNS name of the K3s server"
  value       = aws_instance.k3s_server.public_dns
}

output "k3s_connection_command" {
  description = "Command to SSH into the K3s server"
  value       = "ssh ubuntu@${aws_instance.k3s_server.public_ip}"
}

output "k3s_ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}