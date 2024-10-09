#!/usr/bin/env bash

set -x

curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-org1-default.json
curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-org1-kube-system.json
curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-org1-prom-stack.json
