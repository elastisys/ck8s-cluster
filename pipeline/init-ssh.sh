#!/bin/bash
export SSH_PATH=$(pwd)/id_rsa
export TF_VAR_ssh_pub_key_file_sc=${SSH_PATH}_sc.pub
export TF_VAR_ssh_pub_key_file_wc=${SSH_PATH}_wc.pub

echo "Taking ssh-keys from secrets and adding them to ssh-add"
eval `ssh-agent`
echo "${SSH_KEY_SC}" > ${SSH_PATH}_sc
chmod 600 ${SSH_PATH}_sc
ssh-keygen -y -f ${SSH_PATH}_sc -N '' > ${SSH_PATH}_sc.pub
echo "${SSH_KEY_WC}" > ${SSH_PATH}_wc
chmod 600 ${SSH_PATH}_wc
ssh-keygen -y -f ${SSH_PATH}_wc -N '' > ${SSH_PATH}_wc.pub
ssh-add ${SSH_PATH}_sc
ssh-add ${SSH_PATH}_wc
echo "success"