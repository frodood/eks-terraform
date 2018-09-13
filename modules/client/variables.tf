variable "eks-nodes-arn"{
  default = ""
}

variable "cluster-endpoint"{
  default = ""
}

variable "cluster-certificate_authority"{
  default = ""
}

variable "client_defaults"{
  type = "map"
  default ={
    name = ""
    ami_id      = ""
    public_ip            = ""
    key_name             = ""
    instance_type = ""
  }
}

variable "access-id"{
  default = ""
}

variable "access-key"{
  default = ""
}

variable "subnet-1a-public"{
  default = ""
}
variable "subnet-1b-public"{
  default = ""
}



variable "vpc-id"{
  default = ""
}

variable "cluster_defaults" {
  type        = "map"
  default = {
    name = ""
  }
}
