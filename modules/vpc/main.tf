// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-vpc"
    Environment = var.env_name
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-private-${count.index + 1}"
    Environment = var.env_name
    Tier        = "Private"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-public-${count.index + 1}"
    Environment = var.env_name
    Tier        = "Public"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-igw"
    Environment = var.env_name
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-nat-eip-${count.index + 1}"
    Environment = var.env_name
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-nat-${count.index + 1}"
    Environment = var.env_name
  }
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-public-rt"
    Environment = var.env_name
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-private-rt-${count.index + 1}"
    Environment = var.env_name
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  log_destination      = aws_cloudwatch_log_group.flow_log.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  iam_role_arn         = aws_iam_role.flow_log.arn
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-vpc-flow-logs"
    Environment = var.env_name
  }
}

resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc-flow-log/${var.app_name}-${var.env_name}"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-vpc-flow-logs-group"
    Environment = var.env_name
  }
}

resource "aws_iam_role" "flow_log" {
  name = "${var.app_name}-${var.env_name}-vpc-flow-log-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-vpc-flow-log-role"
    Environment = var.env_name
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.app_name}-${var.env_name}-vpc-flow-log-policy"
  role = aws_iam_role.flow_log.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}