# nat.tf
# NAT Gateway 2개 (각 AZ), Private 라우팅 테이블 2개, 
# App/DB 서브넷 → Private 라우팅 테이블 연결

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-nat-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-rt-private-${count.index + 1}"
  }
}

resource "aws_route_table_association" "app" {
  count = length(var.app_subnet_cidrs)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "db" {
  count = length(var.db_subnet_cidrs)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}