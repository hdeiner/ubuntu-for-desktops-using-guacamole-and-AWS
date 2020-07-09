resource "aws_key_pair" "ubuntu_desktop_key_pair" {
  key_name = "ubuntu_desktop_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}