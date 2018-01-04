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


#
# to add an addon add an appropriate entry to local.defaultconfig and append the key to local.addons
#

# for some unknown reasons locals cannot be used here
variable "slash" {
  default = "\""
}

module "iaas-addons" {
  source = "../variable"
  value = "${length(var.addon_dirs) > 0 ? "${var.slash}${join("${var.slash} ${var.slash}", var.addon_dirs)}${var.slash}" : ""}"
}

locals {
  # this an explicit array to keep a distinct order for the multi-resource
  addons = [ "dashboard", "nginx-ingress", "fluentd-elasticsearch", "kube-lego", "heapster", "guestbook" ]

  defaultconfig = {
     "dashboard" = {
        basic_auth_b64 = "${module.dashboard_creds.b64}"
     }
     "nginx-ingress" = {
        version = "${module.versions.nginx_version}"
     }
     "fluentd-elasticsearch" = {}
     "heapster" = {}
     "kube-lego" = {
        version = "${module.versions.lego_version}"
     }
     "guestbook" = {}

     dummy = {
       basic_auth_b64 = ""
       email = ""
       version = ""
     }
  }

  selected = "${keys(var.addons)}"
  config = "${merge(local.defaultconfig,  var.addons)}"
  standard = {
    cluster_name = "${var.cluster_name}"
    ingress = "${var.ingress_base_domain}"
  }
}

#
# the templates are always processed for all possible extensions, always in the same
# order, this allows to use a counted resource, even if then actual set of addons
# changes without potentials recreation because of the index change of an addon.
#
# the dummy config defines null values for all template vars for all addons
# It is used ONLY if the addon is inactive, this prevents errors comming from the template.
# If the addon is used only the defaults are merged, this will cause errors if
# a mandatory configuration variable for an extension is missing
#

resource "template_dir" "addons" {
  count = "${length(local.addons)}"

  source_dir = "${path.module}/templates/addons/${local.addons[count.index]}"
  destination_dir = "${var.gen_dir}/addons/${local.addons[count.index]}"

  vars = "${merge(local.standard,local.defaultconfig[local.addons[count.index]],local.config[contains(local.selected, local.addons[count.index]) ? local.addons[count.index] : "dummy"])}"
}
