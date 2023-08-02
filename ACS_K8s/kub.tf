terraform {
  required_providers {
    cloudstack = {
      source            = "cloudstack/cloudstack"
      version           = "0.4.0"
    }
  }
}

provider "cloudstack" {
  api_url = "http://10.69.104.60:8080/client/api"
  api_key = "vM-_I73vGvXu9g6eBbXJ3V48dySyGBLSrTyZhWBg5e7ztbg7A1YB938dq5-fVjialM--Cqu6zE_-A8seLwYx5w"
  secret_key = "ir6GFaqspjQb4HaoJO7GFcc3csYe8UJXbGBkxEqhshwI6h14w5xXI22zDRvy2nCYNsj-sarvIWJAHG7VUeoIVw"  
}

resource "cloudstack_instance" "k8s-cluster" {
  name                = "k8s-cluster"
  zone                = "bc-xcp-zone-01"
  network_id          = "7debc8be-c86a-4eed-a206-e5292393b4d5"
  display_name        = "Atlassian Software"
  service_offering    = "L-Small Instance"
  template            = "9420cb9e-3dbe-4e26-bf67-2ca70c0036d7"
}