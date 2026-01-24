# https://hub.docker.com/_/debian/tags?name=trixie-slim
ARG DIGEST=e711a7b30ec1261130d0a121050b4ed81d7fb28aeabcf4ea0c7876d4e9f5aca2

FROM debian:trixie-slim@sha256:${DIGEST}

ENV RUBY_VERSION='4.0.1'
ENV BUNDLER_VERSION='4.0.4'

# install debian updates
RUN apt update && apt upgrade -y \
  && apt install -y --no-install-recommends ca-certificates git curl \
  # install ruby dependencies
  && apt install -y --no-install-recommends bzip2 build-essential autoconf libtool libyaml-dev libssl-dev libreadline-dev zlib1g-dev \
  # install additional dependencies
  # && apt install -y wget \
  # make image smaller
  && rm -rf "/var/lib/apt/lists/*" \
  && rm -rf /var/cache/apt/archives \
  && rm -rf /tmp/* /var/tmp/*


# switch to non-root user
ARG USER=gems
RUN useradd --create-home --shell /bin/bash $USER
ARG HOME="/home/$USER"
WORKDIR $HOME
USER $USER
RUN whoami
RUN pwd

# install rbenv & ruby
ENV PATH "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
RUN git clone --depth 1 https://github.com/rbenv/rbenv.git "$HOME/.rbenv" \
  && echo "export PATH=\"$HOME/.rbenv/shims:$HOME/.rbenv/bin:\$PATH\"" >> ~/.bashrc \
  && rbenv init \
  && echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc \
  && mkdir -p "$(rbenv root)"/plugins \
  && git clone --depth 1 https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build \
  && rbenv install -L | grep "$RUBY_VERSION" \
  && rbenv install $RUBY_VERSION \
  && rbenv rehash

# use rbenv-doctor
WORKDIR $HOME
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-doctor > rbenv-doctor.bash \
  && sha512sum rbenv-doctor.bash \
  && bash rbenv-doctor.bash

RUN rbenv local $RUBY_VERSION
RUN rbenv global $RUBY_VERSION

# Install bundler
RUN gem install bundler -v $BUNDLER_VERSION \
  && bundler --version
#RUN bundle config --global silence_root_warning 1

# set workdir
WORKDIR $HOME/rubygems

# persist data in host
VOLUME $HOME/rubygems

# set gem mirror settings (https://github.com/rubygems/rubygems-mirror)
RUN mkdir $HOME/.gem \
  && echo "---\n- from: http://rubygems.org\n  to: $HOME/rubygems\n  parallelism: 10\n  retries: 3\n  delete: false\n  skiperror: true" > $HOME/.gem/.mirrorrc \
  && gem install rubygems-mirror

RUN ls -lisah $HOME
#RUN chown -R `whoami` $HOME/rubygems
#RUN chown -R $USER $HOME/rubygems

#CMD gem mirror
ENTRYPOINT ["gem", "mirror"]
