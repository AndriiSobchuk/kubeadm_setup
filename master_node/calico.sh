#!/bin/bash
# Check if calico is installed and install if it is not
if ! calicoctl version >/dev/null 2>&1; then
    echo "Calico is not installed"
    echo "Installing calico..."
    wget -O /tmp/calicoctl https://github.com/projectcalico/calicoctl/releases/download/v3.9.0/calicoctl-linux-amd64
    chmod +x /tmp/calicoctl
    sudo cp /tmp/calicoctl /usr/local/bin/calicoctl
    rm /tmp/calicoctl
    sudo calicoctl version
fi
