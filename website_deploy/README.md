# Ansible Static Website Deployment

This Ansible setup provides automated deployment of static websites with nginx configuration management and backup capabilities.

## Structure

```
.
├── ansible.cfg          # Ansible configuration
├── hosts               # Inventory file with web and backup servers
├── deploy.yml          # Main deployment playbook
├── setup-infrastructure.yml  # Infrastructure setup playbook
├── backup.yml          # Backup playbook
├── roles/
│   ├── web/           # Web server role
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   └── backup/        # Backup server role
│       ├── tasks/main.yml
│       └── handlers/main.yml
└── README.md
```

## Prerequisites

- Ansible 2.9+
- SSH access to target servers
- Python 3 on target servers
- Sudo/root access on target servers

## Configuration

### 1. Update hosts file

Edit `hosts` file with your actual server IPs and SSH details:

```ini
[web]
web1 ansible_host=YOUR_WEB_SERVER_IP ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa
web2 ansible_host=YOUR_WEB_SERVER_IP2 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa

[backup]
backup1 ansible_host=YOUR_BACKUP_SERVER_IP ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### 2. Source directory structure

Your source directory should have this structure:

```
source/
├── www/                    # Website content
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── img/
└── conf/
    └── sites-available/    # Nginx configuration files
        └── site_name
```

## Usage

### Setup Infrastructure

First time setup of web and backup servers:

```bash
ansible-playbook setup-infrastructure.yml
```

### Deploy Website

Deploy a specific website:

```bash
ansible-playbook deploy.yml -e "site_name=mysite" -e "source_dir=/path/to/source"
```

Or with a custom source directory:

```bash
ansible-playbook deploy.yml -e "site_name=mysite" -e "source_dir=/home/user/website-source"
```

### Create Backup

Create a backup of website content and configurations:

```bash
ansible-playbook backup.yml -e "site_name=mysite"
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `site_name` | `default` | Name of the website (used for folder naming) |
| `source_dir` | `{{ playbook_dir }}/source` | Local directory containing source files |
| `nginx_config_dir` | `/etc/nginx` | Nginx configuration directory on target |
| `web_root` | `/www` | Web root directory on target |
| `backup_dir` | `/backups` | Backup directory on backup server |

## Features

- **Automated Deployment**: Deploys website content and nginx configurations
- **Infrastructure Management**: Sets up web and backup servers with security
- **Backup System**: Automated backups with rotation (keeps last 10)
- **Security**: Firewall configuration, fail2ban, and proper file permissions
- **Validation**: Nginx configuration testing before deployment
- **Rollback**: Automatic backup creation before deployment

## Security Features

- Firewall configuration (UFW)
- Fail2ban for intrusion prevention
- Proper file permissions and ownership
- SSH key-based authentication
- Non-root user deployment

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure SSH keys are properly configured
2. **Nginx Config Error**: Check nginx configuration syntax in source files
3. **Directory Not Found**: Verify source directory structure matches requirements

### Debug Mode

Run with verbose output for debugging:

```bash
ansible-playbook deploy.yml -e "site_name=mysite" -vvv
```

### Check Server Status

```bash
ansible web -m ping
ansible backup -m ping
```

## Example Nginx Configuration

Create `source/conf/sites-available/mysite`:

```nginx
server {
    listen 80;
    server_name mysite.com www.mysite.com;
    root /www/mysite;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Example
```
export ANSIBLE_SSH_ARGS="-o IdentitiesOnly=no"; ansible-playbook deploy.yml   -e "site_name_var=websitetest" -e source_dir=/home/martin/projects/website-test
```
## Support

For issues or questions, check the Ansible documentation or create an issue in this repository.
