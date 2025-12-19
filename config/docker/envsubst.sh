#!/bin/bash
# Script to substitute environment variables in configuration templates
# Usage: ./envsubst.sh <template_file> <output_file>

set -e

TEMPLATE_FILE=$1
OUTPUT_FILE=$2

if [ -z "$TEMPLATE_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <template_file> <output_file>"
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file '$TEMPLATE_FILE' not found"
    exit 1
fi

# Substitute environment variables using envsubst
# Only substitute variables that are defined
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Configuration generated: $OUTPUT_FILE"
