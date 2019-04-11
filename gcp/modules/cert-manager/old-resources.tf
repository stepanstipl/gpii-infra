resource "null_resource" "cert_manager_resources" {
  depends_on = ["module.cert-manager"]

  triggers = {
    nonce = "${var.nonce}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/resources/"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --ignore-not-found -f ${path.module}/resources/ || true"
  }
}
