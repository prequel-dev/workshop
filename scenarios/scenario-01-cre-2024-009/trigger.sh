#!/bin/bash

JOB_MANIFEST="trace_generator/k8s/deploy.yaml"
JOB_NAME="traces-generator-job"
CHECK_INTERVAL=5

#set -x

kubectl -n monitoring delete job $JOB_NAME

echo "Deploying the problem trigger job..."
kubectl -n monitoring apply -f $JOB_MANIFEST

echo "Waiting for the Job '$JOB_NAME' to complete..."
while true; do
    COMPLETION_TIME=$(kubectl -n monitoring get job $JOB_NAME -o jsonpath='{.status.completionTime}')
    if [ -n "$COMPLETION_TIME" ]; then
        echo "Job '$JOB_NAME' completed at $COMPLETION_TIME."
        break
    else
        echo "Job '$JOB_NAME' is still running. Checking again in $CHECK_INTERVAL seconds..."
        sleep $CHECK_INTERVAL
    fi
done

kubectl -n monitoring delete job $JOB_NAME

echo "Trigger completed"
