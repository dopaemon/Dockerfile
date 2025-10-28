# Ubuntu 22.04 Jammy
FROM ubuntu:22.04

# ENV
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=dora
ENV HOSTNAME=localhost
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# Install packages
RUN apt-get update

RUN apt-get install -yyq \
    build-essential bison flex \
    libncurses-dev libelf-dev wget \
    sudo curl git ccache automake \
    zip bzip2 libbz2-dev libbz2-1.0 \
    libghc-bzlib-dev dpkg-dev make \
    optipng maven pwgen libswitch-perl \
    policycoreutils minicom libxml-sax-base-perl \
    libxml-simple-perl libc6-dev-i386 libx11-dev \
    lib32z-dev libgl1-mesa-dev unzip \
    device-tree-compiler rename dwarves \
    openjdk-8-jdk bc bison g++-multilib \
    gcc-multilib gnupg gperf imagemagick \
    lib32ncurses5-dev lib32readline-dev \
    lib32z1-dev liblz4-tool libncurses5-dev \
    libncurses5 libsdl1.2-dev libssl-dev \
    libwxgtk3.0-gtk3-dev libxml2 libxml2-utils \
    lzop pngcrush rsync schedtool squashfs-tools \
    xsltproc zlib1g-dev python3 python-is-python3

RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LC_ALL=en_US.UTF-8
RUN locale-gen en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

# Install repo
RUN set -x \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && chmod a+x /usr/local/bin/repo

# Link Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Clean APT
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/*

# Setup User
RUN useradd -ms /bin/bash shell
RUN echo "shell ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN echo "shell:123456"|chpasswd
RUN useradd -ms /bin/bash dora
RUN echo "dora ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER dora
WORKDIR /home/dora

# Git configs
RUN git config --global color.ui true
RUN git config --global credential.helper store
RUN git config --global user.name "development"
RUN git config --global user.email "development@example.com"
RUN git config --global core.editor "nano -w"

ENTRYPOINT ["/bin/bash"]
