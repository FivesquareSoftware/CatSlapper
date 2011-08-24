#!/bin/sh

#
# Removes a StartupItem for a Tomcat instance
#

ITEM=$1

if [ -z "$ITEM" ] ; then
	echo "No item to remove"
	exit 1
fi

echo "Removing $ITEM"
rm -Rf "$ITEM"

exit 0

