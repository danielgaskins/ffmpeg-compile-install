#!/bin/bash

set -e  # Exit on any error

echo "Starting FFmpeg compilation and installation..."

# Function to check NASM version
check_nasm_version() {
  if command -v nasm &> /dev/null; then
    local nasm_version=$(nasm -v | grep 'NASM version' | awk '{print $3}')
    if [ "$(printf '%s\n%s' "2.13" "$nasm_version" | sort -V | head -n1)" = "2.13" ]; then
      return 0
    fi
  fi
  return 1
}

install_packages_ubuntu() {
  echo "Updating package list and installing dependencies for Ubuntu/Debian/Mint..."
  sudo apt-get update -qq
  sudo apt-get install -y autoconf automake build-essential cmake git-core libass-dev libfreetype6-dev \
      libgnutls28-dev libmp3lame-dev libsdl2-dev libtool libva-dev libvdpau-dev libvorbis-dev \
      libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev meson ninja-build pkg-config texinfo wget \
      yasm zlib1g-dev libunistring-dev libaom-dev libdav1d-dev
}

install_packages_mac() {
  echo "Installing dependencies for macOS..."
  brew update
  brew install autoconf automake cmake git libass libfreetype gnupg libvorbis libtool sdl2 \
      xz pkgconfig texinfo wget yasm zlib libvpx opus
  brew install gcc nasm # Homebrew gcc and nasm
  brew install aom # AV1 encoder/decoder library
  brew install svt-av1 # SVT-AV1 encoder/decoder
  brew install dav1d # AV1 decoder
  brew install vmaf # Video quality metric library
}

echo "Creating directories..."
mkdir -p ~/ffmpeg_sources ~/bin

OS=$(uname -s)

if [[ "$OS" == "Linux" ]]; then
  install_packages_ubuntu
elif [[ "$OS" == "Darwin" ]]; then
  install_packages_mac
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Check if NASM is installed and meets the version requirement
if ! check_nasm_version; then
  echo "NASM >= 2.13 is required, installing it..."
  cd ~/ffmpeg_sources && \
  wget https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/nasm-2.16.01.tar.bz2 && \
  tar xjvf nasm-2.16.01.tar.bz2 && \
  cd nasm-2.16.01 && \
  ./autogen.sh && \
  PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
  make && \
  make install
  export PATH="$HOME/bin:$PATH"
fi

# Function to compile and install a library from source
compile_and_install() {
  local url=$1
  local folder=$2
  local config_cmd=$3

  cd ~/ffmpeg_sources && \
  if [ -d $folder ]; then
    cd $folder && git pull 2> /dev/null
  else
    git clone --depth 1 $url $folder
  fi
  cd $folder && \
  eval $config_cmd && \
  make && \
  make install
}

# Library compilation and installation
compile_and_install https://code.videolan.org/videolan/x264.git x264 \
  'PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --enable-pic'

sudo apt-get install -y libnuma-dev && \
compile_and_install https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 x265 \
  'cd build/linux && PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off ../../source'

compile_and_install https://chromium.googlesource.com/webm/libvpx.git libvpx \
  'PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm'

compile_and_install https://github.com/mstorsjo/fdk-aac fdk-aac \
  'autoreconf -fiv && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared'

compile_and_install https://github.com/xiph/opus.git opus \
  './autogen.sh && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared'

compile_and_install https://aomedia.googlesource.com/aom aom \
  'mkdir -p aom_build && cd aom_build && PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_TESTS=OFF -DENABLE_NASM=on ../aom'

compile_and_install https://gitlab.com/AOMediaCodec/SVT-AV1.git SVT-AV1 \
  'mkdir -p build && cd build && PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DCMAKE_BUILD_TYPE=Release -DBUILD_DEC=OFF -DBUILD_SHARED_LIBS=OFF ..'

compile_and_install https://code.videolan.org/videolan/dav1d.git dav1d \
  'mkdir -p build && cd build && meson setup -Denable_tools=false -Denable_tests=false --default-library=static .. --prefix "$HOME/ffmpeg_build" --libdir="$HOME/ffmpeg_build/lib"'

cd ~/ffmpeg_sources && \
wget https://github.com/Netflix/vmaf/archive/v3.0.0.tar.gz && \
tar xvf v3.0.0.tar.gz && \
cd vmaf-3.0.0/libvmaf/build && \
meson setup -Denable_tests=false -Denable_docs=false --buildtype=release --default-library=static .. --prefix "$HOME/ffmpeg_build" --bindir="$HOME/bin" --libdir="$HOME/ffmpeg_build/lib" && \
ninja && \
ninja install

echo "Compiling FFmpeg..."
cd ~/ffmpeg_sources && \
wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjvf ffmpeg-snapshot.tar.bz2 && \
cd ffmpeg && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-gnutls \
  --enable-libaom \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsvtav1 \
  --enable-libdav1d \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree && \
PATH="$HOME/bin:$PATH" make -j$(nproc) && \
make install && \
hash -r

echo "FFmpeg compilation and installation completed! Add to manpath..."
echo "MANPATH_MAP $HOME/bin $HOME/ffmpeg_build/share/man" >> ~/.manpath
source ~/.profile

echo "FFmpeg is now installed. You can use it by typing 'ffmpeg'."