FROM resin/rpi-raspbian:jessie-20160401
ENV PATH /opt/elixir/bin:$PATH
ENV LANG C.UTF-8
ENV MIX_ENV production
RUN apt-get update && apt-get install -y \
    tree \
    curl \
    unzip \
    git \
    ca-certificates \
  && echo "deb http://packages.erlang-solutions.com/debian wheezy contrib" >> /etc/apt/sources.list \
  && curl 'http://packages.erlang-solutions.com/debian/erlang_solutions.asc' -o 'esolutions.asc' \
  && apt-key add esolutions.asc \
  && rm esolutions.asc \
  && apt-get update \
  && apt-get install -y --force-yes erlang-mini \
  && mkdir /opt/elixir \
  && curl -k -L https://github.com/elixir-lang/elixir/releases/download/v1.2.4/Precompiled.zip -o /opt/elixir/precompiled.zip \
  && cd /opt/elixir \
  && unzip precompiled.zip \
  && mix local.hex --force \
  && mix local.rebar --force \
  && rm -rf /var/lib/apt/lists/*
COPY . /app
WORKDIR /app
RUN mix hex.registry fetch && mix deps.get && mix compile
CMD modprobe w1-gpio && modprobe w1-therm && elixir --name "homebody@$(hostname).local" --cookie pi -S mix run --no-halt --no-deps-check
