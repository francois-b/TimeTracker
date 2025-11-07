#!/bin/bash

# Launch script for TimeTracker with environment variables

# Load environment variables from shell profile
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

# Check if NEON_PASSWORD is set
if [ -z "$NEON_PASSWORD" ]; then
    echo "Warning: NEON_PASSWORD environment variable is not set"
    echo "Database integration will not work without it"
    echo ""
    echo "To set it, run:"
    echo "  export NEON_PASSWORD=\"your_neon_password\""
    echo ""
fi

# Launch the app
open TimeTracker.app
