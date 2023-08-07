terraform {
  required_providers {
    cloudstack = {
      source            = "cloudstack/cloudstack"
      version           = "0.4.0"
    }
  }
}

provider "cloudstack" {
  api_url = ""
  api_key = ""
  secret_key = ""  
}

resource "cloudstack_instance" "k8s-cluster" {
  name                = "k8s-cluster"
  zone                = "bc-xcp-zone-01"
  network_id          = "7debc8be-c86a-4eed-a206-e5292393b4d5"
  display_name        = "Atlassian Software"
  service_offering    = "L-Small Instance"
  template            = "9420cb9e-3dbe-4e26-bf67-2ca70c0036d7"
}
