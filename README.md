# Android SDK Environment Setup Script

This repository contains a shell script to automate the setup of a complete Android SDK environment on a Linux-based system. It is designed for non-interactive, automated execution, making it ideal for CI/CD pipelines, container-based development environments (like Docker or Gitpod), and virtual machine provisioning.

The script installs the Android SDK command-line tools, specific versions of the platform-tools, build-tools, and a system image, and configures the necessary environment variables.

## Features

- **Automated & Non-Interactive**: Runs without any user input.
- **Reproducible**: Installs specific versions of the Android SDK components for consistent environments.
- **Self-Contained**: Installs the SDK into a local directory (`~/android_sdk`) without requiring root permissions.
- **Configurable**: Key variables like SDK versions can be easily modified at the top of the script.
- **Validates Setup**: Includes a final validation step to confirm the environment is configured correctly.

## How to Use

1.  **Download the script**:
    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```
    (Replace `your-username/your-repo-name` with the actual repository URL).

2.  **Make the script executable**:
    ```bash
    chmod +x setup-android-env.sh
    ```

3.  **Run the script**:
    ```bash
    ./setup-android-env.sh
    ```

After the script finishes, your shell environment will have `ANDROID_HOME` and `PATH` configured, and tools like `sdkmanager` and `adb` will be available. To make these changes permanent, you may need to add the `export` commands to your shell's profile file (e.g., `~/.bashrc`, `~/.zshrc`).

## Customization

You can customize the versions of the SDK components by editing the following variables at the top of `setup-android-env.sh`:

- `CMDLINE_TOOLS_URL`: The download URL for the Android command-line tools. You can find the latest version on the [Android Studio download page](https://developer.android.com/studio#command-line-tools-only).
- `BUILD_TOOLS_VERSION`: The version of the build-tools to install (e.g., `"34.0.0"`).
- `PLATFORM_VERSION`: The API level of the platform to install (e.g., `"android-34"`).

## Requirements

- A Linux-based environment.
- `wget`, `unzip`, `mktemp`.
- Java Development Kit (JDK) installed. The script itself does not install Java.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.