#!/bin/bash

# all persistent data with be inside /home2 in the pods.

# Set up PersistentVolume
kubectl apply -f storage.yaml

# Set up PersistentVolumeClaim
kubectl apply -f pv-claim.yaml

# Example of deployment
kubectl apply -f local-test.yaml
