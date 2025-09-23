# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.cluster_name}-db-subnet-group"
    Environment = var.environment
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for RDS instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-rds-sg"
    Environment = var.environment
  }
}

# Random passwords for databases
resource "random_password" "mysql_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "postgres_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# MySQL RDS Instance for Catalog Service
resource "aws_db_instance" "mysql" {
  identifier = "${var.cluster_name}-catalog-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.mysql_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = "catalog"
  username = "catalog_user"
  password = random_password.mysql_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-catalog-mysql"
    Environment = var.environment
    Service     = "catalog"
  }
}

# PostgreSQL RDS Instance for Orders Service
resource "aws_db_instance" "postgres" {
  identifier = "${var.cluster_name}-orders-postgres"

  engine         = "postgres"
  engine_version = "15.7"
  instance_class = var.postgres_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type         = "gp2"
  storage_encrypted    = true

  db_name  = "orders"
  username = "orders_user"
  password = random_password.postgres_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "${var.cluster_name}-orders-postgres"
    Environment = var.environment
    Service     = "orders"
  }
}

# DynamoDB Table for Carts Service
resource "aws_dynamodb_table" "carts" {
  name           = "${var.cluster_name}-carts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "customerId"

  attribute {
    name = "customerId"
    type = "S"
  }

  tags = {
    Name        = "${var.cluster_name}-carts"
    Environment = var.environment
    Service     = "carts"
  }
}

# Secrets for database credentials
resource "kubernetes_secret" "mysql_credentials" {
  metadata {
    name      = "catalog-db-secret"
    namespace = "default"
  }

  data = {
    username = base64encode(aws_db_instance.mysql.username)
    password = base64encode(aws_db_instance.mysql.password)
    host     = base64encode(aws_db_instance.mysql.endpoint)
    database = base64encode(aws_db_instance.mysql.db_name)
  }

  type = "Opaque"
}

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "orders-db-secret"
    namespace = "default"
  }

  data = {
    username = base64encode(aws_db_instance.postgres.username)
    password = base64encode(aws_db_instance.postgres.password)
    host     = base64encode(aws_db_instance.postgres.endpoint)
    database = base64encode(aws_db_instance.postgres.db_name)
  }

  type = "Opaque"
}

resource "kubernetes_secret" "dynamodb_credentials" {
  metadata {
    name      = "carts-dynamodb-secret"
    namespace = "default"
  }

  data = {
    table_name = base64encode(aws_dynamodb_table.carts.name)
    region     = base64encode(var.aws_region)
  }

  type = "Opaque"
}

# ConfigMaps for application configuration with real values
resource "kubernetes_config_map" "catalog" {
  metadata {
    name      = "catalog"
    namespace = "default"
  }

  data = {
    DB_ENDPOINT = aws_db_instance.mysql.endpoint
    DB_USER     = aws_db_instance.mysql.username
    DB_NAME     = aws_db_instance.mysql.db_name
  }
}

resource "kubernetes_config_map" "orders" {
  metadata {
    name      = "orders"
    namespace = "default"
  }

  data = {
    SPRING_DATASOURCE_URL        = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}:5432/orders"
    SPRING_DATASOURCE_USERNAME   = aws_db_instance.postgres.username
    SPRING_DATASOURCE_WRITER_URL = "jdbc:postgresql://${aws_db_instance.postgres.endpoint}:5432/orders"
  }
}

resource "kubernetes_config_map" "carts" {
  metadata {
    name      = "carts"
    namespace = "default"
  }

  data = {
    CARTS_DYNAMODB_TABLENAME = aws_dynamodb_table.carts.name
    CARTS_DYNAMODB_ENDPOINT  = ""
    AWS_REGION              = var.aws_region
  }
}

resource "kubernetes_config_map" "checkout" {
  metadata {
    name      = "checkout"
    namespace = "default"
  }

  data = {
    REDIS_URL = "redis://redis:6379"  # Using in-cluster Redis for checkout
  }
}