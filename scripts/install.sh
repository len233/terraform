#!/bin/bash

# Installation script for Terraform Cloud Project
# This script sets up the environment and installs dependencies

set -e

echo "=========================================="
echo "Terraform Cloud Project - Installation"
echo "=========================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

echo "✓ Python 3 is installed"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Warning: Terraform is not installed"
    echo "Please install Terraform from https://www.terraform.io/downloads"
else
    echo "✓ Terraform is installed"
    terraform version
fi

# Install Python dependencies
echo ""
echo "Installing Python dependencies..."
cd backend
python3 -m pip install -r requirements.txt
cd ..

echo ""
echo "✓ Python dependencies installed"

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
cd terraform
terraform init

echo ""
echo "=========================================="
echo "Installation completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure your Azure credentials"
echo "2. Update terraform/terraform.tfvars with your values"
echo "3. Run 'terraform plan' to preview changes"
echo "4. Run 'terraform apply' to create resources"
echo "5. Start the backend with 'python3 backend/app.py'"
