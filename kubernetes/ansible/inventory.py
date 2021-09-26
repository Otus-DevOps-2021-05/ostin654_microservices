#!/usr/bin/python3

import os
import sys
import json
import subprocess

if len(sys.argv) > 1 and sys.argv[1] == '--list':
    completed_process = subprocess.run(["terraform", "state", "pull"], capture_output=True, cwd="../terraform")
    terraform_state = json.loads(completed_process.stdout)
    ip_list = terraform_state["outputs"]["external_ip_address_kubernetes"]["value"]

    hosts = []
    host_vars = {}

    for i in range(len(ip_list)):
        ansible_host = "kubernetes-%d" % i
        hosts.append(ansible_host)
        host_vars[ansible_host] = {"ansible_host": ip_list[i]}

    inventory = {"kubernetes": {"hosts": hosts}, "_meta": {"hostvars": host_vars}}
    print(json.dumps(inventory))
