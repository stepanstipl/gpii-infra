variable "environment" {}

output "couchdb_us-east-2a_volume_id" {
  value = "${aws_ebs_volume.couchdb_us-east-2a.id}"
}

output "couchdb_us-east-2b_volume_id" {
  value = "${aws_ebs_volume.couchdb_us-east-2b.id}"
}

output "couchdb_us-east-2c_volume_id" {
  value = "${aws_ebs_volume.couchdb_us-east-2c.id}"
}

output "prometheus_us-east-2b_volume_id" {
  value = "${aws_ebs_volume.prometheus_us-east-2b.id}"
}

output "prometheus_us-east-2c_volume_id" {
  value = "${aws_ebs_volume.prometheus_us-east-2c.id}"
}
