FROM mcr.microsoft.com/devcontainers/typescript-node:1-20-bullseye

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends dumb-init openssh-server cmake gcc gdb curl wget apt-transport-https libasound2 libgconf-2-4 libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libgbm-dev libnss3-dev libxss-dev python3-pip xvfb x11-xserver-utils xauth

RUN apt-get -y install --no-install-recommends rubygems && gem install --no-document fpm


RUN mkdir /var/run/sshd && passwd -d node

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
# Enable passwordless SSH login
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config

RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
  install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/  && \
  echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
  apt-get update && \
  apt-get install -y code

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

RUN mkdir -p /home/node/.ssh
RUN cat <<EOF > /home/node/.ssh/config
Host rpi-dev.local
  HostName localhost

Host rpi2.local
  HostName localhost
EOF
RUN chown -R node:node /home/node/.ssh

# Runs "/usr/bin/dumb-init -- /my/script --with --args"
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
