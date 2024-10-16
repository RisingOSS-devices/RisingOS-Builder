# RisingOS-Builder

**RisingOS-Builder** is a **self-hosted Continuous Integration (CI) build server** designed for RisingOS maintainers. This project is proudly sponsored by [@manidweep](https://github.com/manidweep).

## License

This project is licensed under the MIT License. For more details, please refer to the [LICENSE](LICENSE) file.

## Getting Started

To start using RisingOS-Builder, follow these steps:

1. **Navigate to the Actions Tab:**
   - Go to the **Actions** tab in the repository.

2. **Select the RisingOS-Builder Workflow:**
   - Choose the **RisingOS-Builder** workflow from the list.

3. **Run the Workflow:**
   - Click the **Run workflow** button.
   - Fill in the required information in the provided fields.
   - Execute the workflow and wait for your build to start. Note that it may take some time if there are ongoing builds.

4. **Monitor Build Progress:**
   - Once the build begins, you can monitor its progress, view logs, and access artifacts directly in the **Actions** tab.

5. **Access Build Outputs:**
   - If you specified the build as a test build, the output will be available in the SourceForge test project.
   - For stable builds, the output will be accessible in the designated Drive location.

## Note

- **Do not add `vendorsetup.sh`:** Include all necessary components in the `dependencies` file.
- **Build Limits:** Normal maintainers are limited to 3 builds per device, while those with staging source access have 5. Organization owners have unlimited builds.

## Credits

- **Resync Script:** Special thanks to the team at [crave](https://github.com/accupara/docker-images/blob/master/aosp/common/resync.sh) for the base resync script.