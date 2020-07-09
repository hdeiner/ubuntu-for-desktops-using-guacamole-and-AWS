resource "aws_instance" "ec2_ubuntu_desktop" {
  count = 1
  ami = "ami-0ac80df6eff0e70b5"  #  Ubuntu 18.04 LTS - Bionic - hvm:ebs-ssde  https://cloud-images.ubuntu.com/locator/ec2/
  instance_type = "t2.small"
  key_name = aws_key_pair.ubuntu_desktop_key_pair.key_name
  security_groups = [aws_security_group.ubuntu_desktop.name]
  tags = {
    Name = "Ubuntu Desktop ${format("%03d", count.index)}"
  }
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_dns
      private_key = file("~/.ssh/id_rsa")
    }
    script = "terraformUbuntuDesktopProvisionerNative.sh"
  }
}
