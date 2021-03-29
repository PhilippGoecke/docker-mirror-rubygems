docker build -t rubygems-mirror:0.1 -f Dockerfile .
mkdir /tmp/rubygems
docker run --interactive --tty --volume /tmp/rubygems:/home/gems/rubygems rubygems-mirror:0.1
