#!/bin/bash
#
# urldecode - decoding the URL-encoded string
#
# (C)2010 Shang-Feng Yang <storm_DOT_sfyang_AT_gmail_DOT_com>
#
# License: GPLv3

ENC_STR=$@
[ "${ENC_STR}x" == "x" ] && {
TMP_STR="$(cat - | sed -e 's/%/\\x/g')"
} || {
TMP_STR="$(echo ${ENC_STR} | sed -e 's/%/\\x/g')"
}
PRINTF=/usr/bin/printf
exec ${PRINTF} "${TMP_STR}\n"


