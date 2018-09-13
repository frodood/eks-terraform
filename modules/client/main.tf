resource "aws_security_group" "web" {
  name = "web-sg"
  vpc_id = "${var.vpc-id}"

  egress {
       from_port = 0
       to_port = 0
       protocol = "-1"
       cidr_blocks = ["0.0.0.0/0"]
     }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 27017
    to_port   = 27017
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "kube-client-sg"
  }
}


locals {
  config-map-aws-auth-client = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${var.eks-nodes-arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig-client = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${var.cluster-endpoint}
    certificate-authority-data: ${var.cluster-certificate_authority}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - ${var.cluster_defaults["name"]}
KUBECONFIG
}

locals{
  ansible-config = <<ANSIBLEDATA

[defaults]

# some basic default values...

inventory      = /etc/ansible/hosts
library        = /usr/share/my_modules/
remote_tmp     = $HOME/.ansible/tmp
local_tmp      = $HOME/.ansible/tmp
forks          = 5
poll_interval  = 15
sudo_user      = root
#ask_sudo_pass = True
#ask_pass      = True
#transport      = smart
remote_port    = 22
#module_lang    = C
#module_set_locale = True

# uncomment this to disable SSH key host checking
host_key_checking = False

# if True, make ansible use scp if the connection type is ssh
# (default is sftp)
scp_if_ssh = True

[selinux]
# file systems that require special treatment when dealing with security context
# the default behaviour that copies the existing context or uses the user default
# needs to be changed to use the file system dependent context.
#special_context_filesystems=nfs,vboxsf,fuse,ramfs

# Set this to yes to allow libvirt_lxc connections to work without SELinux.
libvirt_lxc_noseclabel = yes

ANSIBLEDATA


ansible-host = <<ANSIBLEHOST

[jenkins]
127.0.0.1 ansible_connection=local
ANSIBLEHOST
}

locals {
  eks-client-userdata = <<USERDATA
#!/bin/bash -xe

echo "${local.config-map-aws-auth-client}" > /tmp/aws-auth-cm.yaml
echo "${local.kubeconfig-client}" > /tmp/kubeconfig
echo "Done COPY _+++++++++++++++++++++++"
export AWS_ACCESS_KEY_ID="${var.access-id}"
export AWS_SECRET_ACCESS_KEY="${var.access-key}"

kubectl --kubeconfig /tmp/kubeconfig apply -f /tmp/aws-auth-cm.yaml
git clone https://github.com/frodood/node-todo.git

sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update
sudo apt-get install ansible -y

echo "${local.ansible-config}" > /etc/ansible/ansible.cfg
echo "${local.ansible-host}" > /etc/ansible/hosts

USERDATA
}



resource "aws_instance" "eks-kube-client" {
  ami           = "${var.client_defaults["ami_id"]}"
  instance_type = "${var.client_defaults["instance_type"]}"
  key_name      = "${var.client_defaults["key_name"]}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${var.subnet-1a-public}"
  user_data_base64            = "${base64encode(local.eks-client-userdata)}"
  associate_public_ip_address = "${var.client_defaults["public_ip"]}"


  tags {
    Name = "utility-server"
  }
}
