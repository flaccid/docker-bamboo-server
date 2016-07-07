FROM debian:jessie

MAINTAINER Chris Fordham <chris@fordham-nagy.id.au>

ENV BAMBOO_VERSION 5.12.2.1

# download this from Oracle first, see vendor link in:
# https://wiki.debian.org/JavaPackage
#   NOTE: destination filename must match the original convention
#         for make-jpkg to support it
COPY jdk-8u91-linux-x64.tar.gz /tmp/

ADD https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz /tmp/atlassian-bamboo.tar.gz

# TODO: work out which packages can be removed without removing the
#       oracle java package built and installed
RUN cd /tmp && \
    tar zxvf atlassian-bamboo.tar.gz && \
    sed -i 's/.*jessie main.*/deb http:\/\/httpredir.debian.org\/debian\/ jessie main contrib/' /etc/apt/sources.list && \
    ephemeral_pkgs='fakeroot java-package libgl1-mesa-glx libgtk2.0-0 libxslt1.1 libxtst6 libxxf86vm1' && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install $ephemeral_pkgs && \
    chsh -s /bin/sh nobody && \
    su -c 'echo y | fakeroot make-jpkg jdk-8u91-linux-x64.tar.gz' nobody && \
    chsh -s /usr/sbin/nologin nobody && \
    dpkg -i oracle-java8-jdk*.deb && \
    update-alternatives --auto java && \
    apt-get -y clean && \
    tmp_extracted=$(ls /tmp | grep atlassian-bamboo- | head -n 1) && \
    mv -v "$tmp_extracted" /opt/bamboo && \
    sed -i 's/.*bamboo.home.*/bamboo.home= \/var\/opt\/bamboo\/home/' \
        /opt/bamboo/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties && \
      rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /opt/bamboo
VOLUME /var/opt/bamboo/home

EXPOSE 8085

WORKDIR /opt/bamboo
CMD ["bin/start-bamboo.sh", "-fg"]
