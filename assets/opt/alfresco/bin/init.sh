#!/bin/bash
set -e

ALF_HOME=/opt/alfresco
ALF_BIN=$ALF_HOME/bin
ALF_SETUP=$ALF_HOME/setup
CATALINA_HOME=$ALF_HOME/tomcat
LOCALESUPPORT=it_IT.utf8

ALFRESCO_CONTEXT=${ALFRESCO_CONTEXT:-}

# ensure the context has a trailing slash or nothing
if [[ $ALFRESCO_CONTEXT == /* ]]; then ALFRESCO_CONTEXT=$ALFRESCO_CONTEXT; else ALFRESCO_CONTEXT=/$ALFRESCO_CONTEXT; fi
if [[ $ALFRESCO_CONTEXT == / ]];
then
# no context
  ALFRESCO_CONTEXT=
  ALFRESCO_CONTEXT_WITH_DASHES=
else
# this is the context with a trailing slash
  ALFRESCO_CONTEXT=$ALFRESCO_CONTEXT;
# replace slash with dash
  ALFRESCO_CONTEXT_WITH_DASHES=`echo $ALFRESCO_CONTEXT | sed s,/,#,g`
# remove first dash. This is the context with dash instead of slash, no trailing dash and tailing dash
  ALFRESCO_CONTEXT_WITH_DASHES=${ALFRESCO_CONTEXT_WITH_DASHES#"#"}\#
fi


DB_USERNAME=${DB_USERNAME:-alfresco}
DB_PASSWORD=${DB_PASSWORD:-a1l2f3r4e5s6c7o}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_DATABASE=${DB_DATABASE:-alfresco}

SHARE_HOSTNAME=${SHARE_HOSTNAME:-`hostname`}
SHARE_PROTOCOL=${SHARE_PROTOCOL:-https}
SHARE_PORT=${SHARE_PORT:-80}
if [ "${SHARE_PROTOCOL,,}" = "https" ]; then
  SHARE_PORT=${SHARE_PORT:-443}
else
  SHARE_PORT=${SHARE_PORT:-80}
fi
REPO_HOSTNAME=${REPO_HOSTNAME:-`hostname`}

MAIL_SMTP_HOST=${MAIL_SMTP_HOST:-localhost}
MAIL_SMTP_PORT=${MAIL_SMTP_PORT:-25}
MAIL_SMTP_USERNAME=${MAIL_SMTP_USERNAME:-}
MAIL_SMTP_PASSWORD=${MAIL_SMTP_PASSWORD:-}
MAIL_FROM=${MAIL_FROM:-demo@alfresco.org}
MAIL_PROTOCOL=${MAIL_PROTOCOL:-smtp}
MAIL_SMTP_AUTH=${MAIL_SMTP_AUTH:-false}
MAIL_SMTP_STARTTLS=${MAIL_SMTP_STARTTLS:-false}
MAIL_SMTPS_AUTH=${MAIL_SMTPS_AUTH:-false}
MAIL_SMTPS_STARTTLS=${MAIL_SMTPS_STARTTLS:-false}

FTP_ENABLED=${FTP_ENABLED:-false}
FTP_PORT=${FTP_PORT:-2021}
FTP_DATAPORT_FROM=${FTP_DATAPORT_FROM:-35000}
FTP_DATAPORT_TO=${FTP_DATAPORT_TO:-35009}
FTP_KEYSTORE=${FTP_KEYSTORE:-}
FTP_KEYSTORE_TYPE=${FTP_KEYSTORE_TYPE:-}
FTP_KEYSTORE_PASSPHRASE=${FTP_KEYSTORE_PASSPHRASE:-}
FTP_TRUSTSTORE=${FTP_TRUSTSTORE:-$FTP_KEYSTORE}
FTP_TRUSTSTORE_TYPE=${FTP_TRUSTSTORE_TYPE:-$FTP_KEYSTORE_TYPE}
FTP_TRUSTSTORE_PASSPHRASE=${FTP_TRUSTSTORE_PASSPHRASE:-$FTP_KEYSTORE_PASSPHRASE}
FTP_REQUIRE_SECURE_SESSION=${FTP_REQUIRE_SECURE_SESSION:-false}


tweak_tomcat() {
  cp $ALF_SETUP/server.xml $CATALINA_HOME/conf/server.xml
  cp $ALF_SETUP/catalina.properties $CATALINA_HOME/conf/catalina.properties
  cp $ALF_SETUP/tomcat-users.xml $CATALINA_HOME/conf/tomcat-users.xml

  mkdir -p $CATALINA_HOME/conf/Catalina/localhost
  rm -f $CATALINA_HOME/conf/Catalina/localhost/*.xml

  cat > $CATALINA_HOME/conf/Catalina/localhost/solr.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
  <Context docBase="$ALF_HOME/deploy/solr.war" debug="0" crossContext="true">
  <Environment name="solr/home" type="java.lang.String" value="$ALF_HOME/solr" override="true"/>
</Context>
EOF

  cat > $CATALINA_HOME/conf/Catalina/localhost/${ALFRESCO_CONTEXT_WITH_DASHES}alfresco.xml <<EOF
<Context docBase="$ALF_HOME/deploy/alfresco.war" reloadable="true">
</Context>
EOF

  cat > $CATALINA_HOME/conf/Catalina/localhost/${ALFRESCO_CONTEXT_WITH_DASHES}share.xml <<EOF
<Context docBase="$ALF_HOME/deploy/share.war" reloadable="true">
</Context>
EOF

}

tweak_alfresco() {
  ALFRESCO_GLOBAL_PROPERTIES=$CATALINA_HOME/shared/classes/alfresco-global.properties
  cp $ALF_SETUP/alfresco-global.properties $ALFRESCO_GLOBAL_PROPERTIES

  sed -i "s/@@DB_USERNAME@@/$DB_USERNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@DB_PASSWORD@@/$DB_PASSWORD/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@DB_HOST@@/$DB_HOST/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@DB_PORT@@/$DB_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@DB_DATABASE@@/$DB_DATABASE/g" $ALFRESCO_GLOBAL_PROPERTIES

  sed -i "s/@@SHARE_HOSTNAME@@/$SHARE_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@SHARE_PROTOCOL@@/$SHARE_PROTOCOL/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@SHARE_PORT@@/$SHARE_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@REPO_HOSTNAME@@/$REPO_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES

  sed -i "s/@@MAIL_SMTP_HOST@@/$MAIL_SMTP_HOST/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTP_PORT@@/$MAIL_SMTP_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTP_USERNAME@@/$MAIL_SMTP_USERNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTP_PASSWORD@@/$MAIL_SMTP_PASSWORD/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_FROM@@/$MAIL_FROM/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_PROTOCOL@@/$MAIL_PROTOCOL/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTP_AUTH@@/$MAIL_SMTP_AUTH/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTP_STARTTLS@@/$MAIL_SMTP_STARTTLS/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTPS_AUTH@@/$MAIL_SMTPS_AUTH/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@MAIL_SMTPS_STARTTLS@@/$MAIL_SMTPS_STARTTLS/g" $ALFRESCO_GLOBAL_PROPERTIES

  sed -i "s/@@FTP_ENABLED@@/$FTP_ENABLED/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_PORT@@/$FTP_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_DATAPORT_FROM@@/$FTP_DATAPORT_FROM/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_DATAPORT_TO@@/$FTP_DATAPORT_TO/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_KEYSTORE@@/$FTP_KEYSTORE/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_KEYSTORE_TYPE@@/$FTP_KEYSTORE_TYPE/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_KEYSTORE_PASSPHRASE@@/$FTP_KEYSTORE_PASSPHRASE/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_TRUSTSTORE@@/$FTP_TRUSTSTORE/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_TRUSTSTORE_TYPE@@/$FTP_TRUSTSTORE_TYPE/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_TRUSTSTORE_PASSPHRASE@@/$FTP_TRUSTSTORE_PASSPHRASE/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@FTP_REQUIRE_SECURE_SESSION@@/$FTP_REQUIRE_SECURE_SESSION/g" $ALFRESCO_GLOBAL_PROPERTIES

  sed -i "s/@@ALFRESCO_CONTEXT@@/$ALFRESCO_CONTEXT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@ALFRESCO_SHARE_SERVER@@/$SHARE_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@ALFRESCO_SHARE_SERVER_PORT@@/$SHARE_PORT/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@ALFRESCO_SHARE_SERVER_PROTOCOL@@/$SHARE_PROTOCOL/g" $ALFRESCO_GLOBAL_PROPERTIES
  sed -i "s/@@ALFRESCO_REPO_SERVER@@/$REPO_HOSTNAME/g" $ALFRESCO_GLOBAL_PROPERTIES

  SHARE_CONFIG_CUSTOM=$CATALINA_HOME/shared/classes/alfresco/web-extension/share-config-custom.xml
  cp $ALF_SETUP/share-config-custom.xml $SHARE_CONFIG_CUSTOM

  sed -i "s/@@ALFRESCO_CONTEXT@@/$ALFRESCO_CONTEXT/g" $SHARE_CONFIG_CUSTOM
  sed -i "s/@@ALFRESCO_SHARE_SERVER@@/$SHARE_HOSTNAME/g" $SHARE_CONFIG_CUSTOM
  sed -i "s/@@ALFRESCO_REPO_SERVER@@/$REPO_HOSTNAME/g" $SHARE_CONFIG_CUSTOM

  SOLR_ARCHIVE_PROPERTIES=$ALF_HOME/solr/archive-SpacesStore/conf/solrcore.properties
  cp $ALF_SETUP/archive-solrcore.properties $SOLR_ARCHIVE_PROPERTIES
  sed -i "s,@@ALFRESCO_SOLR_DIR@@,$ALF_HOME/alf_data/solr,g" $SOLR_ARCHIVE_PROPERTIES
  sed -i "s,@@ALFRESCO_CONTEXT@@,$ALFRESCO_CONTEXT,g" $SOLR_ARCHIVE_PROPERTIES

  SOLR_WORKSPACE_PROPERTIES=$ALF_HOME/solr/workspace-SpacesStore/conf/solrcore.properties
  cp $ALF_SETUP/workspace-solrcore.properties $SOLR_WORKSPACE_PROPERTIES
  sed -i "s,@@ALFRESCO_SOLR_DIR@@,$ALF_HOME/alf_data/solr,g" $SOLR_WORKSPACE_PROPERTIES
  sed -i "s,@@ALFRESCO_CONTEXT@@,$ALFRESCO_CONTEXT,g" $SOLR_WORKSPACE_PROPERTIES

}


tweak_tomcat
tweak_alfresco

JVM_HEAP=${JVM_HEAP:-2G}

export JAVA_OPTS="-Xmx$JVM_HEAP -Xss1024k -XX:MaxPermSize=256m"
export JAVA_OPTS="${JAVA_OPTS} -Duser.country=IT -Duser.region=IT -Duser.language=it -Duser.timezone=\"Europe/Rome\" -d64"
export JAVA_OPTS="${JAVA_OPTS} -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
export JAVA_OPTS="${JAVA_OPTS} -Dalfresco.home=${ALF_HOME} -Dcom.sun.management.jmxremote=true"

# start supervisor
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf

if [ "${DB_HOST}" == "localhost" ]; then
    /etc/init.d/postgresql start
fi

sudo -u alfresco $CATALINA_HOME/bin/catalina.sh run



