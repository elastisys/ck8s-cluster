install_storage_class_provider() {
    case "${1}" in
    "nfs-client")
        echo "Install nfs-client-provisioner" >&2
        helmfile -f helmfile.yaml -e ${2} -l app=nfs-client-provisioner $INTERACTIVE apply --suppress-diff
    ;;
    "local-storage")
        echo "Creating local storage class for elasticsearch nodes" >&2
        kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch/local-storage-class.yaml

        echo "Install local-volume-provisioner" >&2
        helmfile -f helmfile.yaml -e ${2} -l app=local-volume-provisioner $INTERACTIVE apply --suppress-diff
    ;;
    "cinder-storage")
        storage=$(kubectl get storageclasses.storage.k8s.io -o json | jq '.items[].metadata | select(.name == "cinder-storage") | .name')
        if [ -z "$storage" ]
        then
            echo "Install cinder storage class" >&2
            kubectl apply -f ${SCRIPTS_PATH}/../manifests/cinder-storage.yaml
        fi
    ;;
    "ebs-gp2")
        storage=$(kubectl get storageclasses.storage.k8s.io -o json | jq '.items[].metadata | select(.name == "ebs-gp2") | .name')
        if [ -z "$storage" ]
        then
            echo "Install EBS GP2 storage class" >&2
            kubectl apply -f "${SCRIPTS_PATH}/../manifests/storageclass/aws/ebs-gp2.yaml"
        fi
    ;;
    esac
}
