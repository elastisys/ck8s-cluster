#!/bin/bash

# all persistent data with be inside /home2 in the pods.

kubectl apply -f storge.yaml
kubectl apply -f pv-claim.yaml
kubectl apply -f local-test.yaml
