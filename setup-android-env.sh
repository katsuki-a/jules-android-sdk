#!/bin/bash

# ==============================================================================
# Jules Android SDK Environment Setup Script
#
# This script establishes a complete, high-performance, and reproducible
# Android build environment within the ephemeral Jules VM.
# It is designed to be run once and then snapshotted for future use.
# ==============================================================================

# ---
# 1. Script Configuration and Error Handling
# ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipelines return the exit status of the last command to exit with a
# non-zero status, or zero if all commands exit successfully.
set -o pipefail

echo "--- Starting Android SDK Environment Setup ---"

# ---
# 2. Environment Variables and Configuration
# ---
# These variables can be customized to match project requirements.
export ANDROID_SDK_ROOT="${HOME}/android_sdk"
# Official download link for the latest command-line tools.
# See: https://developer.android.com/studio#command-line-tools-only
readonly CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
readonly BUILD_TOOLS_VERSION="34.0.0"
readonly PLATFORM_VERSION="android-34"

# ---
# 3. Android SDK Command-Line Tools Installation
# ---
echo "--> Downloading and setting up Android SDK command-line tools..."

# Create a temporary directory to avoid polluting the workspace.
readonly TMP_DIR=$(mktemp -d)

# Download the tools package into the temporary directory.
wget -q "${CMDLINE_TOOLS_URL}" -O "${TMP_DIR}/cmdline-tools.zip"

# Create the required directory structure for the SDK.
mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"

# Unzip the package from the temporary directory into the target directory.
# The -o option overwrites files without prompting.
unzip -o -q -d "${ANDROID_SDK_ROOT}/cmdline-tools" "${TMP_DIR}/cmdline-tools.zip"

# The tools must be placed in a 'latest' subdirectory for sdkmanager to work correctly.
# See: https://developer.android.com/tools/sdkmanager
# We remove any existing 'latest' directory to ensure the move is clean.
rm -rf "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"

# Clean up the temporary directory and its contents.
rm -rf "${TMP_DIR}"

# ---
# 4. Environment Variable Configuration
# ---
echo "--> Configuring ANDROID_HOME and PATH environment variables..."

# Set ANDROID_HOME. This is a best practice for command-line builds.
export ANDROID_HOME="${ANDROID_SDK_ROOT}"

# Add the essential SDK tool directories to the PATH.
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# ---
# 5. Headless License Acceptance
# ---
echo "--> Accepting SDK licenses automatically..."

# In a non-interactive environment, we must accept licenses programmatically
# before attempting to install packages.
yes | sdkmanager --licenses > /dev/null

# ---
# 6. Installing Core SDK Packages with sdkmanager
# ---
echo "--> Installing core SDK packages (platform-tools, build-tools, platform)..."

# Use sdkmanager to install the necessary packages for building an Android app.
# The package paths are specified as per the official documentation.
sdkmanager "platform-tools" "build-tools;${BUILD_TOOLS_VERSION}" "platforms;${PLATFORM_VERSION}"

# ---
# 7. Environment Validation
# ---
# This final step verifies that the environment is correctly configured
# before the snapshot is taken.
echo "--> Validating the new environment..."

echo "Java Version:"
java -version
echo ""

echo "ANDROID_HOME:"
echo "${ANDROID_HOME}"
echo ""

echo "PATH:"
echo "${PATH}"
echo ""

echo "Verifying tool locations:"
which sdkmanager
which adb
echo ""

echo "Listing installed SDK packages:"
sdkmanager --list_installed
echo ""

echo "--- Android SDK Environment Setup Complete ---"
