resource "aws_vpc" "rahulverse_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    "Name" = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }

  vpc_id                  = aws_vpc.rahulverse_vpc.id
  cidr_block              = each.value
  availability_zone       = var.public_subnet_availability_zones[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }

  vpc_id            = aws_vpc.rahulverse_vpc.id
  cidr_block        = each.value
  availability_zone = var.private_subnet_availability_zones[tonumber(each.key)]

  tags = {
    Name = "${var.environment}-private-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "rahulverse_igw" {
  vpc_id = aws_vpc.rahulverse_vpc.id
  tags = {
    Name = "${var.environment}-internet-gateway"
  }
}

resource "aws_route_table" "rahulverse_route_table" {
  vpc_id = aws_vpc.rahulverse_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rahulverse_igw.id
  }

  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

resource "aws_route_table_association" "public_route_table_assoc" {
  for_each       = aws_subnet.public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.rahulverse_route_table.id
}
