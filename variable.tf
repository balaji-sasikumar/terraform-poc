variable "resource_group_name" {
  description = "Name of the resource group in which the resources will be created"
  default     = "bt-rg"
}

variable "location" {
  default     = "centralindia"
  description = "Location where resources will be created"
}

variable "tags" {
  description = "Map of the tags to use for the resources that are deployed"
  type        = map(string)
  default = {
    environment = "dev"
  }
}

variable "application_port" {
  description = "Port that you want to expose to the external load balancer"
  default     = 80
}

variable "admin_user" {
  description = "User name to use as the admin account on the VMs that will be part of the VM scale set"
  default     = "balaji"
}

variable "admin_password" {
  description = "Default password for admin account"
  default     = "Balaji@12345"
  sensitive   = true
}

variable "vm_name" {
  description = "Name of the virtual machine"
  default     = "bt"
}

variable "vm_sku" {
  description = "SKU of the virtual machine"
  default     = "Standard_DS2_v2"
}

variable "blob_url_to_install" {
  description = "URL of the blob that contains the installation script"
  default     = "https://filexplorer.blob.core.windows.net/exe-file/file-explorer_1.0.0.exe"
}
