#!/bin/sh

# Freeciv - Copyright (C) 2007 - The Freeciv Project

# This script generates fc_gitrev_gen.h from fc_gitrev_gen.h.tmpl.
# See fc_gitrev_gen.h.tmpl for details.

# Parameters - $1 - top srcdir
#              $2 - output file
#

# Absolute paths
SRCROOT="$(cd "$1" ; pwd)"
INPUTDIR="$(cd "$1/bootstrap" ; pwd)"
OUTPUTFILE="$2"

REVSTATE="OFF"
REV1=""
REV2="dist"
EXT1=""
EXT2=""

(cd "$INPUTDIR"
 # Check that all commands required by this script are available
 # If not, we will not claim to know which git revision this is
 # (REVSTATE will be OFF)
 if command -v git >/dev/null &&
    command -v tail >/dev/null &&
    command -v head >/dev/null &&
    command -v sed >/dev/null &&
    command -v awk >/dev/null &&
    command -v grep >/dev/null ; then

   BRANCH="origin/$(cd "$SRCROOT"; git branch|grep '^*'|sed -e 's:[/ (),*]: :g' |awk '{ print $NR }' 2>/dev/null)"
   ORIGIN="$(cd "$SRCROOT"; git rev-parse --short $BRANCH 2>/dev/null)"
   HEAD="$(cd "$SRCROOT"; git rev-parse --short HEAD 2>/dev/null)"

   if test "x$HEAD" != "x" ; then
     # This is git repository. Check for local modifications
     if (cd "$SRCROOT" ; git diff $BRANCH --quiet); then
       REVSTATE="ON $BRANCH $ORIGIN "
       REV2="HEAD $HEAD"
     else
       REVSTATE=MOD
       COUNT=$(git rev-list --count HEAD ^$ORIGIN)
       if [ "$COUNT" != "0" ]; then
            EXT1="(+$COUNT)"
       fi
       if [ "$(cd "$SRCROOT" ; git diff $HEAD --quiet; echo $?)" != "0" ] ; then
            EXT2="+ modified"
       fi
       REV1="$BRANCH $ORIGIN "
       REV2="HEAD $HEAD $EXT1 $EXT2"
     fi
   fi
 fi

 sed -e "s,<GITREV1>,$REV1," -e "s,<GITREV2>,$REV2," -e "s,<GITREVSTATE>,$REVSTATE," fc_gitrev_gen.h.tmpl) > "${OUTPUTFILE}.tmp"

if ! test -f "${OUTPUTFILE}" ||
   ! cmp "${OUTPUTFILE}" "${OUTPUTFILE}.tmp" >/dev/null
then
  mv "${OUTPUTFILE}.tmp" "${OUTPUTFILE}"
fi
rm -f "${OUTPUTFILE}.tmp"
