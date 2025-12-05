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

output "mysql_info" {
  description = "Información de MySQL (corre en Docker dentro del EC2)"
  value       = "MySQL corre en Docker dentro del mismo EC2 en localhost:3306"
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

