#!/bin/sh

# Function to check for required commands
check_command() {
    command -v "$1" >/dev/null 2>&1 || { echo >&2 "Error: $1 is required but not installed."; exit 1; }
}

# Check for required commands
check_command curl
check_command wget
check_command sha256sum || check_command sha1sum

# Set checksum command based on availability
CHECKSUM_CMD=sha256sum
if ! command -v $CHECKSUM_CMD >/dev/null 2>&1; then
    CHECKSUM_CMD=sha1sum
fi

# Function to download and verify a file
download_and_verify() {
    URL=$1
    EXPECTED_CHECKSUM=$2
    TEMP_FILE=$(mktemp)

    # Download the file
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$TEMP_FILE" "$URL"
    else
        wget -O "$TEMP_FILE" "$URL"
    fi

    # Verify the checksum
    if [ "$($CHECKSUM_CMD "$TEMP_FILE" | awk '{print $1}')" != "$EXPECTED_CHECKSUM" ]; then
        echo "Checksum verification failed!"
        rm -f "$TEMP_FILE"
        exit 1
    fi

    echo "Download and verification successful!"
    # Continue with installation...
}

# Example usage
download_and_verify "https://example.com/file" "expectedchecksumvalue"

# Cleanup
rm -f "$TEMP_FILE"
echo "Installation completed successfully!"
