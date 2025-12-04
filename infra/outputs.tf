output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.ecommerce_vpc.id
}

output "ec2_instance_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.ecommerce_app.id
}

output "ec2_public_ip" {
  description = "IP pública de la instancia EC2"
  value       = aws_instance.ecommerce_app.public_ip
}

output "ec2_public_dns" {
  description = "DNS público de la instancia EC2"
  value       = aws_instance.ecommerce_app.public_dns
}

output "rds_endpoint" {
  description = "Endpoint de RDS"
  value       = aws_db_instance.ecommerce_db.address
  sensitive   = true
}

output "rds_port" {
  description = "Puerto de RDS"
  value       = aws_db_instance.ecommerce_db.port
}

output "application_url" {
  description = "URL de la aplicación"
  value       = "http://${aws_instance.ecommerce_app.public_ip}:${var.app_port}"
}

output "application_url_dns" {
  description = "URL de la aplicación usando DNS"
  value       = "http://${aws_instance.ecommerce_app.public_dns}:${var.app_port}"
}

output "ssh_command" {
  description = "Comando SSH para conectarse a la instancia"
  value       = "ssh -i <key-file> ubuntu@${aws_instance.ecommerce_app.public_ip}"
}

