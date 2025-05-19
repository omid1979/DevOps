from flask import Flask, render_template, request, redirect, url_for, flash
import socket
import paramiko
import subprocess
import os
from paramiko.ssh_exception import SSHException

app = Flask(__name__)
app.secret_key = 'secret_key'  # Secret key for session management and flash messages

# Configuration constants
IP_LIST_FILE = 'ips.txt'  # File containing list of IP addresses
GIT_REPO_URL = 'git@github.com:omid1979/config.git'  # Git repository URL (SSH)
LOCAL_CONFIG_DIR = 'config_repo'  # Local directory to clone the git repo

# Dictionary mapping local config filenames to their remote destination paths
CONFIG_FILES = {
    'sshd_config': '/etc/ssh/sshd_config',
    'custom_config.conf': '/etc/custom/custom_config.conf',
    # Add more config files and paths here as needed
}

SSH_USERNAME = 'root'  # SSH username to connect with
PRIVATE_KEY_PATH = '/home/omid/.ssh/id_ed25519'  # Path to the SSH private key file


def read_ips(file_path):
    """
    Read IP addresses from a file, one per line.
    Empty lines are ignored.
    """
    with open(file_path, 'r') as f:
        return [line.strip() for line in f if line.strip()]


def check_ssh(ip, port=22, timeout=3):
    """
    Check if SSH port is open on the given IP address.
    Returns True if connection succeeded, False otherwise.
    """
    try:
        with socket.create_connection((ip, port), timeout=timeout):
            return True
    except Exception:
        return False


def update_git_repo():
    """
    Clone the git repository if not already cloned.
    Otherwise, pull the latest changes.
    Returns True on success, False on failure.
    """
    if not os.path.exists(LOCAL_CONFIG_DIR):
        result = subprocess.run(['git', 'clone', GIT_REPO_URL, LOCAL_CONFIG_DIR])
        return result.returncode == 0
    else:
        result = subprocess.run(['git', '-C', LOCAL_CONFIG_DIR, 'pull'])
        return result.returncode == 0


def copy_config(ip):
    """
    Connect to the server via SSH using private key authentication,
    and copy all config files from the local git repo to their respective remote paths.
    Returns a tuple (success: bool, message: str).
    """
    try:
        # Load private key for authentication
        key = paramiko.RSAKey.from_private_key_file(PRIVATE_KEY_PATH)

        # Initialize SSH client and set policy to add unknown hosts automatically
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        # Connect to the server
        ssh.connect(ip, username=SSH_USERNAME, pkey=key, timeout=10)

        # Open SFTP session for file transfer
        sftp = ssh.open_sftp()

        # Iterate over all config files and transfer each
        for local_filename, remote_path in CONFIG_FILES.items():
            local_path = os.path.join(LOCAL_CONFIG_DIR, local_filename)

            # Check if the local config file exists
            if not os.path.exists(local_path):
                return False, f'Local file "{local_filename}" not found.'

            try:
                # Upload the file to the remote server
                sftp.put(local_path, remote_path)
            except Exception as e:
                return False, f'Error copying "{local_filename}" to "{remote_path}": {str(e)}'

        # Close SFTP and SSH connections
        sftp.close()
        ssh.close()

        return True, 'All config files transferred successfully.'

    except SSHException as e:
        return False, f'SSH error: {str(e)}'
    except Exception as e:
        return False, f'Unknown error: {str(e)}'


@app.route('/', methods=['GET', 'POST'])
def index():
    # Read IPs and check SSH status for each
    ips = read_ips(IP_LIST_FILE)
    status = {ip: check_ssh(ip) for ip in ips}

    if request.method == 'POST':
        # Update or clone the git repository first
        if not update_git_repo():
            flash('Error updating git repository.', 'error')
            return redirect(url_for('index'))

        selected_ip = request.form.get('selected_ip')
        if not selected_ip:
            flash('Please select an IP address.', 'error')
            return redirect(url_for('index'))

        # Copy config files to the selected server
        success, message = copy_config(selected_ip)
        flash(message, 'success' if success else 'error')
        return redirect(url_for('index'))

    return render_template('index.html', ips=ips, status=status)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

