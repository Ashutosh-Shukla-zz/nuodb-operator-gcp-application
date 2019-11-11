#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eo pipefail

export NUODB_APP_NAME="nuodb"
export NAMESPACE="nuodb"
cat nuodb.yaml.template | envsubst > nuodb.yaml

cat nuodb.yaml

kubectl apply -f nuodb.yaml

while true; do
  #Check sts rollout status every 10 seconds (max 10 minutes) until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status sts/admin -n $NAMESPACE"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    kubectl get pods -n $NAMESPACE
    sleep 10
  done

  echo "Retrieving status"
  status=$(kubectl get $NUODB_APP_NAME -o=json | \
    jq ".items[0].status.domainHealth")
  
  echo $status

  echo "Checking status for green status"
  completed_status=$(echo $status | grep "Green" || true)
  if [[ -n "$completed_status" ]]; then
    echo "Delete nuodb $NUODB_APP_NAME"
    kubectl delete nuodb "$NUODB_APP_NAME"
    exit 0
  fi

  echo "Checking status for Red status"
  failed_status=$(echo $status | grep "Red" || true)
  if [[ -n "$failed_status" ]]; then
    echo "Delete nuodb $NUODB_APP_NAME"
    kubectl delete nuodb "$NUODB_APP_NAME"
    exit 1
  fi

  echo "Waiting 4 seconds before retry"
  sleep 4
done
