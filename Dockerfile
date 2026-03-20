FROM mcr.microsoft.com/devcontainers/base:jammy

USER vscode

# install: claude code
RUN curl -fsSL https://claude.ai/install.sh | bash

USER root

# install: 
#   yq
RUN wget https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_amd64 -O /usr/local/bin/yq &&\
    chmod +x /usr/local/bin/yq

COPY rootfs/ /
RUN chown -R vscode:vscode /home/vscode
RUN find /usr/local/bin -type f -exec chmod +x {} \;

USER vscode

CMD ["sleep", "infinity"]
