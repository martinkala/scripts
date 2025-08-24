#!/bin/bash

# Ansible Backup System Script
# Usage: ./run_backup.sh [OPTIONS]
#
# Options:
#   -d, --destination DIR    Specify custom backup destination directory
#   -h, --host HOST          Specify source host group (default: web)
#   -c, --config FILE        Specify backup config file (default: backup_config.yml)
#   -v, --verbose            Enable verbose output
#   --help                   Show this help message

set -e

# Default values
BACKUP_DESTINATION=""
HOST_GROUP="web"
CONFIG_FILE="backup_config.yml"
VERBOSE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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
    echo -e "${BLUE}  Ansible Backup System${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to show help
show_help() {
    cat << EOF
Ansible Backup System

Usage: $0 [OPTIONS]

Options:
  -d, --destination DIR    Specify custom backup destination directory
  -h, --host HOST          Specify source host group (default: web)
  -c, --config FILE        Specify backup config file (default: backup_config.yml)
  -v, --verbose            Enable verbose output
  --help                   Show this help message

Examples:
  $0                                    # Run backup with default timestamp directory
  $0 -d /custom/backup/path            # Run backup to custom directory
  $0 --host web --verbose              # Run backup with verbose output
  $0 -c custom_config.yml              # Use custom config file

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--destination)
            BACKUP_DESTINATION="$2"
            shift 2
            ;;
        -h|--host)
            HOST_GROUP="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="-v"
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if required files exist
check_requirements() {
    print_status "Checking requirements..."
    
    if [[ ! -f "ansible.cfg" ]]; then
        print_error "ansible.cfg not found in current directory"
        exit 1
    fi
    
    if [[ ! -f "hosts" ]]; then
        print_error "hosts file not found in current directory"
        exit 1
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Backup config file '$CONFIG_FILE' not found"
        exit 1
    fi
    
    if [[ ! -f "backup.yml" ]]; then
        print_error "Backup playbook 'backup.yml' not found"
        exit 1
    fi
    
    print_status "All requirements satisfied"
}

# Function to show backup preview
show_backup_preview() {
    print_status "Backup Preview:"
    echo "  Source host group: $HOST_GROUP"
    echo "  Config file: $CONFIG_FILE"
    
    if [[ -n "$BACKUP_DESTINATION" ]]; then
        echo "  Destination: $BACKUP_DESTINATION"
    else
        echo "  Destination: /home/martin/backup/IP_YYYYMMDDHHMI (auto-generated)"
    fi
    
    echo "  Config file: $CONFIG_FILE"
    echo ""
    
    # Show what will be backed up
    if [[ -f "$CONFIG_FILE" ]]; then
        print_status "Items to be backed up:"
        grep "^- /" "$CONFIG_FILE" | sed 's/^  - /    /' || print_warning "No backup sources found in config"
        echo ""
    fi
}

# Function to run the backup
run_backup() {
    print_status "Starting backup process..."
    
    # Build ansible-playbook command
    CMD="ansible-playbook backup.yml"
    
    if [[ -n "$BACKUP_DESTINATION" ]]; then
        CMD="$CMD -e backup_destination=$BACKUP_DESTINATION"
    fi
    
    if [[ -n "$VERBOSE" ]]; then
        CMD="$CMD $VERBOSE"
    fi
    
    CMD="$CMD --limit=$HOST_GROUP"
    
    print_status "Executing: $CMD"
    echo ""
    
    # Execute the backup
    if eval $CMD; then
        print_status "Backup completed successfully!"
        
        # Show final destination
        if [[ -n "$BACKUP_DESTINATION" ]]; then
            FINAL_DEST="$BACKUP_DESTINATION"
        else
            TIMESTAMP=$(date +%Y%m%d%H%M)
            # Note: The actual directory will include IP address prefix
            FINAL_DEST="/home/martin/backup/IP_$TIMESTAMP"
        fi
        
        echo ""
        print_status "Backup location: $FINAL_DEST"
        print_status "Archive created: ${FINAL_DEST}.tar.gz"
        
    else
        print_error "Backup failed!"
        exit 1
    fi
}

# Main execution
main() {
    print_header
    echo ""
    
    check_requirements
    echo ""
    
    show_backup_preview
    
    # Ask for confirmation
    read -p "Do you want to proceed with the backup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Backup cancelled by user"
        exit 0
    fi
    
    echo ""
    run_backup
}

# Run main function
main "$@"
