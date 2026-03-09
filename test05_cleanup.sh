#!/bin/bash
# remove_images.sh
set -e
read -ra images <<< "$Images"
for image in "${images[@]}"; do
  docker image rm "$image" -f || echo "❌ Failed to remove: $image"
done
