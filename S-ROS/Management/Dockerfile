# Use a lightweight base image
FROM python:3.9-slim

# Install necessary packages
RUN apt-get update && apt-get install -y \
    git \
    rsync \
    openssh-client \
    && apt-get clean

# Install Ansible
RUN pip install ansible

# Set working directory
WORKDIR /ansible-playbooks

# Keep container running
CMD ["tail", "-f", "/dev/null"]

