# Use the official ZMK build environment - same as GitHub Actions
FROM zmkfirmware/zmk-build-arm:stable

# Set working directory
WORKDIR /workspace

# Set default command
CMD ["/bin/bash"]
