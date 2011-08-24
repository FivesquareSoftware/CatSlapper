#!/bin/sh

#
# Installs Tomcat 5.0.28
#


while getopts "d:e:h:b:s:t:q:u:p:" o
do 
	case "$o" in
		d) RESOURCE_PATH=$OPTARG ;;
		e) INSTALLER_ERR=$OPTARG ;;
		h) TOMCAT_BINARIES=$OPTARG ;;
		b) TOMCAT_BASE=$OPTARG ;;
		s) TOMCAT_SHUTDOWN_PORT=$OPTARG ;;
		t) TOMCAT_HTTP_PORT=$OPTARG ;;
		q) TOMCAT_AJP_PORT=$OPTARG ;;
		u) MANAGER_USER=$OPTARG ;;
		p) MANAGER_PASSWD=$OPTARG ;;
	esac
done

if [ -z "$RESOURCE_PATH" ] ; then
	echo "Resource path missing ... quitting"
	exit 1
fi

if [ -z "$INSTALLER_ERR" ] ; then
	echo "Cannot open stderr for installer ... quitting"
	exit 1
fi


{

# check env
echo -n "Validating environment"
if [ -z "$TOMCAT_BINARIES" ] ; then
	echo "TOMCAT_BINARIES must be set to install Tomcat" >&2
	exit 1
fi
if [ -z "$TOMCAT_BASE" ] ; then
	TOMCAT_BASE="$TOMCAT_BINARIES"
fi
echo "...ok"


# configure installation
# full - installing both binaries and base into same location
# base - installing just base (using binaries from elsewhere)
# split - installing binaries and base, but to different locations
echo -n "Configuring installation"
if [ "$TOMCAT_BINARIES" = "$TOMCAT_BASE" ] ; then
	INSTALL_TYPE="full"
	mkdir "$TOMCAT_BINARIES" > /dev/null 2>&1
else
	if [ ! -f "$TOMCAT_BINARIES/bin/catalina.sh" ] ; then
		INSTALL_TYPE="split"
		mkdir "$TOMCAT_BINARIES" > /dev/null 2>&1
		mkdir "$TOMCAT_BASE" > /dev/null 2>&1
	else
		INSTALL_TYPE="base"
		mkdir "$TOMCAT_BASE" > /dev/null 2>&1
	fi
fi
echo "...ok"

# validate installations
echo -n "Validating installation"
case $INSTALL_TYPE in
	full) 	if [ -f "$TOMCAT_BASE/conf/server.xml"  -o -f "$TOMCAT_BASE/bin/catalina.sh" ] ; then
				echo "Cannot install Tomcat into existing installation" >&2
				exit 1
			fi ;;
	base) 	if [ -f "$TOMCAT_BASE/conf/server.xml" ] ; then
				echo "Cannot install Tomcat into existing installation" >&2
				exit 1
			fi ;;
	split) 	if [ -f "$TOMCAT_BASE/conf/server.xml"  -o -f "$TOMCAT_BINARIES/bin/catalina.sh" ] ; then
				echo "Cannot install Tomcat into existing installation" >&2
				exit 1
			fi ;;
esac
echo "...ok"

echo "Performing a $INSTALL_TYPE installation"
echo "Using CATLINA_HOME: $TOMCAT_BINARIES"
echo "Using CATLINA_BASE: $TOMCAT_BASE"

# unpack source to tmp
echo -n "Preparing packages"
cp "$RESOURCE_PATH/jakarta-tomcat-5.0.28.tar.gz" /tmp
cd /tmp
gnutar zxf jakarta-tomcat-5.0.28.tar.gz
cd jakarta-tomcat-5.0.28
echo "...ok"


# set ports, etc.
#<Server port="8005" shutdown="SHUTDOWN" debug="0">
echo -n "Configuring Tomcat"
	if [ ! -z "$TOMCAT_SHUTDOWN_PORT" ] ; then
		sed -i .temp "s/<Server port=\"8005\"/<Server port=\"$TOMCAT_SHUTDOWN_PORT\"/" conf/server.xml
		rm -f conf/server.xml.temp
	fi
	if [ ! -z "$TOMCAT_HTTP_PORT" ] ; then
		sed -i .temp "s/<Connector port=\"8080\"/<Connector port=\"$TOMCAT_HTTP_PORT\"/" conf/server.xml
	fi
	if [ ! -z "$TOMCAT_AJP_PORT" ] ; then
		sed -i .temp "s/<Connector port=\"8009\"/<Connector port=\"$TOMCAT_AJP_PORT\"/" conf/server.xml
	fi
	if [ ! -z "$MANAGER_USER" -a ! -z "$MANAGER_PASSWD" ] ; then
        sed -i .temp "/<\/tomcat-users/i\\
        <user name=\"$MANAGER_USER\"   password=\"$MANAGER_PASSWD\" roles=\"manager\" />
        
        " conf/tomcat-users.xml		
	fi
    rm -f conf/server.xml.temp
    rm -f conf/tomcat-users.xml.temp
echo "...ok"


# copy home to home
if [ "$INSTALL_TYPE" = "full" -o "$INSTALL_TYPE" = "split" ] ; then
	echo -n "Installing binaries"
	cp -fR "bin" "$TOMCAT_BINARIES"
	cp -fR "common" "$TOMCAT_BINARIES"
	cp -fR "server" "$TOMCAT_BINARIES"
	echo "...ok"
fi

# copy base to base
echo -n "Installing base"
cp -fR "conf" "$TOMCAT_BASE"
cp -fR "LICENSE" "$TOMCAT_BASE"
cp -fR "logs" "$TOMCAT_BASE"
cp -fR "NOTICE" "$TOMCAT_BASE"
cp -fR "RELEASE-NOTES" "$TOMCAT_BASE"
cp -fR "RUNNING.txt" "$TOMCAT_BASE"
cp -fR "shared" "$TOMCAT_BASE"
cp -fR "temp" "$TOMCAT_BASE"
cp -fR "webapps" "$TOMCAT_BASE"
cp -fR "work" "$TOMCAT_BASE"
echo "...ok"


# set permissions
echo -n "Setting permissions"
cd "$TOMCAT_BINARIES"
chmod -fR 775 *
chmod -f a+x bin/*.sh
cd "$TOMCAT_BASE"
chmod -f 770 conf/*
chmod -f 777 logs
echo "...ok"

# clean up nice, nice
echo -n "Cleaning up"
cd /tmp
rm -fR jakarta-tomcat-5.0.28*
echo "...ok"

echo "Installation complete"

} 2>"$INSTALLER_ERR"

exit 0
