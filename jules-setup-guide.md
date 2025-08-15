-----

Here is a document, translated and optimized in English, for Jules to use as a guide for autonomously creating and executing an Android environment setup script.

-----

## **Jules: Android Build Environment Technical Specification**

This document provides the technical specification for establishing a robust, high-performance, and reproducible Android build environment within the Jules VM. It is intended to be used as a direct guide for autonomous script generation and execution.

### **1. Core Principles & Environmental Constraints**

The setup script must adhere to the following architectural principles of the Jules environment:

  * **Ephemeral Execution Context**: The environment is a stateless, short-lived Ubuntu Linux VM that is destroyed after each task. All required software (i.e., the Android SDK) must be installed and configured programmatically via a setup script.
  * **Primary Optimization Strategy - Environment Snapshotting**: The single most critical performance optimization is the "Environment Snapshot" feature. The primary goal of the setup script is not just to set up the environment, but to create a perfect, reusable "golden image" that can be snapshotted. This amortizes the high cost of the initial SDK download and setup across all subsequent tasks.
  * **Immutable Pre-installed Toolchain**: The VM comes with **OpenJDK 21** pre-installed. This is a non-negotiable constraint. All build tooling, specifically the Gradle version, must be compatible with a JDK 21 execution environment.
  * **Single Scripted Entrypoint**: All environment configuration is performed via a single shell script provided in the "Initial Setup" field. The script must be fully non-interactive.
  * **Principle of Least Privilege**: The script must operate entirely within the user space. It should not require `sudo` or other elevated permissions. The self-contained SDK installation detailed below adheres to this principle.

### **2. Reference Implementation: Setup Script**

This is the definitive reference script for creating the Android build environment. It is designed to be executed once and then snapshotted.

```bash
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

# Download the tools package. The -q flag enables quiet mode.
wget -q "${CMDLINE_TOOLS_URL}" -O cmdline-tools.zip

# Create the required directory structure for the SDK.
mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"

# Unzip the package into the target directory.
unzip -q -d "${ANDROID_SDK_ROOT}/cmdline-tools" cmdline-tools.zip

# The tools must be placed in a 'latest' subdirectory for sdkmanager to work correctly.
# See: https://developer.android.com/tools/sdkmanager
mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"

# Clean up the downloaded zip file.
rm cmdline-tools.zip

# ---
# 4. Environment Variable Configuration
# ---
echo "--> Configuring ANDROID_HOME and PATH environment variables..."

# Set ANDROID_HOME. This is a best practice for command-line builds.
export ANDROID_HOME="${ANDROID_SDK_ROOT}"

# Add the essential SDK tool directories to the PATH.
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# ---
# 5. Installing Core SDK Packages with sdkmanager
# ---
echo "--> Installing core SDK packages (platform-tools, build-tools, platform)..."

# Use sdkmanager to install the necessary packages for building an Android app.
# The package paths are specified as per the official documentation.
sdkmanager "platform-tools" "build-tools;${BUILD_TOOLS_VERSION}" "platforms;${PLATFORM_VERSION}"

# ---
# 6. Headless License Acceptance
# ---
echo "--> Accepting SDK licenses automatically..."

# In a non-interactive environment, we must accept licenses programmatically.
# Piping 'yes' to the command achieves this.
yes | sdkmanager --licenses > /dev/null

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
```

### **3. Key Technical Directives & Rationale**

  * **SDK Directory Structure**: The `cmdline-tools` must be placed within a subdirectory named `latest` (i.e., `.../cmdline-tools/latest/`). This is a strict requirement for `sdkmanager` to function correctly.
  * **Build Toolchain Compatibility**:
      * The pre-installed JDK 21 mandates the use of **Gradle version 8.5 or newer**.
      * The project being built *must* use the Gradle Wrapper (`./gradlew`) and its `gradle-wrapper.properties` must specify a compatible Gradle distribution URL. Builds must be invoked with `./gradlew`, never a system-installed `gradle`.
  * **Performance Configuration (gradle.properties)**: For optimal build performance after the snapshot is loaded, the project's `gradle.properties` file should include:
      * `org.gradle.caching=true` (Enables build cache)
      * `org.gradle.configuration-cache=true` (Enables configuration cache)
      * `org.gradle.parallel=true` (Enables parallel execution)
      * `org.gradle.jvmargs=-Xmx4g` (Or a higher value, to provide sufficient heap memory)
  * **Gradle Daemon**: Do not disable the Gradle Daemon (e.g., with `--no-daemon`). In Jules's ephemeral environment, the default behavior is optimal. A single-use daemon is created and automatically cleaned up with the VM, and disabling it offers no benefit.
  * **Build Reproducibility**: Projects must enable Gradle's dependency locking feature. This ensures deterministic builds by forcing dependency resolution to match a committed `gradle.lockfile`.
      * Enable in `build.gradle.kts`: `dependencyLocking { lockAllConfigurations() }`
      * Generate/update lockfiles with: `./gradlew dependencies --write-locks`
      * The `gradle.lockfile` must be committed to the version control repository.

### **4. Task Execution Example**

Once the environment is established (or a snapshot is loaded), a typical Android build and test task should be invoked as follows:

```bash
./gradlew assembleDebug testDebugUnitTest --build-cache --configuration-cache
```

This command leverages the Gradle Wrapper and explicitly enables caching features for maximum performance.
