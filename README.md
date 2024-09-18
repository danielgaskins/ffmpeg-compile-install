# FFmpeg Compilation and Installation Script

This repository contains a single script to compile and install FFmpeg with several third-party libraries on both macOS and Ubuntu/Debian/Mint systems.

## Files

- `install_ffmpeg.sh`: The script to download, compile, and install FFmpeg and its dependencies.

## Prerequisites

- Ensure you have `sudo` privileges as the script requires installing several packages.
- Ensure your system has sufficient disk space and memory for compiling software.
- For macOS, [Homebrew](https://brew.sh/) should be installed.

## Usage

1. **Clone the repository:**

   ```sh
   git clone https://github.com/yourusername/ffmpeg-compile-install.git
   cd ffmpeg-compile-install
   ```

2. **Make the script executable:**

   ```sh
   chmod +x install_ffmpeg.sh
   ```

3. **Run the script:**

   ```sh
   ./install_ffmpeg.sh
   ```

   The script will:
   - Detect your operating system.
   - Install the necessary dependencies using the appropriate package manager (`apt-get` for Linux, `brew` for macOS).
   - Create directories for source files and binaries.
   - Download, compile, and install FFmpeg and its dependencies.

4. **Post Installation:**

   Once the script has finished running, FFmpeg (along with ffplay, ffprobe, lame, x264, x265) will be installed in your home directory under `~/bin`. You can use the new ffmpeg binaries simply by typing `ffmpeg` in your terminal.

   If you want all users on the system to access the new ffmpeg, you can copy the binaries to `/usr/local/bin`:

   ```sh
   sudo cp ~/bin/{ffmpeg,ffprobe,ffplay,x264,x265} /usr/local/bin/
   ```

## Uninstallation

To revert the changes made by this script, you can remove the build and source files as well as the binaries:

```sh
rm -rf ~/ffmpeg_build ~/ffmpeg_sources ~/bin/{ffmpeg,ffprobe,ffplay,x264,x265,nasm}
sed -i '/ffmpeg_build/d' ~/.manpath
hash -r
```

To remove the packages that were installed for compiling FFmpeg on Ubuntu/Debian/Mint:

```sh
sudo apt-get autoremove autoconf automake build-essential cmake git-core libass-dev libfreetype6-dev \
    libgnutls28-dev libmp3lame-dev libnuma-dev libopus-dev libsdl2-dev libtool libva-dev \
    libvdpau-dev libvorbis-dev libvpx-dev libx264-dev libx265-dev libxcb1-dev libxcb-shm0-dev \
    libxcb-xfixes0-dev texinfo wget yasm zlib1g-dev
```

For macOS, use `brew` to uninstall installed packages:

```sh
brew uninstall autoconf automake cmake git libass libfreetype gnupg libvorbis libtool sdl2 \
    xz pkgconfig texinfo wget yasm zlib libvpx opus gcc nasm aom svt-av1 dav1d vmaf
```

## Support

If you encounter any issues or have questions, please open an issue in this repository.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.