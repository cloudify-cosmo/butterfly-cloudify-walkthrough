#!/bin/bash

TEMP_DIR='/tmp'
ANSIBLE_DIRECTORY=${TEMP_DIR}/$(ctx execution-id)/ansible
FILENAME=$(ctx source node properties playbook_file_name)
PLAYBOOK_PATH=${ANSIBLE_DIRECTORY}/${FILENAME}
export ANSIBLE_CONFIG=$(ctx target instance runtime-properties confpath)
ansible-playbook ${PLAYBOOK_PATH} --sudo --connection=paramiko -vvvv > ${ANSIBLE_DIRECTORY}/output.log 2>&1
ctx logger info "executed ${PLAYBOOK_PATH}"
