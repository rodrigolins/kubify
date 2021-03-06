# Copyright 2017 The Gardener Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


data "template_file" "cloud_conf" {
  template = "${file("${path.module}/templates/cloud.conf")}"

  vars {
    os_auth_url = "${module.os.auth_url}"
    os_username = "${module.os.user_name}"
    os_password = "${module.os.password}"
    os_tenant_name = "${module.os.tenant_name}"
    os_domain_name = "${module.os.domain_name}"
    fip_subnet_id = "${data.openstack_networking_network_v2.fip.id}"
    lb_subnet_id = "${openstack_networking_subnet_v2.cluster.id}"
    lb_provider = "${module.os.lbaas_provider}"
  }
}

resource "local_file" "cloud_conf" {
  content = "${data.template_file.cloud_conf.rendered}"
  filename = "${var.gen_dir}/iaas/cloud.conf"
}


output "cloud_conf" {
  value = "${data.template_file.cloud_conf.rendered}"
}

