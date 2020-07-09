output "ubuntu_desktop_dns" {
  value = ["${aws_instance.ec2_ubuntu_desktop.*.public_dns}"]
}
output "ubuntu_desktop_ec2_id" {
  value = ["${aws_instance.ec2_ubuntu_desktop.*.id}"]
}