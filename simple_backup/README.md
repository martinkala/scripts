# Ansible Backup System

A comprehensive backup solution using Ansible to copy files and directories from remote servers to local backup storage with automatic timestamp-based organization and retention management.

## Features

- **Automated Backup**: Copy files and directories from remote servers using Ansible
- **Timestamp-based Organization**: Automatic backup directory naming with format `YYYYMMDDHHMI`
- **Flexible Configuration**: Easy-to-modify backup sources and exclusions
- **Retention Management**: Automatic cleanup of old backups based on configurable retention policies
- **Command-line Interface**: Simple scripts for running backups and cleanup operations
- **Progress Tracking**: Detailed backup metadata and progress reporting
- **Archive Creation**: Automatic creation of compressed backup archives

## System Requirements

- **Ansible**: Version 2.9 or higher
- **Python**: Version 3.6 or higher
- **SSH Access**: To remote servers being backed up
- **rsync**: For efficient file synchronization
- **Linux/Unix**: Tested on Linux systems

## Installation

1. **Clone or download** the backup system files to your local machine
2. **Make scripts executable**:
   ```bash
   chmod +x run_backup.sh cleanup_backups.sh
   ```
3. **Verify Ansible installation**:
   ```bash
   ansible --version
   ```

## Configuration

### 1. Hosts Configuration (`hosts`)

The `hosts` file defines your source servers. Example:

```ini
[web]
web1 ansible_host=194.182.81.37 ansible_user=root

[backup]
backup1 ansible_host=192.168.1.20 ansible_user=deploy

[web:vars]
ansible_python_interpreter=/usr/bin/python3
nginx_config_dir=/etc/nginx
web_root=/opt
```

### 2. Backup Configuration (`backup_config.yml`)

Define what files and directories to backup:

```yaml
backup_sources:
  # System configuration files
  - /etc/nginx/nginx.conf
  - /etc/nginx/sites-available/
  - /etc/nginx/sites-enabled/
  
  # Web application files
  - /opt/
  - /var/www/
  
  # Custom directories
  - /home/deploy/apps/

exclude_patterns:
  - "*.tmp"
  - "*.log"
  - "node_modules/"
  - ".git/"

backup_retention:
  days: 30
  max_backups: 10
```

### 3. Ansible Configuration (`ansible.cfg`)

Basic Ansible settings:

```ini
[defaults]
inventory = hosts
host_key_checking = False
timeout = 30
gathering = smart
stdout_callback = yaml
```

## Usage

### Running Backups

#### Basic Backup (with timestamp directory)
```bash
./run_backup.sh
```
This creates a backup in `/home/martin/backup/202412011430/` (example timestamp)

#### Custom Destination Directory
```bash
./run_backup.sh -d /custom/backup/path
```

#### Specific Host Group
```bash
./run_backup.sh --host web
```

#### Verbose Output
```bash
./run_backup.sh --verbose
```

#### Custom Configuration File
```bash
./run_backup.sh -c custom_config.yml
```

### Backup Cleanup

#### Preview What Will Be Deleted
```bash
./cleanup_backups.sh --dry-run
```

#### Run Cleanup
```bash
./cleanup_backups.sh
```

#### Force Cleanup (no confirmation)
```bash
./cleanup_backups.sh -f
```

#### Custom Backup Directory
```bash
./cleanup_backups.sh -d /custom/backup
```

### Direct Ansible Usage

You can also run the backup playbook directly:

```bash
# Basic backup
ansible-playbook backup.yml

# Custom destination
ansible-playbook backup.yml -e backup_destination=/custom/path

# Specific host
ansible-playbook backup.yml --limit=web1

# Verbose output
ansible-playbook backup.yml -v
```

## Backup Structure

Each backup creates the following structure:

```
/home/martin/backup/202412011430/
├── nginx.conf
├── sites-available/
├── sites-enabled/
├── opt/
├── var/
├── home/
├── etc/
└── backup_metadata.txt

/home/martin/backup/202412011430.tar.gz  # Compressed archive
```

## File Descriptions

- **`backup.yml`**: Main Ansible playbook for backup operations
- **`backup_config.yml`**: Configuration file defining backup sources and settings
- **`run_backup.sh`**: User-friendly script for running backups
- **`cleanup_backups.sh`**: Script for managing backup retention and cleanup
- **`hosts`**: Ansible inventory file defining source servers
- **`ansible.cfg`**: Ansible configuration file

## Customization

### Adding New Backup Sources

Edit `backup_config.yml` and add new paths to the `backup_sources` list:

```yaml
backup_sources:
  - /etc/nginx/nginx.conf
  - /opt/
  - /var/www/
  - /home/user/documents/  # Add new source
  - /etc/mysql/            # Add new source
```

### Modifying Exclusions

Update the `exclude_patterns` section:

```yaml
exclude_patterns:
  - "*.tmp"
  - "*.log"
  - "*.cache"
  - "node_modules/"
  - ".git/"
  - "*.pyc"
  - "__pycache__/"
  - "*.sql"                # Add new exclusion
  - "temp/"                # Add new exclusion
```

### Changing Retention Settings

Modify the `backup_retention` section:

```yaml
backup_retention:
  days: 60        # Keep backups for 60 days
  max_backups: 20 # Maximum 20 backup directories
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify SSH keys are properly configured
   - Check `ansible_ssh_common_args` in hosts file
   - Ensure firewall allows SSH connections

2. **Permission Denied**
   - Verify user has read access to source directories
   - Check local backup directory permissions
   - Ensure sufficient disk space

3. **rsync Errors**
   - Verify rsync is installed on both local and remote systems
   - Check network connectivity and bandwidth

### Debug Mode

Run with verbose output to see detailed information:

```bash
./run_backup.sh --verbose
```

Or directly with Ansible:

```bash
ansible-playbook backup.yml -vvv
```

## Security Considerations

- **SSH Keys**: Use SSH key authentication instead of passwords
- **File Permissions**: Ensure backup directories have appropriate permissions
- **Network Security**: Use VPN or firewall rules to restrict access
- **Backup Encryption**: Consider encrypting sensitive backup data

## Automation

### Cron Job Example

Add to crontab for automated daily backups:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/backup/run_backup.sh

# Weekly cleanup on Sundays at 3 AM
0 3 * * 0 /path/to/backup/cleanup_backups.sh -f
```

### Systemd Timer Example

Create a systemd service and timer for more control:

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Ansible Backup Service
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/backup/run_backup.sh
User=martin
WorkingDirectory=/path/to/backup

# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily
Requires=backup.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

## Monitoring

### Backup Status

Check backup status and metadata:

```bash
# List recent backups
ls -la /home/martin/backup/

# View backup metadata
cat /home/martin/backup/202412011430/backup_metadata.txt

# Check backup sizes
du -sh /home/martin/backup/*
```

### Log Files

Monitor backup execution:

```bash
# View Ansible logs
tail -f /var/log/ansible.log

# Check system logs
journalctl -u backup.service -f
```

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review Ansible documentation
3. Check system logs for error details
4. Verify configuration files syntax

## License

This backup system is provided as-is for educational and operational purposes.
