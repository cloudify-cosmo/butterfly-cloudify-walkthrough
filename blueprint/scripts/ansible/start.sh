#!/bin/bash -e 

ctx logger info 'Installing Ansible...'

# Make sure that ansible exists in the virtualenv
set -e
if ! type ansible > /dev/null; then
    pip install ansible
    ctx logger info 'Installed Ansible'
fi
set +e

ctx logger info 'Installing Repex...'

set -e
if ! type repex > /dev/null; then
    pip install repex
    ctx logger info 'Installed Repex'
fi
set +e


# there is a way in bash to get the tmp directory via command. use it instead.
TEMP_DIR='tmp'
ANSIBLE_DIRECTORY=${TEMP_DIR}/$(ctx execution-id)/ansible
# replace FILENAME with 'PLAYBOOK_FILENAME'
FILENAME=main.yaml
PLAYBOOK_PATH=${ANSIBLE_DIRECTORY}/${FILENAME}

mkdir -p ${ANSIBLE_DIRECTORY}/roles

# Download and Move the Default Ansible Config in place
TEMP_CONF_PATH=$(ctx download-resource-and-render resources/ansible.cfg)
TEMP_VAR_PATH=$(ctx download-resource-and-render resources/default.yml)

ctx logger info "Downloaded ansible.cfg to ${TEMP_CONF_PATH}"
ctx logger info "Playbook: ${FILENAME}"
CONF_PATH=$ANSIBLE_DIRECTORY/ansible.cfg
VAR_PATH=$ANSIBLE_DIRECTORY/default.yml
INVENTORY_PATH=$ANSIBLE_DIRECTORY/inventory
cp $TEMP_CONF_PATH $CONF_PATH
cp $TEMP_VAR_PATH $VAR_PATH
ctx logger info "Copied ${TEMP_CONF_PATH} ${CONF_PATH}"
export ANSIBLE_CONFIG=${CONF_PATH}
ctx instance runtime-properties confpath ${CONF_PATH}

# Add the ansible hostname name to the inventory and to etc hosts
#INVENTORY_FILE=$(ctx download-resource-and-render resources/inventory { "application_host_public_ip": "$application_host_public_ip" })
INVENTORY_FILE=$(ctx download-resource-and-render resources/inventory)
cp $INVENTORY_FILE $INVENTORY_PATH
rpx repl -p $INVENTORY_PATH -r HOST -w $application_host_public_ip

# Download the playbook that will download the roles for the other modules
PLAYBOOK=$(ctx download-resource-and-render resources/main.yaml)
cp $PLAYBOOK $PLAYBOOK_PATH
ctx logger info "Downloaded resource to ${PLAYBOOK_PATH}"

# Manipulate playbook to prepare for Ansible run
rpx repl -p $PLAYBOOK_PATH -r PLACE0 -w "{{ ansible_ssh_host }}"
rpx repl -p $PLAYBOOK_PATH -r 'echo "PLACE1"' -w 'echo "{{ sys_update }}"'
rpx repl -p $PLAYBOOK_PATH -r 'echo "PLACE2"' -w 'echo "{{ deploy }}"'
rpx repl -p $PLAYBOOK_PATH -r PLACE3 -w "{{ item }}"
rpx repl -p $PLAYBOOK_PATH -r PLACE4 -w {{butterfly_PID.stdout}}
rpx repl -p $PLAYBOOK_PATH -r PLACE5 -w {{ext_ip.stdout}}

# Run playbook after manipulation
sleep 1m
ansible-playbook ${PLAYBOOK_PATH} > ${ANSIBLE_DIRECTORY}/output.log 2>&1
ctx logger info "Executed ${PLAYBOOK_PATH}"