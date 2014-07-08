FROM sameersbn/ubuntu:14.04.20140628
MAINTAINER stefano.travelli@entaksi.eu

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list  && \
  echo "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/sources.list

# install postgre and nginx
RUN apt-get update && \
    apt-get -q -y install nginx-core openjdk-7-jre && \
    mkdir -p /var/cache/nginx/alfresco  && \
    chown -R www-data:www-data /var/cache/nginx


ADD assets /
RUN chmod 755 /opt/alfresco/setup/*.sh && chmod 755 /opt/alfresco/bin/*.sh

# install all the other components
RUN /opt/alfresco/setup/install.sh

RUN apt-get clean

VOLUME [/opt/alfresco/data]

# http tomcat and via nginx
EXPOSE 80 443 8080 8443
# cifs
EXPOSE 1143 1445 1139 1137 1138
# ftp
EXPOSE 2021 35000 35001 35002 35003 35004 35005 35006 35007 35008 35009
CMD ["/opt/alfresco/bin/init.sh"]


