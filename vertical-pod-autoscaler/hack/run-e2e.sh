#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_ROOT=$(dirname ${BASH_SOURCE})/..

function print_help {
  echo "ERROR! Usage: run-e2e.sh <suite>"
  echo "<suite> should be one of:"
  echo " - recommender"
  echo " - updater"
  echo " - admission-controller"
  echo " - full-vpa"
}

if [ $# -eq 0 ]; then
  print_help
  exit 1
fi

if [ $# -gt 1 ]; then
  print_help
  exit 1
fi

SUITE=$1

case ${SUITE} in
  recommender|updater|admission-controller|full-vpa)
    ${SCRIPT_ROOT}/hack/vpa-down.sh
    ${SCRIPT_ROOT}/hack/deploy-for-e2e.sh ${SUITE}

    # VPA creation and listing for debugging test-infra. DELETE AFTER DEBUG
    kubectl create -f ${SCRIPT_ROOT}/examples/hamster.yaml
    kubectl describe vpa
    kubectl delete -f ${SCRIPT_ROOT}/examples/hamster.yaml

    go test ${SCRIPT_ROOT}/e2e/*go -v  --args --ginkgo.v=true --ginkgo.focus="\[VPA\] \[${SUITE}\]"
    ;;
  *)
    print_help
    exit 1
    ;;
esac

