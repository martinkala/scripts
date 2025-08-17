#!/bin/bash

# Example deployment script for static websites
# Usage: ./example-deploy.sh <site_name> [source_directory]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <site_name> [source_directory]"
    echo "Example: $0 mysite /path/to/source"
    exit 1
fi

SITE_NAME=$1
SOURCE_DIR=${2:-"./source"}

echo "Deploying website: $SITE_NAME"
echo "Source directory: $SOURCE_DIR"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Check if www and conf directories exist in source
if [ ! -d "$SOURCE_DIR/www" ] || [ ! -d "$SOURCE_DIR/conf/sites-available" ]; then
    echo "Error: Source directory must contain 'www' and 'conf/sites-available' subdirectories"
    echo "Expected structure:"
    echo "  $SOURCE_DIR/"
    echo "  ├── www/"
    echo "  └── conf/sites-available/"
    exit 1
fi

# Deploy the website
echo "Starting deployment..."
ansible-playbook deploy.yml \
    -e "site_name=$SITE_NAME" \
    -e "source_dir=$SOURCE_DIR" \
    --ask-become-pass

if [ $? -eq 0 ]; then
    echo "✅ Deployment completed successfully!"
    echo "Website '$SITE_NAME' is now deployed and accessible"
else
    echo "❌ Deployment failed. Check the output above for errors."
    exit 1
fi
