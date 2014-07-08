# Alfresco base image 

This image provides a base installation for Alfresco Community. The image contains:

* All Alfresco dependencies: Tomcat, Libreoffice, SwfTools (is this still needed in version 5?), ImageMagick
* Basic version of Alfresco Repository and Alfresco Share (that is: no extra modules applied)
* Solr as search engine
* Nginx

The building process is inspired by https://github.com/loftuxab/alfresco-ubuntu-install by http://loftux.se/ and 
some artifacts are copied from that work (the nginx maintenance page, for instance).

Warning: this image is work in progress. Don't rely on it until this notice appears.

Alfresco has tons of configuration parameters. We manage a few of them, described below.
 
## Database 

TODO

## Outgoing mail

TODO

## FTP

TODO
 
## Context root

TODO





