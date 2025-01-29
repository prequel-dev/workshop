#!/usr/bin/env bash

set -x

NUM_USERS=$1
BASTION=$2

function tarball() {
  local TARBALL=$1
  DATE=$(date --rfc-3339=date)

  pushd ../../
  tar -czvf /tmp/workshop-$DATE.tgz \
    --exclude='terraform.tfstate' \
    --exclude='exceptions' \
    --exclude='.terraform' \
    --exclude='celery' \
    --exclude='.terraform.lock.hcl' \
    --exclude='.git' \
    --exclude='.gitignore' \
    --exclude='setup.sh' \
    ./workshop
    popd
}

function doinstall() {
  local USER_NUM=$1
  local OUT=$2

  USER="student$USER_NUM"
  scp $OUT $USER@$BASTION:workshop.tgz
  ssh $USER@$BASTION "tar -zxvf workshop.tgz"
  ssh -t $USER@$BASTION "bash -ic 'helm repo add strimzi https://strimzi.io/charts'"
  ssh -t $USER@$BASTION "bash -ic 'helm install my-kafka strimzi/strimzi-kafka-operator --namespace strimzi --create-namespace --version 0.32.0'"
  ssh -t $USER@$BASTION "bash -ic 'kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml'"
  ssh -t $USER@$BASTION "bash -ic 'cd workshop/scenarios/scenario-01-cre-2024-009/collector && ./install.sh'"
  ssh -t $USER@$BASTION "bash -ic 'cd workshop/scenarios/scenario-02-cre-2024-006 && kubectl -n strimzi apply -f ./kafka-metrics-mitigation.yaml'"
  ssh -t $USER@$BASTION "bash -ic 'cd workshop/scenarios/scenario-03-cre-2024-007 && ./install.sh'"
  ssh -t $USER@$BASTION "bash -ic 'cd workshop/setup/monitors && ./install.sh'"
}

function install() {
  local OUT=$1

  counter=1

  while [ $counter -le $NUM_USERS ]; do
    doinstall $counter $OUT
    ((counter++))
  done
}

function main() {
  DATE=$(date --rfc-3339=date)
  OUT=/tmp/workshop-$DATE.tgz
  tarball $OUT
  install $OUT
}

main
