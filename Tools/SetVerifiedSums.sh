#!/bin/sh

echo "Using PROJECT_DIR=$PROJECT_DIR"

RESOURCE_DIR="${PROJECT_DIR}/Resources"

echo -n "Calculating sums ..."
INSTALLER_MD5_SUM=`md5 -q "${RESOURCE_DIR}/Installer/install-5.0.28.sh"`
ENABLE_STARTUP_ITEM_MD5_SUM=`md5 -q "${RESOURCE_DIR}/Scripts/EnableStartupItem.sh"`
DISABLE_STARTUP_ITEM_MD5_SUM=`md5 -q "${RESOURCE_DIR}/Scripts/DisableStartupItem.sh"`
SLAPPER_MD5_SUM=`md5 -q "${RESOURCE_DIR}/Scripts/TomcatSlapper.sh"`
echo "ok"

echo "Using INSTALLER_MD5_SUM=$INSTALLER_MD5_SUM"
echo "Using ENABLE_STARTUP_ITEM_MD5_SUM=$ENABLE_STARTUP_ITEM_MD5_SUM"
echo "Using DISABLE_STARTUP_ITEM_MD5_SUM=$DISABLE_STARTUP_ITEM_MD5_SUM"
echo "Using SLAPPER_MD5_SUM=$SLAPPER_MD5_SUM"

TEMPLATE="${PROJECT_DIR}/Source/TCSAuthorizationHandlerVerifiedSums.template"
echo "Using template: $TEMPLATE"
WORKING_FILE="${PROJECT_DIR}/Source/TCSAuthorizationHandlerVerifiedSums.working"
echo "Using working file: $WORKING_FILE"
HEADER="${PROJECT_DIR}/Source/TCSAuthorizationHandlerVerifiedSums.h"
echo "Using header: $HEADER"

echo -n "Copying template to header ..."
cp  "$TEMPLATE" "$HEADER"
echo "ok"

echo -n "Replacing tokens ..."
sed -i .temp "s/_INSTALLER_MD5_SUM_/$INSTALLER_MD5_SUM/" "$HEADER"
sed -i .temp "s/_ENABLE_STARTUP_ITEM_MD5_SUM_/$ENABLE_STARTUP_ITEM_MD5_SUM/" "$HEADER"
sed -i .temp "s/_DISABLE_STARTUP_ITEM_MD5_SUM_/$DISABLE_STARTUP_ITEM_MD5_SUM/" "$HEADER"
sed -i .temp "s/_SLAPPER_MD5_SUM_/$SLAPPER_MD5_SUM/" "$HEADER"
echo "ok"

#echo "Header contents: "
#cat "$HEADER"
#open $HEADER

echo -n "Cleaning up ..."
rm "$HEADER.temp"
echo "ok"

if [ ! -f $HEADER ] ; then
    echo "Header file missing: $HEADER"
    exit 1
fi

CONTENT=`cat $HEADER`
if [ -z "$CONTENT" ] ; then
    echo "Header file empty: $HEADER"
    exit 1
fi

exit 0