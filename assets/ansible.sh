[root@master01 ~]# cat /usr/share/ansible/openshift-ansible/roles/openshift_node/templates/openshift.docker.node.dep.service
[Unit]
Requires={{ openshift.docker.service_name }}.service
After={{ openshift.docker.service_name }}.service
PartOf={{ openshift.common.service_type }}-node.service
Before={{ openshift.common.service_type }}-node.service
{% if openshift_use_crio|default(false) %}Wants=cri-o.service{% endif %}

[Service]
ExecStart=/bin/bash -c 'if [[ -f /usr/bin/docker-current ]]; \
 then echo DOCKER_ADDTL_BIND_MOUNTS=\"--volume=/usr/bin/docker-current:/usr/bin/docker-current:ro \
 --volume=/etc/sysconfig/docker:/etc/sysconfig/docker:ro \
 --volume=/etc/containers/registries:/etc/containers/registries:ro \
 {% if l_bind_docker_reg_auth %} --volume={{ oreg_auth_credentials_path }}:/root/.docker:ro{% endif %}\" > \
 /etc/sysconfig/{{ openshift.common.service_type }}-node-dep; \
 else echo "#DOCKER_ADDTL_BIND_MOUNTS=" > /etc/sysconfig/{{ openshift.common.service_type }}-node-dep; fi'
ExecStop=
SyslogIdentifier={{ openshift.common.service_type }}-node-dep