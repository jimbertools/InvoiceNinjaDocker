#!/bin/bash
# Clean up all Docker resources for Invoice Ninja

read -p "Are you sure you want to remove all containers, volumes and images? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo "Stopping and removing containers..."
docker compose down -v

echo "Removing built image..."
docker rmi invoiceninja-with-nginx 2>/dev/null || true



echo "Done! You can now rebuild with: docker compose up -d --build"
