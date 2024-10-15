#!/usr/bin/env bash

set -x

ORG=$1

curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-$ORG-default.json
curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-$ORG-kube-system.json
curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-$ORG-prequel.json
curl -XPOST -H "Authorization: Bearer $TOKEN" "https://api-beta.prequel.dev:8080/v1/api/exceptions" -d @exceptions-$ORG-prom-stack.json
