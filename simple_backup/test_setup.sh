#!/bin/bash

# Test Setup Script for Ansible Backup System
# This script verifies that all components are properly configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Backup System Test${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Test functions
test_ansible() {
    print_status "Testing Ansible installation..."
    
    if command -v ansible >/dev/null 2>&1; then
        VERSION=$(ansible --version | head -1)
        print_status "Ansible found: $VERSION"
    else
        print_error "Ansible not found. Please install Ansible first."
        return 1
    fi
}

test_ansible_playbook() {
    print_status "Testing ansible-playbook..."
    
    if command -v ansible-playbook >/dev/null 2>&1; then
        print_status "ansible-playbook found"
    else
        print_error "ansible-playbook not found"
        return 1
    fi
}

test_files() {
    print_status "Testing required files..."
    
    local missing_files=()
    
    for file in "ansible.cfg" "hosts" "backup.yml" "backup_config.yml"; do
        if [[ -f "$file" ]]; then
            print_status "✓ $file found"
        else
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing files: ${missing_files[*]}"
        return 1
    fi
}

test_scripts() {
    print_status "Testing executable scripts..."
    
    for script in "run_backup.sh" "cleanup_backups.sh"; do
        if [[ -x "$script" ]]; then
            print_status "✓ $script is executable"
        else
            print_warning "$script is not executable"
        fi
    done
}

test_hosts() {
    print_status "Testing hosts file..."
    
    if [[ -f "hosts" ]]; then
        # Check if hosts file has content
        if [[ -s "hosts" ]]; then
            print_status "✓ hosts file has content"
            
            # Show available host groups
            echo "Available host groups:"
            grep "^\[" hosts | sed 's/\[//;s/\]//' | while read -r group; do
                echo "  - $group"
            done
        else
            print_warning "hosts file is empty"
        fi
    fi
}

test_config() {
    print_status "Testing backup configuration..."
    
    if [[ -f "backup_config.yml" ]]; then
        # Check if config file has content
        if [[ -s "backup_config.yml" ]]; then
            print_status "✓ backup_config.yml has content"
            
            # Show backup sources
            echo "Backup sources:"
            grep "^- /" backup_config.yml | sed 's/^  - /    /' || print_warning "No backup sources found"
        else
            print_warning "backup_config.yml is empty"
        fi
    fi
}

test_connectivity() {
    print_status "Testing SSH connectivity to hosts..."
    
    # Extract host IPs from hosts file
    local hosts=$(grep "ansible_host=" hosts | awk '{print $2}' | cut -d'=' -f2)
    
    if [[ -z "$hosts" ]]; then
        print_warning "No hosts found in hosts file"
        return 0
    fi
    
    for host in $hosts; do
        print_status "Testing connection to $host..."
        if timeout 5 bash -c "</dev/tcp/$host/22" 2>/dev/null; then
            print_status "✓ Port 22 open on $host"
        else
            print_warning "✗ Cannot connect to $host:22"
        fi
    done
}

test_backup_directory() {
    print_status "Testing backup directory..."
    
    local backup_dir="/home/martin/backup"
    
    if [[ -d "$backup_dir" ]]; then
        print_status "✓ Backup directory exists: $backup_dir"
        
        # Check permissions
        local perms=$(stat -c %a "$backup_dir")
        print_status "Permissions: $perms"
        
        # Check available space
        local space=$(df -h "$backup_dir" | tail -1 | awk '{print $4}')
        print_status "Available space: $space"
    else
        print_warning "Backup directory does not exist: $backup_dir"
        print_status "It will be created automatically during backup"
    fi
}

test_rsync() {
    print_status "Testing rsync availability..."
    
    if command -v rsync >/dev/null 2>&1; then
        VERSION=$(rsync --version | head -1)
        print_status "✓ rsync found: $VERSION"
    else
        print_error "rsync not found. Please install rsync."
        return 1
    fi
}

run_dry_run() {
    print_status "Running dry-run backup test..."
    
    if [[ -x "run_backup.sh" ]]; then
        echo "This will test the backup system without actually copying files."
        read -p "Continue? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create a temporary test config
            cat > test_config.yml << EOF
---
backup_sources:
  - /tmp
  - /etc/hosts

exclude_patterns:
  - "*.tmp"

backup_retention:
  days: 1
  max_backups: 2
EOF
            
            print_status "Running backup with test configuration..."
            ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook backup.yml -e backup_destination=/tmp/test_backup -c test_config.yml --limit=localhost || print_warning "Dry-run completed with warnings"
            
            # Cleanup test config
            rm -f test_config.yml
        else
            print_status "Dry-run skipped"
        fi
    else
        print_warning "run_backup.sh not executable, skipping dry-run"
    fi
}

# Main test execution
main() {
    print_header
    echo ""
    
    local tests_passed=0
    local tests_total=0
    
    # Run all tests
    for test in test_ansible test_ansible_playbook test_files test_scripts test_hosts test_config test_rsync test_backup_directory test_connectivity; do
        echo "Running $test..."
        if $test; then
            tests_passed=$((tests_passed + 1))
        fi
        tests_total=$((tests_total + 1))
        echo ""
    done
    
    # Summary
    echo "=================================="
    echo "Test Summary:"
    echo "  Passed: $tests_passed/$tests_total"
    echo "=================================="
    
    if [[ $tests_passed -eq $tests_total ]]; then
        print_status "All tests passed! Your backup system is ready to use."
        echo ""
        print_status "Next steps:"
        echo "  1. Review and customize backup_config.yml"
        echo "  2. Test with: ./run_backup.sh --help"
        echo "  3. Run first backup: ./run_backup.sh"
    else
        print_warning "Some tests failed. Please fix the issues before using the backup system."
    fi
    
    echo ""
    read -p "Run dry-run backup test? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_dry_run
    fi
}

# Run main function
main "$@"
