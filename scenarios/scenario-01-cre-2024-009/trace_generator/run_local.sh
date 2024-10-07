#!/usr/bin/env bash

echo "Starting port-forward proxy"

kubectl -n monitoring port-forward svc/otel-collector-opentelemetry-collector 14268:14268 &
PID=$!

echo "Generating traces"
for i in {1..5}
do
  time ./generator
done

echo "Done"
kill $PID
