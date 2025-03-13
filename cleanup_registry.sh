#!/bin/bash
REGISTRY=$1
IMAGE_NAME=$2
DOCKER_USERNAME=$3
DOCKER_TOKEN=$4

echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USERNAME" --password-stdin ${REGISTRY} > /dev/null 2>&1

tags=$(curl -s "https://${REGISTRY}/v2/${IMAGE_NAME}/tags/list")

current_time=$(date +%s)
delete_tags=()

for tag in $(echo "$tags" | jq -r '.tags[]'); do
  tag_details=$(curl -s "https://${REGISTRY}/v2/${IMAGE_NAME}/manifests/${tag}")
  created_time=$(echo "$tag_details" | jq -r '.history[0].v1Compatibility.created' | sed 's/T/ /g' | sed 's/Z//g' | xargs -I {} date -d "{}" +%s)
  age_in_days=$(( (current_time - created_time) / (60*60*24) ))

  if [[ $age_in_days -gt 7 ]]; then
    delete_tags+=("$tag")
  fi
done

for tag in "${delete_tags[@]}"; do
  curl -X DELETE "https://${REGISTRY}/v2/${IMAGE_NAME}/manifests/${tag}"
  docker rmi "${REGISTRY}/${IMAGE_NAME}:${tag}" || true
done
