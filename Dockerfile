# Ubuntu 22.04 Jammy
FROM ubuntu:22.04

# ENV
ENV DEBIAN_FRONTEND noninteractive
ENV USER dora
ENV HOSTNAME localhost
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

# Install packages
RUN apt-get update
RUN apt-get install -yyq build-essential bison flex gnupg libncurses-dev libelf-dev libssl-dev wget sudo curl git

RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

# Install repo
RUN set -x \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && chmod a+x /usr/local/bin/repo

# Link Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

# Clean APT
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
RUN git config --global color.ui false

ENTRYPOINT ["/bin/bash"]
