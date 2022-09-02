# Import Ubuntu 20.04 Image
FROM ubuntu:20.04

# ENV
ENV DEBIAN_FRONTEND noninteractive
ENV USER Dopaemon
ENV HOSTNAME dopaemon
ENV USE_CCACHE 1
ENV LC_ALL C
ENV CCACHE_COMPRESS 1
ENV CCACHE_SIZE 50G
ENV CCACHE_DIR /tmp/ccache
ENV CCACHE_EXEC /usr/bin/ccache 
ENV USE_CCACHE true
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# Install packages
RUN apt-get update
RUN apt-get install -yq libpam-pwquality software-properties-common sudo 
RUN apt-get install -yq cpio bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5-dev libncurses5 libsdl1.2-dev libssl-dev libwxgtk3.0-gtk3-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev openjdk-8-jdk python-is-python3

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list && apt update && apt install ngrok -yq

# Install Gh
RUN /usr/bin/apt-key adv --no-tty --keyserver hkp://keyserver.ubuntu.com:80 --recv C99B11DEB97541F0
RUN apt-add-repository https://cli.github.com/packages
RUN apt-get update
RUN apt-get install gh -yq

RUN apt-get install jq wget unzip aria2 git -y -q

RUN apt-get purge openjdk-8-jdk openjdk-8-jre openjdk-11-jdk openjdk-11-jre -y

RUN apt-get install openjdk-8-jdk openjdk-8-jre -y


RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

RUN apt-get install -yq linux-libc-dev

## GCC
RUN apt-get install -yq gcc-i686-linux-gnu gcc-mipsel-linux-gnu gcc-mips64-linux-gnuabi64 gcc-mips-linux-gnu gcc-arm-linux-gnueabihf gcc-riscv64-linux-gnu gcc-8-aarch64-linux-gnu gcc-8-s390x-linux-gnu gcc-aarch64-linux-gnu gcc-s390x-linux-gnu gcc-arm-linux-gnueabi

# Install repo
RUN set -x \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && chmod a+x /usr/local/bin/repo

RUN rm -rf /var/lib/apt/lists/*

# Link Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Install GoLang
# RUN add-apt-repository ppa:longsleep/golang-backports
# RUN apt-get update
# RUN apt-get install golang-go -yq
# RUN mkdir -p ~/go/{bin,pkg,src}
# RUN echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
# RUN echo 'export PATH="$PATH:${GOPATH//://bin:}/bin"' >> ~/.bashrc
# RUN wget https://storage.googleapis.com/golang/$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version').linux-amd64.tar.gz
# RUN tar -xf go*linux-amd64.tar.gz
# RUN chown -R root:root go
# RUN mv -v go /usr/local
# RUN echo "export GOPATH=$HOME/go" >> /root/.bashrc
# RUN echo "export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin" >> /root/.bashrc

# My Script
RUN wget -O compile-xray-core https://raw.githubusercontent.com/dopaemon/Dockerfile/bionic/compile-xray-core
RUN wget -O compile-xrayr https://raw.githubusercontent.com/dopaemon/Dockerfile/bionic/compile-xrayr
RUN wget -O compile-xui https://raw.githubusercontent.com/dopaemon/Dockerfile/bionic/compile-xui

RUN chmod +x compile-xray-core
RUN chmod +x compile-xrayr
RUN chmod +x compile-xui

RUN rm -rf /usr/bin/compile-xray-core
RUN rm -rf /usr/bin/compile-xrayr
RUN rm -rf /usr/bin/compile-xui

RUN cp -r compile-xray-core /usr/bin/
RUN cp -r compile-xrayr /usr/bin/
RUN cp -r compile-xui /usr/bin/

# Add User
# Why? Well for avoid something wrong
# I've seen some notes for not using root when build

RUN useradd -ms /bin/bash shell
RUN echo "shell ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN echo "shell:123456"|chpasswd

RUN useradd -ms /bin/bash doraemon
RUN echo "doraemon ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER doraemon
WORKDIR /home/doraemon

# Git
RUN git config --global user.email "polarisdp@gmail.com"
RUN git config --global user.name "dopaemon"
RUN git config --global color.ui false

# GoLang ENV
# RUN echo "export GOPATH=$HOME/go" >> /home/doraemon/.bashrc
# RUN echo "export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin" >> /home/doraemon/.bashrc
# RUN mkdir -p ~/go/{bin,pkg,src}
# RUN echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
# RUN echo 'export PATH="$PATH:${GOPATH//://bin:}/bin"' >> ~/.bashrc

# Work in the build directory, repo is expected to be init'd here
WORKDIR /src

# This is where the magic happens~
ENTRYPOINT ["/bin/bash"]
