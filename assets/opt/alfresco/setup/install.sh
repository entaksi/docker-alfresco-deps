#!/bin/bash
# -------
# Set up a base image with all the tools needed to run Alfresco.
#
# Inspired by Peter Löfgren install script.
#
#
# Copyright 2014 Entaksi Solutions Srl
# Copyright 2013 Loftux AB, Peter Löfgren
# -------

export ALF_HOME=/opt/alfresco
export CATALINA_HOME=$ALF_HOME/tomcat
export ALF_USER=alfresco
export APTVERBOSITY="-qq -y"


#Change this to prefered locale to make sure it exists. This has impact on LibreOffice transformations
export LOCALESUPPORT=it_IT.utf8

export TOMCAT_DOWNLOAD=http://ftp.sunet.se/pub/www/servers/apache/dist/tomcat/tomcat-7/v7.0.54/bin/apache-tomcat-7.0.54.tar.gz
export XALAN=http://svn.alfresco.com/repos/alfresco-open-mirror/alfresco/HEAD/root/projects/3rd-party/lib/xalan-2.7.0/
export JDBCPOSTGRESURL=http://jdbc.postgresql.org/download
export JDBCPOSTGRES=postgresql-9.3-1101.jdbc41.jar
export JDBCMYSQLURL=http://ftp.sunet.se/pub/unix/databases/relational/mysql/Downloads/Connector-J
export JDBCMYSQL=mysql-connector-java-5.1.30.tar.gz

export LIBREOFFICE=http://ftp.sunet.se/pub/Office/tdf/libreoffice/stable/4.2.5/deb/x86_64/LibreOffice_4.2.5_Linux_x86-64_deb.tar.gz

export SWFTOOLS=http://www.swftools.org/swftools-2013-04-09-1007.tar.gz

export ALF_WAR=https://www.entaksi.eu/maven/maintenact/org/alfresco/alfresco/5.0.a/alfresco-5.0.a.war
export SHARE_WAR=https://www.entaksi.eu/maven/maintenact/org/alfresco/share/5.0.a/share-5.0.a.war

# Stick to version 4.2.f
export SOLR=http://dl.alfresco.com/release/community/4.2.f-build-00012/alfresco-community-solr-4.2.f.zip


install_solr() {
  mkdir -p $ALF_HOME/solr
  curl -# -o $ALF_HOME/solr/solr.zip $SOLR
  cd $ALF_HOME/solr/

  sudo unzip -q solr.zip

  # Remove some unused stuff
  sudo rm $ALF_HOME/solr/solr.zip
  sudo rm -rf $ALF_HOME/solr/alf_data

}

install_libreoffice() {
  echo "Install LibreOffice."

  cd /tmp/alfrescoinstall
  curl -# -O $LIBREOFFICE
  tar xf LibreOffice*.tar.gz
  cd "$(find . -type d -name "LibreOffice*")"
  cd DEBS
  sudo dpkg -i *.deb
  echo
  echo "Installing some support fonts for better transformations."
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
  sudo apt-get $APTVERBOSITY install ttf-mscorefonts-installer fonts-droid


}

install_imagemagick() {
  echo "Installing ImageMagick..."
  apt-get $APTVERBOSITY install imagemagick ghostscript libgs-dev libjpeg62 libpng3
  echo
  IMAGEMAGICKVERSION=`ls /usr/lib/|grep -i imagemagick`
  echo "Creating symbolic link for ImageMagick."
  ln -s /usr/lib/$IMAGEMAGICKVERSION /usr/lib/ImageMagick
}

install_swftools() {
  echo "Installing build tools and libraries needed to compile swftools. Fetching packages..."
  apt-get $APTVERBOSITY install make build-essential ccache g++ libgif-dev libjpeg62-dev libfreetype6-dev libpng12-dev libt1-dev
  cd /tmp/alfrescoinstall
  echo "Downloading swftools..."
  curl -# -O $SWFTOOLS
  tar xf swftools*.tar.gz
  cd "$(find . -type d -name "swftools*")"
  ./configure
  sudo make && sudo make install
}


install_tomcat() {
  echo "Downloading tomcat..."
  curl -# -O $TOMCAT_DOWNLOAD
  # Make sure install dir exists
  mkdir -p $ALF_HOME
  echo "Extracting..."
  tar xf "$(find . -type f -name "apache-tomcat*")"
  mv "$(find . -type d -name "apache-tomcat*")" $CATALINA_HOME
  # Remove apps not needed
  rm -rf $CATALINA_HOME/webapps/*
  # Get Alfresco config
  mkdir -p $CATALINA_HOME/shared/classes/alfresco/extension
  mkdir -p $CATALINA_HOME/shared/classes/alfresco/web-extension
  mkdir -p $CATALINA_HOME/shared/lib
  # Add Xalan to endorsed
  mkdir -p $CATALINA_HOME/endorsed
  curl -# -o $CATALINA_HOME/endorsed/xalan.jar $XALAN/xalan.jar
  curl -# -o $CATALINA_HOME/endorsed/serializer.jar $XALAN/serializer.jar
  echo

  curl -# -O $JDBCPOSTGRESURL/$JDBCPOSTGRES
  mv $JDBCPOSTGRES $CATALINA_HOME/lib
}




cd /tmp
if [ -d "alfrescoinstall" ]; then
	rm -rf alfrescoinstall
fi
mkdir alfrescoinstall
cd ./alfrescoinstall

apt-get $APTVERBOSITY update;

apt-get $APTVERBOSITY install curl;

echo
echo "Creating user alfresco."
adduser --system --disabled-login --disabled-password --group $ALF_USER
echo
echo "Adding locale support"
  #install locale to support that locale date formats in open office transformations
sudo locale-gen $LOCALESUPPORT
echo

install_tomcat
install_imagemagick
install_libreoffice
install_swftools
install_solr


# Add the addons dir and scripts
mkdir -p $ALF_HOME/addons/war
mkdir -p $ALF_HOME/addons/share
mkdir -p $ALF_HOME/addons/alfresco
mkdir -p $ALF_HOME/deploy

curl -# -o $ALF_HOME/addons/war/alfresco.war $ALF_WAR
curl -# -o $ALF_HOME/addons/war/share.war $SHARE_WAR

chown -R $ALF_USER:$ALF_USER /opt/alfresco

$ALF_HOME/bin/apply.sh all





