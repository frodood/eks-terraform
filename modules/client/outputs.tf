output "kubectl-client-public-ip"{
  value = "${aws_instance.eks-kube-client.public_ip}"
}

output "kubectl-client-private-ip"{
  value = "${aws_instance.eks-kube-client.private_ip}"
}
