#!/bin/bash
set -e

install_pwsh() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)
            if command -v apt-get &> /dev/null; then
                echo "Attempting to install via apt-get..."
                sudo apt-get update
                sudo apt-get install -y wget apt-transport-https software-properties-common
                wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
                sudo dpkg -i packages-microsoft-prod.deb
                sudo apt-get update
                sudo apt-get install -y powershell
            elif command -v yum &> /dev/null; then
                echo "Attempting to install via yum..."
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo sh -c 'echo -e "[powershell]\nname=PowerShell\nbaseurl=https://packages.microsoft.com/yumrepos/microsoft-rhel7.3-prod\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/microsoft.repo'
                sudo yum install -y powershell
            else
                echo "Unsupported Linux distro ${unameOut}"
                exit 1
            fi
            ;;
        Darwin*)
            echo "Attempting to install via brew..."
            if command -v brew &> /dev/null; then
                brew install --cask powershell
            else
                echo "Homebrew is not installed. Install it first: https://brew.sh"
                exit 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "Attempting to install via winget..."
            if command -v winget &> /dev/null; then
                winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements
            else
                echo "winget not found. Please install PowerShell manually: https://aka.ms/powershell"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS ${unameOut}"
            echo "Please install PowerShell manually."
            exit 1
            ;;
    esac
}

# Ensure pwsh is installed
if ! command -v pwsh &> /dev/null; then
    echo "PowerShell (pwsh) not found. Attempting to install..."
    install_pwsh
fi
