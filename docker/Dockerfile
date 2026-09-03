FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Metropolis demo needs XeLaTeX, Beamer, pgfplots, ccicons, and latexmk.
RUN apt-get update -q \
 && apt-get install -y --no-install-recommends \
        make \
        latexmk \
        wget \
        unzip \
        ca-certificates \
        fontconfig \
        texlive-xetex \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-fonts-extra \
 && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 does not package Fira Sans/Mono. Use Mozilla's OpenType release.
RUN wget -q -O /tmp/fira.zip https://github.com/mozilla/Fira/archive/refs/tags/4.202.zip \
 && unzip -q /tmp/fira.zip -d /tmp \
 && mkdir -p /usr/local/share/fonts/fira \
 && find /tmp/Fira-4.202 -name '*.otf' -exec cp {} /usr/local/share/fonts/fira/ \; \
 && fc-cache -f \
 && rm -rf /tmp/fira.zip /tmp/Fira-4.202

WORKDIR /data
