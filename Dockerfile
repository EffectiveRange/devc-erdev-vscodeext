FROM mcr.microsoft.com/devcontainers/typescript-node:20-trixie

ARG PACKAGING_TOOLS_VER=latest
ENV PACKAGING_TOOLS_VER=${PACKAGING_TOOLS_VER}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends python3-setuptools ca-certificates dumb-init openssh-server cmake gcc gdb curl wget dos2unix apt-transport-https libasound2  libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf-xlib-2.0-0 libgtk-3-0 libgbm-dev libnss3-dev libxss-dev python3-pip python3-packaging xvfb x11-xserver-utils xauth gnupg

RUN wget -O- https://raw.githubusercontent.com/EffectiveRange/infrastructure-configuration/refs/heads/main/aptrepo/repository/add_repo.sh 2>/dev/null | /bin/bash

RUN apt-get -y install --no-install-recommends rubygems && gem install --no-document fpm

RUN . /etc/os-release && \
    if [ "${PACKAGING_TOOLS_VER}" = "latest" ]; then \
        apt install -y packaging-tools; \
    else \
        wget -O /tmp/packaging-tools.deb \
        "https://github.com/EffectiveRange/packaging-tools/releases/download/${PACKAGING_TOOLS_VER}/${VERSION_CODENAME}_packaging-tools_${PACKAGING_TOOLS_VER#v}-1_all.deb" && \
        apt install -y /tmp/packaging-tools.deb && \
        rm -f /tmp/packaging-tools.deb; \
    fi

RUN mkdir -p /var/run/sshd && passwd -d node

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# Enable passwordless SSH login
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

RUN install -d -m 0755 /usr/share/keyrings; curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg; \
    chmod 0644 /usr/share/keyrings/microsoft-archive-keyring.gpg;

RUN  cat <<EOF > /etc/apt/sources.list.d/vscode.sources 
Types: deb
URIs: https://packages.microsoft.com/repos/vscode
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft-archive-keyring.gpg
EOF

  
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /usr/share/keyrings/githubcli-archive-keyring.gpg; \
  chmod 0644 /usr/share/keyrings/githubcli-archive-keyring.gpg;

RUN cat <<EOF > /etc/apt/sources.list.d/github-cli.sources 
Types: deb
URIs: https://cli.github.com/packages
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/githubcli-archive-keyring.gpg
EOF

RUN  apt-get update;  apt-get install -y --no-install-recommends code gh; 

RUN mkdir -p /home/node/.ssh

RUN ssh-keygen -b 2048 -t rsa -f /home/node/.ssh/id_rsa -q -N ""

RUN cat <<EOF > /home/node/.ssh/config
Host rpi-dev.local
  HostName localhost

Host rpi2.local
  HostName localhost
  IdentityFile ~/.ssh/id_rsa
EOF
RUN chown -R node:node /home/node/.ssh

# Runs "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
