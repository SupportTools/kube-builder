#!/bin/bash

su - rootless -c "dockerd-rootless.sh --experimental --storage-driver vfs --host 0.0.0.0:2375 --host unix:///var/run/docker.sock"