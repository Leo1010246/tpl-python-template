# base stage
FROM python:3.11-slim AS base

ENV PULSE_SERVER=unix:/run/user/1000/pulse/native

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN if getent group $USER_GID; then \
        groupmod -n $USERNAME $(getent group $USER_GID | cut -d: -f1);\
    else \
        groupadd --gid $USER_GID $USERNAME; \
    fi \
    && if getent passwd $USER_UID; then \
        usermod -l $USERNAME -g $USER_GID -m -d /home/$USERNAME $(getent passwd $USER_UID | cut -d: -f1); \
    else \
        useradd --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
    
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglx-mesa0 \
    libgl1-mesa-dri \
    libglu1-mesa \
    libvulkan1 \
    mesa-vulkan-drivers \
    pulseaudio \
    libpulse0 \
    libasound2 \
    libasound2-plugins \
    alsa-utils \
    && rm -rf /var/lib/apt/lists/*
    
RUN python3 -m pip install --no-cache-dir pip-tools --break-system-packages

WORKDIR /app

RUN chown $USERNAME:$USER_GID /app

# dev stage
FROM base AS dev

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    curl \
    vim \
    htop \
    x11-apps \
    mesa-utils \
    vulkan-tools \
    pulseaudio-utils \
    freeglut3-dev \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME

COPY --chown=$USERNAME:$USER_GID pyproject.toml README.md ./

RUN python3 -m piptools compile --extra dev --strip-extras -o requirements.txt pyproject.toml
RUN python3 -m pip install --user --break-system-packages -r requirements.txt

RUN find . -maxdepth 1 ! -name '.' ! -name '..' -delete

CMD ["/bin/bash"]

# app stage
FROM base AS app

USER $USERNAME

COPY --chown=$USERNAME:$USER_GID . .

RUN python3 -m piptools compile --extra dev --strip-extras -o requirements.txt pyproject.toml
RUN python3 -m pip install --user --break-system-packages -r requirements.txt

RUN pip install -e .

ENV PATH="/home/user/.local/bin:${PATH}"

ENTRYPOINT ["sh", "-c", "$PKG_SCRIPT"]
