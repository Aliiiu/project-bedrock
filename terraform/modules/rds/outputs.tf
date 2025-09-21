output "mysql_endpoint" {
  description = "MySQL RDS endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "postgres_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.carts.name
}

output "mysql_username" {
  description = "MySQL username"
  value       = aws_db_instance.mysql.username
}

output "postgres_username" {
  description = "PostgreSQL username"
  value       = aws_db_instance.postgres.username
}

output "mysql_database_name" {
  description = "MySQL database name"
  value       = aws_db_instance.mysql.db_name
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}