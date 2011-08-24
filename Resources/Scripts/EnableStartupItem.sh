#!/bin/sh

#
# Installs a StartupItem for a Tomcat instance
#

# do not use environment
unset JAVA_HOME
unset CATALINA_HOME
unset CATALINA_BASE
unset CATALINA_OPTS
unset CATALINA_PID

while getopts "d:r:n:p:j:h:b:t:" o
do 
	case "$o" in
		d) RESOURCE_PATH=$OPTARG ;;
		r) REAL_NAME=$OPTARG ;;
		n) NAME=$OPTARG ;;
		p) CATALINA_PID=$OPTARG ;;
		j) JAVA_HOME=$OPTARG ;;
		h) CATALINA_HOME=$OPTARG ;;
		b) CATALINA_BASE=$OPTARG ;;
		t) CATALINA_OPTS=$OPTARG ;;
	esac
done

if [ -z "$RESOURCE_PATH" ] ; then
	echo "Resource path missing ... quitting"
	exit 1
fi

# check env
echo -n "Validating environment"
if [ -z "$JAVA_HOME" ] ; then
	echo "JAVA_HOME must be set for a StartupItem to work properly"
	exit 1
fi
if [ -z "$CATALINA_HOME" ] ; then
	echo "CATALINA_HOME must be set for a StartupItem to work properly"
	exit 1
fi
if [ -z "$CATALINA_PID" ] ; then
	echo "CATALINA_PID must be set to enable a StartupItem"
	exit 1
fi
if [ -z "$NAME" ] ; then
	echo "NAME must be set to enable a StartupItem"
fi
if [ -z "$TOMCAT_BASE" ] ; then
	CATALINA_BASE="$CATALINA_HOME"
fi
if [ -z "$REAL_NAME" ] ; then
	REAL_NAME="$NAME"
fi
echo "...ok"


echo "Using:"
echo "    RESOURCE_PATH=$RESOURCE_PATH"
echo "    JAVA_HOME=$JAVA_HOME"
echo "    CATALINA_HOME=$CATALINA_HOME"
echo "    CATALINA_BASE=$CATALINA_BASE"
echo "    CATALINA_OPTS=$CATALINA_OPTS"
echo "    CATALINA_PID=$CATALINA_PID"
echo "    NAME=$NAME"


# remove old item
rm -Rf /Library/StartupItems/${REAL_NAME}-*

# configure script
echo -n "Configuring StartupItem"

cp "$RESOURCE_PATH/StartupParameters.plist" "/tmp/StartupParameters.plist.$NAME"
cp "$RESOURCE_PATH/StartupItemTemplate" "/tmp/StartupItemTemplate.$NAME"
cd /tmp

sed -i .temp "s|{NAME}|$NAME|g" "StartupParameters.plist.$NAME"
sed -i .temp "s|{REAL_NAME}|$REAL_NAME|g" "StartupParameters.plist.$NAME"
rm -f "StartupParameters.plist.$NAME.temp"

sed -i .temp "s|{NAME}|$NAME|g" "StartupItemTemplate.$NAME"
sed -i .temp "s|{REAL_NAME}|$REAL_NAME|g" "StartupItemTemplate.$NAME"
sed -i .temp "s|{JAVA_HOME}|$JAVA_HOME|g" "StartupItemTemplate.$NAME"
sed -i .temp "s|{CATALINA_HOME}|$CATALINA_HOME|g" "StartupItemTemplate.$NAME"
sed -i .temp "s|{CATALINA_BASE}|$CATALINA_BASE|g" "StartupItemTemplate.$NAME"
sed -i .temp "s|{CATALINA_OPTS}|$CATALINA_OPTS|g" "StartupItemTemplate.$NAME"
sed -i .temp "s|{CATALINA_PID}|$CATALINA_PID|g" "StartupItemTemplate.$NAME"
rm -f "StartupItemTemplate.$NAME.temp"

echo "...ok"

# install
echo -n "Installing StartupItem"
mkdir "/Library/StartupItems/$NAME" > /dev/null 2>&1 
mv -f "StartupItemTemplate.$NAME" "/Library/StartupItems/$NAME/$NAME"
mv -f "StartupParameters.plist.$NAME" "/Library/StartupItems/$NAME/StartupParameters.plist"
echo "...ok"

# cleanup
echo -n "Cleaning up"
#rm  "StartupParameters.plist.$NAME".temp
#rm  "StartupItemTemplate.$NAME".temp
echo "...ok"

# set perms
echo -n "Setting permissions"
chmod -f 755 "/Library/StartupItems/$NAME/$NAME"
echo "...ok"

echo "StartupItem enabled"

exit 0


