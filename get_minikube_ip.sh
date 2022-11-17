#!/bin/bash
MINIKUBE_IP=`minikube ip -p agones`
echo -n "{ \"address\" : \"${MINIKUBE_IP}\"}"