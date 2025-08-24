#!/bin/bash

# Backup Cleanup Script
# Removes old backups based on retention settings in backup_config.yml
# Usage: ./cleanup_backups.sh [OPTIONS]
#
# Options:
#   -d, --backup-dir DIR    Specify backup directory (default: /home/martin/backup)
#   -c, --config FILE       Specify backup config file (default: backup_config.yml)
#   -f, --force             Force cleanup without confirmation
#   --dry-run               Show what would be deleted without actually deleting
#   --help                  Show this help message

set -e

# Default values
BACKUP_DIR="/home/martin/backup"
CONFIG_FILE="backup_config.yml"
FORCE=false
DRY_RUN=false

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
    echo -e "${BLUE}  Backup Cleanup Script${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to show help
show_help() {
    cat << EOF
Backup Cleanup Script

Usage: $0 [OPTIONS]

Options:
  -d, --backup-dir DIR    Specify backup directory (default: /home/martin/backup)
  -c, --config FILE       Specify backup config file (default: backup_config.yml)
  -f, --force             Force cleanup without confirmation
  --dry-run               Show what would be deleted without actually deleting
  --help                  Show this help message

Examples:
  $0                      # Run cleanup with default settings
  $0 --dry-run           # Show what would be deleted
  $0 -f                  # Force cleanup without confirmation
  $0 -d /custom/backup   # Use custom backup directory

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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

# Function to load retention settings
load_retention_settings() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Extract retention days from config file
        RETENTION_DAYS=$(grep -A 5 "backup_retention:" "$CONFIG_FILE" | grep "days:" | awk '{print $2}' | head -1)
        MAX_BACKUPS=$(grep -A 5 "backup_retention:" "$CONFIG_FILE" | grep "max_backups:" | awk '{print $2}' | head -1)
        
        # Set defaults if not found
        RETENTION_DAYS=${RETENTION_DAYS:-30}
        MAX_BACKUPS=${MAX_BACKUPS:-10}
        
        print_status "Retention settings: $RETENTION_DAYS days, max $MAX_BACKUPS backups"
    else
        print_warning "Config file not found, using default retention: 30 days, max 10 backups"
        RETENTION_DAYS=30
        MAX_BACKUPS=10
    fi
}

# Function to find old backups
find_old_backups() {
    print_status "Scanning backup directory: $BACKUP_DIR"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_error "Backup directory does not exist: $BACKUP_DIR"
        exit 1
    fi
    
    # Find directories older than retention days
    OLD_DIRS=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS 2>/dev/null | sort)
    
    # Find directories exceeding max_backups limit
    ALL_DIRS=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "20*" 2>/dev/null | sort)
    TOTAL_DIRS=$(echo "$ALL_DIRS" | wc -l)
    
    if [[ $TOTAL_DIRS -gt $MAX_BACKUPS ]]; then
        EXCESS_COUNT=$((TOTAL_DIRS - MAX_BACKUPS))
        EXCESS_DIRS=$(echo "$ALL_DIRS" | head -$EXCESS_COUNT)
    else
        EXCESS_DIRS=""
    fi
    
    # Combine old and excess directories
    TO_DELETE=""
    if [[ -n "$OLD_DIRS" ]]; then
        TO_DELETE="$OLD_DIRS"
    fi
    
    if [[ -n "$EXCESS_DIRS" ]]; then
        if [[ -n "$TO_DELETE" ]]; then
            TO_DELETE="$TO_DELETE"$'\n'"$EXCESS_DIRS"
        else
            TO_DELETE="$EXCESS_DIRS"
        fi
    fi
    
    # Remove duplicates and sort
    TO_DELETE=$(echo "$TO_DELETE" | sort -u)
    
    if [[ -z "$TO_DELETE" ]]; then
        print_status "No backups to clean up"
        return 0
    fi
    
    print_status "Found backups to clean up:"
    echo "$TO_DELETE" | while read -r dir; do
        if [[ -n "$dir" ]]; then
            size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            date=$(stat -c %y "$dir" 2>/dev/null | cut -d' ' -f1)
            echo "  $dir ($size, $date)"
        fi
    done
    
    return 1
}

# Function to perform cleanup
perform_cleanup() {
    local count=0
    local total_size=0
    
    print_status "Starting cleanup..."
    
    echo "$TO_DELETE" | while read -r dir; do
        if [[ -n "$dir" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_status "[DRY RUN] Would delete: $dir"
            else
                size=$(du -sb "$dir" 2>/dev/null | cut -f1)
                if [[ -n "$size" ]]; then
                    total_size=$((total_size + size))
                fi
                
                print_status "Deleting: $dir"
                rm -rf "$dir"
                
                # Also remove the corresponding tar.gz file if it exists
                if [[ -f "${dir}.tar.gz" ]]; then
                    print_status "Deleting archive: ${dir}.tar.gz"
                    rm -f "${dir}.tar.gz"
                fi
                
                count=$((count + 1))
            fi
        fi
    done
    
    if [[ "$DRY_RUN" == "false" ]]; then
        print_status "Cleanup completed: $count backups removed"
        if [[ $total_size -gt 0 ]]; then
            print_status "Space freed: $(numfmt --to=iec $total_size)"
        fi
    else
        print_status "[DRY RUN] Would remove $count backups"
    fi
}

# Function to show cleanup summary
show_cleanup_summary() {
    print_status "Cleanup Summary:"
    echo "  Backup directory: $BACKUP_DIR"
    echo "  Retention period: $RETENTION_DAYS days"
    echo "  Max backups: $MAX_BACKUPS"
    echo "  Current backups: $TOTAL_DIRS"
    echo "  Backups to remove: $(echo "$TO_DELETE" | wc -l)"
    echo ""
}

# Main execution
main() {
    print_header
    echo ""
    
    load_retention_settings
    echo ""
    
    if find_old_backups; then
        exit 0
    fi
    
    echo ""
    show_cleanup_summary
    
    if [[ "$DRY_RUN" == "true" ]]; then
        perform_cleanup
        exit 0
    fi
    
    if [[ "$FORCE" == "false" ]]; then
        echo "This will permanently delete the listed backups."
        read -p "Do you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Cleanup cancelled by user"
            exit 0
        fi
    fi
    
    echo ""
    perform_cleanup
}

# Run main function
main "$@"
