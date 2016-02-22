#!/bin/bash -e

TEMP_DIR='/tmp'
ANSIBLE_DIRECTORY=${TEMP_DIR}/$(ctx execution-id)/ansible
FILENAME=$(ctx source node properties playbook_file_name)
PLAYBOOK_PATH=${ANSIBLE_DIRECTORY}/${FILENAME}

NODE_HOSTNAME=$(ctx source node name)
NODE_ADDRESS=$(ctx source instance host_ip)

set -e
if ! ping -c 1 ${NODE_HOSTNAME} > /dev/null; then
    echo "${NODE_ADDRESS} ${NODE_HOSTNAME}" | sudo tee -a /etc/hosts
    ctx logger info "added hostname ${NODE_HOSTNAME}"
fi
set +e

cat <<EOF > ${ANSIBLE_DIRECTORY}/inventory
$NODE_HOSTNAME
EOF
ctx logger info "added ${NODE_HOSTNAME} to inventory"

PLAYBOOK=$(ctx download-resource-and-render resources/${FILENAME})
cp $PLAYBOOK $PLAYBOOK_PATH
set -e
if stat $PLAYBOOK; then
    ctx logger info "downloaded resource to ${PLAYBOOK_PATH}"
else ctx logger info "resource not downloaded."
fi
if stat $PLAYBOOK_PATH; then
    ctx logger info "copied to ${PLAYBOOK_PATH}"
else ctx logger info "resource not copied."
fi
set e
