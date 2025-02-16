# ZoneMinder

FROM ubuntu:trusty
MAINTAINER Richard Silver<richard@zettabyte.me>

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Resynchronize the package index files
RUN apt-get update && apt-get install -y \
	libpolkit-gobject-1-dev build-essential libmysqlclient-dev libssl-dev libbz2-dev libpcre3-dev \
	libdbi-perl libarchive-zip-perl libdate-manip-perl libdevice-serialport-perl libmime-perl libpcre3 \
	libwww-perl libdbd-mysql-perl libsys-mmap-perl yasm cmake libjpeg-turbo8-dev \
	libjpeg-turbo8 libtheora-dev libvorbis-dev libvpx-dev libx264-dev libmp4v2-dev libav-tools mysql-client \
	apache2 php5 php5-mysql apache2-mpm-prefork libapache2-mod-php5 php5-cli \
	mysql-server libvlc-dev libvlc5 libvlccore-dev libvlccore7 vlc-data libcurl4-openssl-dev \
	libavformat-dev libswscale-dev libavutil-dev libavcodec-dev libavfilter-dev \
	libavresample-dev libavdevice-dev libpostproc-dev libv4l-dev libtool libnetpbm10-dev \
	libmime-lite-perl dh-autoreconf dpatch php5-dev nano dh-make-php git && \
	pecl install timezonedb && apt-get clean && \
  rm -rf /tmp/* /var/tmp/* && rm -rf /var/lib/apt/lists/*

# installed the timezonedb cuz php is stupid and zoneminder is even dumber for it's weird folder structure

# Copy local code into our container
RUN git clone https://github.com/ZoneMinder/ZoneMinder.git /ZoneMinder

# Change into the ZoneMinder directory
WORKDIR /ZoneMinder

RUN git submodule update --init --recursive && cmake .

# Build ZoneMinder
RUN make

# Install ZoneMinder
RUN make install

# ensure writable folders
RUN ./zmlinkcontent.sh

# Fix cgi-bin missing link
#RUN ln -s /ZoneMinder/src/nph-zms /usr/lib/cgi-bin/
RUN ln -s /usr/local/share/zoneminder/www /var/www/zm
#without this the folder structure will be created wrong passing the TZ env doesn't fix
RUN echo "America/Los_Angeles" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
# Adding the start script
ADD utils/docker/start.sh /tmp/start.sh

# Adding the start script
ADD utils/docker/start.sh /tmp/start.sh

# Ensure we can run this
# TODO - Files ADD'ed have 755 already...why do we need this?
RUN chmod 755 /tmp/start.sh

# give files in /usr/local/share/zoneminder/
RUN chown -R www-data:www-data /usr/local/share/zoneminder/

# Adding apache virtual hosts file
ADD utils/docker/apache-vhost /etc/apache2/sites-available/000-default.conf
ADD utils/docker/phpdate.ini /etc/php5/apache2/conf.d/25-phpdate.ini

ADD utils/docker/db_init.sh /ZoneMinder/utils/docker/db_init.sh
RUN utils/docker/db_init.sh

# Set the root passwd
RUN echo 'root:root' | chpasswd

# Add a user we can actually login with
RUN useradd -m -s /bin/bash -G sudo zoneminder
RUN echo 'zoneminder:zoneminder' | chpasswd

EXPOSE 80

CMD "/tmp/start.sh"
