FROM quay.io/jupyter/base-notebook@sha256:876e3c3e40c4f0a25d3a16223a158a2d582b1ad77ac94269d43a5f6256eb4eec

USER root

RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        # xclip is added as jupyter-remote-desktop-proxy's tests requires it
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
    # Disable the automatic screenlock since the account password is unknown
 && apt-get -y -qq remove xfce4-screensaver \
    # chown $HOME to workaround that the xorg installation creates a
    # /home/jovyan/.cache directory owned by root
    # Create /opt/install to ensure it's writable by pip
 && mkdir -p /opt/install \
 && chown -R $NB_UID:$NB_GID $HOME /opt/install

ENV NVIDIA_VISIBLE_DEVICES="all"
ENV NVIDIA_DRIVER_CAPABILITIES="all"
ENV PATH=/opt/TurboVNC/bin:/opt/VirtualGL/bin:$PATH

ARG VIRTUALGL_VERSION=3.1.1
RUN wget -q "https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb" -O virtualgl.deb \
 && apt-get install -y -q ./virtualgl.deb \
 && rm ./virtualgl.deb
RUN /opt/VirtualGL/bin/vglserver_config +glx +egl +s +f +t

ARG TURBOVNC_VERSION=3.1.1
RUN wget -q "https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb" -O turbovnc.deb \
 && apt-get install -y -q ./turbovnc.deb \
    # remove light-locker to prevent screen lock
 && apt-get remove -y -q light-locker \
 && rm ./turbovnc.deb \
 && rm -rf /var/lib/apt/lists/*

USER $NB_USER

# Install the environment first, and then install the package separately for faster rebuilds
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN . /opt/conda/bin/activate && \
    mamba env update --quiet --file /tmp/environment.yml

COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN . /opt/conda/bin/activate && \
    pip install /opt/install
