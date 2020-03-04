resource "aws_db_instance" "mahesh-test" {
  allocated_storage    = 8
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "Exmapledb"
  username             = "admin"
  password             = "Admin#123"
  parameter_group_name = "default.mysql5.7"
}
