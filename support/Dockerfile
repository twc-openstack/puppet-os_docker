FROM ubuntu:trusty

RUN apt-get update && \
apt-get install --no-install-recommends -y \
  build-essential \
  ca-certificates \
  git \
  libffi-dev \
  libldap2-dev \
  libmysqlclient-dev \
  libpq-dev \
  libsasl2-dev \
  libvirt-dev \
  libxml2-dev \
  libxslt-dev \
  pkg-config \
  python-dev \
  python-virtualenv \
  rsync

RUN virtualenv /tox-venv
RUN /tox-venv/bin/pip install -U pip
RUN /tox-venv/bin/pip install tox
