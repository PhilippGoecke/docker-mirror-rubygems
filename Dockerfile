FROM debian:buster-slim

ENV RUBY_VERSION='2.7.2'
ENV BUNDLER_VERSION='2.2.15'

# install debian updates
RUN apt update && apt upgrade -y
# install ruby dependencies
RUN apt install -y git curl bzip2 build-essential autoconf libtool libssl-dev libreadline-dev zlib1g-dev
RUN apt install -y wget

# make image smaller
RUN rm -rf /var/lib/apt/lists/*

# switch to non-root user
ARG USER=gems
RUN adduser $USER
USER $USER
RUN whoami
# show current workdir
ARG HOME="/home/$USER"
WORKDIR $HOME
RUN pwd

# install rbenv
RUN git clone https://github.com/rbenv/rbenv.git $HOME/.rbenv
ENV PATH "$HOME/.rbenv/bin:$PATH"
RUN echo $PATH
RUN cd "$HOME/.rbenv"
RUN eval "$(rbenv init)"
RUN echo 'eval "$(rbenv init -)"' >> $HOME/.bash_profile
RUN echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc

RUN mkdir -p "$(rbenv root)"/plugins
RUN git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
ENV PATH "$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

RUN rbenv install -L | grep "$RUBY_VERSION"
RUN rbenv install $RUBY_VERSION
RUN rbenv rehash
ENV PATH "$HOME/.rbenv/shims:$PATH"
RUN echo $PATH

# use rbenv-doctor
WORKDIR $HOME
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor > rbenv-doctor.bash
RUN sha512sum rbenv-doctor.bash
RUN bash rbenv-doctor.bash

RUN rbenv local $RUBY_VERSION
RUN rbenv global $RUBY_VERSION

# Install bundler
RUN gem install bundler -v $BUNDLER_VERSION
RUN bundler --version
#RUN bundle config --global silence_root_warning 1

# set workdir
WORKDIR $HOME/rubygems

# persist data in host
VOLUME $HOME/rubygems

# set gem mirror settings (https://github.com/rubygems/rubygems-mirror)
RUN echo "---\n- from: http://rubygems.org\n  to: $HOME/rubygems\n  parallelism: 10\n  retries: 3\n  delete: false\n  skiperror: true" > $HOME/.gem/.mirrorrc

RUN gem install rubygems-mirror

RUN ls -lisah $HOME
#RUN chown -R `whoami` $HOME/rubygems
#RUN chown -R $USER $HOME/rubygems

#CMD gem mirror
ENTRYPOINT ["gem", "mirror"]
