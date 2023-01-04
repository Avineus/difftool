#!/bin/bash

CHKPOINT=0
SBNAME=$1
USER=$2
CMD=$3

. /homes/antonyr/public_html/cgi/sb_user.env

CHKPOINT=$(($CHKPOINT + 1))

if [ -z "$SBNAME" ]; then
    echo "Need sand box name"
    exit $CHKPOINT
fi

if [ -z "$USER" ]; then
    USER=antonyr
fi
if [ -z "$CMD" ]; then
    CMD=info
fi

CHKPOINT=($CHKPOINT + 1)
id -u $USER > /dev/null
if [ $? -ne 0 ]; then
    echo "$USER is not a valid username"
    exit $CHKPOINT
fi

CHKPOINT=$(($CHKPOINT + 1))
cd /b/$USER/$SBNAME/src
if [ $? -ne 0 ]; then
    echo "Path not found /b/$USER/$SBNAME/src"
    exit $CHKPOINT
fi

echo "################################################################"
echo -en "Checking sandbox /b/$USER/$SBNAME/src at "
hostname
echo "################################################################"
echo
echo

CHKPOINT=($CHKPOINT + 1)
echo "$CMD:"
svn $CMD
if [ $? -ne 0 ]; then
    echo "svn $CMD got error $?"
    exit $CHKPOINT
fi

