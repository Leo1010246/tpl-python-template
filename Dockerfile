# base stage
FROM python:3.11-slim AS base

ENV PULSE_SERVER=unix:/run/user/1000/pulse/native

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
    
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libglu1-mesa \
    pulseaudio \
    libasound2 \
    libasound2-plugins \
    alsa-utils \
    && rm -rf /var/lib/apt/lists/*
    
RUN pip install --no-cache-dir pip-tools

WORKDIR /app

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
    pulseaudio-utils \
    freeglut3-dev \
    && rm -rf /var/lib/apt/lists/*

USER $USERNAME

COPY --chown=$USERNAME:$USER_GID pyproject.toml README.md ./

RUN pip-compile --extra dev -o requirements.txt pyproject.toml
RUN pip install -r requirements.txt

RUN find . -maxdepth 1 ! -name '.' ! -name '..' -delete

CMD ["/bin/bash"]

# app stage
FROM base AS app

USER $USERNAME

COPY --chown=$USERNAME:$USER_GID . .

RUN pip-compile -o requirements.txt pyproject.toml
RUN pip install -r requirements.txt

ENTRYPOINT ["python", "."]
