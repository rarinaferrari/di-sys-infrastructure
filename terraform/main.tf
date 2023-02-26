terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = ""
  cloud_id  = ""
  folder_id = ""
  zone      = ""
}

#-------------------------------------------------------------------------------------------
resource "yandex_compute_instance" "web-1" {
  name        = "vm-web1"
  hostname    = "web-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89n8278rhueakslujo"
      size     = 13
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.inner-web-1.id
    security_group_ids = [yandex_vpc_security_group.inner.id]
    ip_address         = "10.0.1.3"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}

resource "yandex_compute_instance" "web-2" {
  name        = "vm-web-2"
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89n8278rhueakslujo"
      size     = 13
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.inner-web-2.id
    security_group_ids = [yandex_vpc_security_group.inner.id]
    ip_address         = "10.0.2.3"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8o8aph4t4pdisf1fio" #Nat
      size     = 13
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.inner.id, yandex_vpc_security_group.public-bastion.id]
    ip_address         = "10.0.10.5"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}

resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  hostname    = "prometheus"
  platform_id = "standard-v3"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89n8278rhueakslujo"
      size     = 13
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.inner-services.id
    security_group_ids = [yandex_vpc_security_group.inner.id]
    ip_address         = "10.0.3.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}

resource "yandex_compute_instance" "grafana" {
  name        = "grafana"
  hostname    = "grafana"
  platform_id = "standard-v3"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89n8278rhueakslujo"
      size     = 13
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.inner.id, yandex_vpc_security_group.public-grafana.id]
    ip_address         = "10.0.10.11"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}

resource "yandex_compute_instance" "elastic" {
  name        = "elastic"
  hostname    = "elastic"
  platform_id = "standard-v3"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89n8278rhueakslujo"
      size     = 13
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.inner-services.id
    security_group_ids = [yandex_vpc_security_group.inner.id]
    ip_address         = "10.0.3.12"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-c"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89n8278rhueakslujo"
      size     = 13
    }
  }


  network_interface {
    subnet_id          = yandex_vpc_subnet.public.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.inner.id, yandex_vpc_security_group.public-kibana.id]
    ip_address         = "10.0.10.13"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  scheduling_policy {
    preemptible = false
}
}
#---------------------------------------------------------------------------

resource "yandex_vpc_network" "mynet" {
  name = "mynet-network"
}

resource "yandex_vpc_route_table" "inner-to-nat" {
  network_id = yandex_vpc_network.mynet.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.bastion.network_interface.0.ip_address
  }
}

resource "yandex_vpc_subnet" "inner-web-1" {
  name           = "web-1-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.0.1.0/28"]
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}

resource "yandex_vpc_subnet" "inner-web-2" {
  name           = "web-2-subnet"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.0.2.0/28"]
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}

resource "yandex_vpc_subnet" "inner-services" {
  name           = "inner-services-subnet"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.0.3.0/27"]
  route_table_id = yandex_vpc_route_table.inner-to-nat.id
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.mynet.id
  v4_cidr_blocks = ["10.0.10.0/27"]
}

#-----------------------------------------------------------------------------------------

resource "yandex_alb_target_group" "web" {
  name = "web-target-group"

  target {
    ip_address = yandex_compute_instance.web-1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.inner-web-1.id
  }

  target {
    ip_address = yandex_compute_instance.web-2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.inner-web-2.id
  }
}

resource "yandex_alb_backend_group" "web" {
  name = "web-backend-group"

  http_backend {
    name             = "http-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]
    load_balancing_config {
      panic_threshold = 90
    }
    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web" {
  name = "web-http-router"
}

resource "yandex_alb_virtual_host" "root" {
  name           = "root-virtual-host"
  http_router_id = yandex_alb_http_router.web.id
  route {
    name = "root-path"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
        timeout          = "3s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  name               = "web-load-balancer"
  network_id         = yandex_vpc_network.mynet.id
  security_group_ids = [yandex_vpc_security_group.public-load-balancer.id, yandex_vpc_security_group.inner.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-c"
      subnet_id = yandex_vpc_subnet.inner-services.id
    }
  }

  listener {
    name = "listener1"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web.id
      }
    }
  }
}

resource "yandex_vpc_security_group" "inner" {
  name       = "inner-rules"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    protocol       = "ANY"
    description    = "allow any connection from inner subnets"
    v4_cidr_blocks = ["10.0.1.0/28", "10.0.2.0/28", "10.0.3.0/27", "10.0.10.0/27"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connections"
    v4_cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "yandex_vpc_security_group" "public-bastion" {
  name       = "public-bastion-rules"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    protocol       = "TCP"
    description    = "allow ssh connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "public-grafana" {
  name       = "public-grafana-rules"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    protocol       = "TCP"
    description    = "allow grafana connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "public-kibana" {
  name       = "public-kibana-rules"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    protocol       = "TCP"
    description    = "allow kibana connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "public-load-balancer" {
  name       = "public-load-balancer-rules"
  network_id = yandex_vpc_network.mynet.id

  ingress {
    protocol          = "ANY"
    description       = "Health checks"
    #port              = 80
    v4_cidr_blocks    = ["198.18.235.0/24", "198.18.248.0/24"]
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    description    = "allow HTTP connections from internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connection"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#---------------------------------------------------

output "external_ip_address_load_balancer" {
  value = yandex_alb_load_balancer.web.listener.0.endpoint.0.address.0.external_ipv4_address
}
output "external_ip_address_bastion-ssh" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

resource "local_file" "hosts" {
  content  = <<-EOT
    [bastion]
    ${yandex_compute_instance.bastion.network_interface.0.ip_address} public_ip=${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}

    [public-balancer]
    ${yandex_alb_load_balancer.web.listener.0.endpoint.0.address.0.external_ipv4_address.0.address}

    [web]
    ${yandex_compute_instance.web-1.network_interface.0.ip_address}
    ${yandex_compute_instance.web-2.network_interface.0.ip_address}

    [web1]
    ${yandex_compute_instance.web-1.network_interface.0.ip_address}

    [web2]
    ${yandex_compute_instance.web-2.network_interface.0.ip_address}

    [prometheus]
    ${yandex_compute_instance.prometheus.network_interface.0.ip_address}

    [grafana]
    ${yandex_compute_instance.grafana.network_interface.0.ip_address} public_ip=${yandex_compute_instance.grafana.network_interface.0.nat_ip_address}

    [elastic]
    ${yandex_compute_instance.elastic.network_interface.0.ip_address}

    [kibana]
    ${yandex_compute_instance.kibana.network_interface.0.ip_address} public_ip=${yandex_compute_instance.kibana.network_interface.0.nat_ip_address}

    [all:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -p 22 -W %h:%p -q thug@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
    EOT
  filename = "../ansible/hosts.ini"
}
