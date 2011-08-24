#!/bin/sh
#
# Wrapper script for a Tomcat instance that allows environment to be set from 
# the command line.
#
# Copyright 2005 Fivesquare Software, LLC. All rights reserved.
#


usage() {
	echo ""
	echo "Usage: $0 -j JAVA_HOME -h CATALINA_HOME [-b CATALINA_BASE] [-t CATALINA_OPTS] [-p CATALINA_PID] [-j JPDA_TRANSPORT] [-s JPDA_ADDRESS] command1 command2 ..."
	exit 1
}

#echo "$0 $@"
#echo "$UID"
#echo "$EUID"

# do not use environment
unset JAVA_HOME
unset CATALINA_HOME
unset CATALINA_BASE
unset CATALINA_OPTS
unset CATALINA_PID
unset JPDA_TRANSPORT
unset JPDA_ADDRESS

while getopts "e:j:h:b:t:p:v" o
do 
    case "$o" in
        e) SLAPPER_ERR=$OPTARG ;;
        j) JAVA_HOME=$OPTARG ;;
        h) CATALINA_HOME=$OPTARG ;;
        b) CATALINA_BASE=$OPTARG ;;
        t) CATALINA_OPTS=$OPTARG ;;
        p) CATALINA_PID=$OPTARG ;; 
        j) JPDA_TRANSPORT=$OPTARG ;;
        s) JPDA_ADDRESS=$OPTARG ;;
        v) $VERBOSE="YES" ;; 
    esac
done

if [ "$SLAPPER_ERR" = "" ] ; then
	echo "Cannot open stderr for runner ... quitting"
	usage
fi

{

# command1 command2 ... = $@
shift $(($OPTIND-1))
COMMANDS=("$@")
echo "Issuing command '${COMMANDS[@]}'"
# drop the null terminator
#unset COMMANDS[${#COMMANDS[@]}-1]
#echo "COMMANDS='${COMMANDS[@]}'"

# check env
echo -n "Validating environment..."
if [ -z "$JAVA_HOME" ] ; then
	echo "JAVA_HOME must be set to run Tomcat"
	usage
fi
if [ -z "$CATALINA_HOME" ] ; then
	echo "CATALINA_HOME must be set to run Tomcat"
	usage
fi
if [ -z "$CATALINA_BASE" ] ; then
	CATALINA_BASE="$CATALINA_HOME"
fi
echo "ok"


#echo "Using JAVA_HOME=$JAVA_HOME"
#echo "Using CATALINA_HOME=$CATALINA_HOME"
#echo "Using CATALINA_BASE=$CATALINA_BASE"
#echo "Using CATALINA_OPTS=$CATALINA_OPTS"
#echo "Using CATALINA_PID=$CATALINA_PID"

# set environment
echo -n "Setting environment..."
export JAVA_HOME=$JAVA_HOME
export CATALINA_HOME=$CATALINA_HOME
export CATALINA_BASE=$CATALINA_BASE
export CATALINA_OPTS="$CATALINA_OPTS"
export CATALINA_PID=$CATALINA_PID
export JPDA_TRANSPORT=$JPDA_TRANSPORT
export JPDA_ADDRESS=$JPDA_ADDRESS
echo "ok"



# check script
echo -n "Checking script..."
SCRIPT="$CATALINA_HOME/bin/catalina.sh"
test -x "$SCRIPT" || exit 1
echo "...ok"


for COM in "${COMMANDS[@]}" ; do
    #echo "COM=${COM}"
    echo "Running '$SCRIPT ${COM}'"
    "$SCRIPT" ${COM} 2>&1
done

} 2>"$SLAPPER_ERR"

exit 0

