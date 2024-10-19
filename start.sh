#!/bin/bash

terraform apply --auto-approve
az aks get-credentials --resource-group sock-shop-rg --name sock-shop-aks
kubectl apply -f deployment.yaml
kubectl config set-context --current --namespace=sock-shop