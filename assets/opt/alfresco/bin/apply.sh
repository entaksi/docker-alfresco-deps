#!/bin/bash
# -------
# Script for apply AMPs to installed WAR
# 
# Copyright 2013 Loftux AB, Peter Löfgren
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------
export JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64/"
export JRE_HOME=$JAVA_HOME/jre
export PATH=$PATH:$HOME/bin:$JRE_HOME/bin
export ALF_HOME=/opt/alfresco
export MMT_JAR=$ALF_HOME/lib/alfresco-mmt.jar
export CATALINA_HOME=$ALF_HOME/tomcat
export CATALINA_PID="${ALF_HOME}/tomcat.pid"
export USER=alfresco

cd $ALF_HOME/addons

#Create directories if not exist
if [ ! -d "share" ]; then
	mkdir share
fi
if [ ! -d "alfresco" ]; then
	mkdir alfresco
fi
if [ ! -d "war" ]; then
	mkdir war
fi

amp(){
if [ -e war/alfresco.war ]; then
	if [ -e alfresco.war ]; then
		rm alfresco.war
	fi
	cp war/alfresco.war .
	# Use ls listing instead of -directory option, that way we can control order amps is applied
	for file in `ls -v alfresco/*.amp`;
	do
  	if [[ ! -f "$file" ]]
  		then
    	continue
  	fi
  		echo "Applying $file"
		java -jar $MMT_JAR install $file alfresco.war -force -nobackup
	done
	
else
	echo "Skipping alfresco.war - not present in war directory"
fi
if [ -e war/share.war ]; then
	if [ -e share.war ]; then
		rm share.war
	fi
	cp war/share.war .
	# Use ls listing instead of -directory option, that way we can control order amps is applied
	for file in `ls -v share/*.amp`;
	do
  	if [[ ! -f "$file" ]]
  		then
    	continue
  	fi
  		echo "Applying $file"
		java -jar $MMT_JAR install $file share.war -force -nobackup
	done
else
	echo "Skipping share.war - not present in war directory"
fi

# List the installed war files
if [ -e alfresco.war ]; then
	java -jar $MMT_JAR list alfresco.war
fi
if [ -e share.war ]; then
	java -jar $MMT_JAR list share.war
fi
}

copy(){
	echo "------------------------"
	echo "Copying new war files..."
        SHUTDOWN_PORT=`netstat -vatn|grep LISTEN|grep 8005|wc -l`
        export JAVA_HOME=$JAVA_HOME
        if [ $SHUTDOWN_PORT -ne 0 ]; then
            echo "Alfresco is started, cannot copy while started"
        else
            if [ -e $CATALINA_PID ]; then
				echo "The process id file ${CATALINA_PID} exist even if Alfresco is not started."
				echo "This can happen with an unexpected shutdown or if you run this startup script twice before tomcat is fully started."
				echo "You need to manually remove this file if you are shure Alfresco tomcat is not running before copying again."
			else
				if [ -e $ALF_HOME/deploy/alfresco.war.old ]; then
					rm $ALF_HOME/deploy/alfresco.war.old
				fi
				if [ -e alfresco.war ]; then
					if [ -e $ALF_HOME/deploy/alfresco.war ]; then
						echo "Backing up existing alfresco.war"
						mv $ALF_HOME/deploy/alfresco.war $ALF_HOME/deploy/alfresco.war.old
					fi
					echo "Moving new alfresco.war to tomcat..."
					mv alfresco.war $ALF_HOME/deploy/alfresco.war
				fi
				if [ -e $ALF_HOME/deploy/share.war.old ]; then
					rm $ALF_HOME/deploy/share.war.old
				fi
				if [ -e share.war ]; then
					if [ -e $ALF_HOME/deploy/share.war ]; then
						echo "Backing up existing share.war"
						mv $ALF_HOME/deploy/share.war $ALF_HOME/deploy/share.war.old
					fi
					echo "Moving new share.war to tomcat..."
					mv share.war $ALF_HOME/deploy/share.war
				fi
				echo "Cleaning temporary Alfresco files from Tomcat..."
				rm -rf ${CATALINA_HOME}/temp/Alfresco
				rm -rf ${CATALINA_HOME}/work/Catalina/localhost
				rm -rf ${CATALINA_HOME}/webapps/*
				echo "Restoring permissions on Tomcat"
				chown -R ${USER}:nogroup ${CATALINA_HOME}
            fi
        fi
}

case "$1" in
	amp)
    	amp
    	;;
    copy)
        copy
        ;;
    all)
    	amp
    	copy
    	;;
    *)
      	echo "Apply amps to war files"
      	echo "Put amp files in share and alfresco respectively. Put alfresco.war and share.war in source"
      	echo "Completed war files will be put in ${PWD}"
      	echo " amp: Merge amp files into war files"
      	echo " copy: Copy the new war files to tomcat"
      	echo " all: Run amp and copy targets"
        echo "Usage: $0 {amp|copy|all}"
        exit 1
    esac