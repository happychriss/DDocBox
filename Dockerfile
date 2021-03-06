#This file will create the base-image for a RPI to run Docbox on an ARM Architecture
# Build process is using quemu for cress plattform build:
#https://github.com/moul/docker-binfmt-register/blob/master/Dockerfile
#https://blog.hypriot.com/post/setup-simple-ci-pipeline-for-arm-images/
#To run on x64:
#docker run --rm --privileged multiarch/qemu-user-static:register --reset > qemu-arm-static
FROM resin/rpi-raspbian:stretch as builder
RUN [ "cross-build-start" ]
RUN apt-get update -qq && apt-get install -y apt-utils
RUN apt-get install -y \
    apt-utils \
    git \
    cmake \
    make \
    g++ \
    bison \
    flex \
    mariadb-client \
    build-essential \
    libmariadbclient-dev \
    libmariadbclient18
RUN mkdir /build && cd /build \
&& git clone https://github.com/manticoresoftware/manticore.git --single-branch \
&& cd manticore && git checkout tags/2.6.3 \
&& mkdir -p build && cd build \
&& cmake \
    -D SPLIT_SYMBOLS=1 \
    -D WITH_MYSQL=ON \
    -D DL_MYSQL=0 \
    -D WITH_PGSQL=OFF \
    -D WITH_RE2=ON \
    -D WITH_STEMMER=ON \
    -D DISABLE_TESTING=ON \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CONFFILEDIR=/etc/sphinxsearch \
    -D SPHINX_TAG=release .. \
&& make -j4 searchd indexer indextool
RUN [ "cross-build-end" ]
FROM resin/rpi-raspbian:stretch
RUN [ "cross-build-start" ]
COPY --from=builder /build/manticore/build/src/indexer /usr/bin/
COPY --from=builder /build/manticore/build/src/indextool /usr/bin/
COPY --from=builder /build/manticore/build/src/searchd /usr/bin/
#COPY --from=builder /build/manticore/build/src/sphinx.conf /etc/sphinxsearch/sphinx.conf
#VOLUME /var/lib/manticore /etc/sphinxsearch
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs ruby ruby-dev \
    libavahi-compat-libdnssd-dev nginx libmariadbclient-dev git avahi-daemon avahi-utils nano dbus libnss-mdns \
    imagemagick poppler-utils unpaper tesseract-ocr tesseract-ocr-deu html2ps exactimage oracle-java8-jdk \
    less sane sane-utils wget ghostscript usbutils
RUN gem install bundler
RUN mkdir /gem_tmp
ADD DBServer/Gemfile /gem_tmp/Gemfile_DBServer
ADD DBServer/Gemfile.lock /gem_tmp/Gemfile_DBServer.lock
ADD DBDaemon/Gemfile /gem_tmp/Gemfile_DBDaemon
ADD DBDaemon/Gemfile.lock /gem_tmp/Gemfile_DBDaemon.lock
RUN bundle install --gemfile=/gem_tmp/Gemfile_DBServer
RUN bundle install --gemfile=/gem_tmp/Gemfile_DBDaemon
WORKDIR /docbox
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/vc/lib
#COPY DBDaemon DBDaemon
#COPY DBServer DBServer
### Install Scanner
RUN mkdir /usr/share/sane/epjitsu
RUN wget https://www.josharcher.uk/static/files/2016/10/1300_0C26.nal
RUN mv 1300_0C26.nal /usr/share/sane/epjitsu
RUN [ "cross-build-end" ]