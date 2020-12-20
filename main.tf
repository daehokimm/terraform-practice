provider "aws" {
    region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami = "ami-007b7745d0725de95" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type
  instance_type = "t2.micro"

  tags = {
    "Name" = "terraform-example"
  }
}
