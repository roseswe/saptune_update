#!/bin/bash
# $Header: /home/cvs/AddSourceCode/suse/sap/migrate2saptune.sh,v 1.7 2020/04/14 11:12:14 ralph Exp $
# (c) 2019-2020 by Ralph Roth, ROSE SWE
# ---------------------------------------------------------------------------
# This script tries to migrate a host running saptune v1 to saptune v2, see:
#      man 7 saptune
# rr, 26.09.2019 - initial creation, send feedback to Ralph dot Roth at suse dot com
# rr, 12.11.2019 - many fixes around CSI output etc. Sanity checks
# rr, 18.11.2019 - CVS keywords, beautified the source
# rr, 18.02.2020 - workaround for corrupted SAPTUNE_VERSION= in /etc/sysconfig/saptune
# rr, 14.04.2020 - workaround for bug with /var/lib/saptune/saved_state files added
# ---------------------------------------------------------------------------

export LANG=posix

# little sanity check: is saptune installed and are we root (/usr/sbin/saptune)
which saptune || exit 42

# overdosing is not needed, means v2 already active
saptune version | grep -q "version is '2'$"  && exit 41

# needed later, maybe we need here a trap handling to remove this file ...?
TMPFILE=$(mktemp)

# we need this information later to apply them again
# the perl stuff is a workaround to get rid off ANSI escape sequences (CSI codes)
SOLUTION=$(saptune solution list 2> /dev/null | perl -pe 's/\e\[[0-9;]*m(?:\e\[K)?//g' | awk ' {if ($1 == "*" ) print $2;} ')

# ---------------------------------------------------------------------------

for f in ${SOLUTION}
do
    saptune solution revert $f 2>/dev/null
done

# works as long as there is no override file in place
NOTES=$(saptune note list 2> /dev/null | perl -pe 's/\e\[[0-9;]*m(?:\e\[K)?//g' | awk ' {if ($1 == "+" ) print $2;} ')

for f in ${NOTES}
do
    saptune note revert $f 2>/dev/null
done

sed 's/SAPTUNE_VERSION="1"/SAPTUNE_VERSION="2"/' /etc/sysconfig/saptune > $TMPFILE
mv -f $TMPFILE /etc/sysconfig/saptune   ## -rw-r--r--, 644
rm -f /var/lib/saptune/saved_state/*    ## not sure if this needs to be applied before or after the migration!
chmod 644 /etc/sysconfig/saptune        ## rpm -V, chkstat(8)

echo "### Please check if the following variables in /etc/sysconfig/saptune are empty and SAPTUNE_VERSION=2 is set"
egrep -v "^#|^$" /etc/sysconfig/saptune

echo "### Config files cleanup..."

rm -f /etc/saptune/extra/{SAP_BOBJ-SAP_Business_OBJects.conf,SAP_ASE-SAP_Adaptive_Server_Enterprise.conf}
rm -f /etc/tuned/saptune/*
rm -f /etc/sysconfig/saptune-note-*
rm -f /etc/systemd/logind.conf.d/sap.conf
rm -rf /var/log/saptune/

## may not work - Puppet needs to be fixed?
grep -v " nofile " /etc/security/limits.conf > $TMPFILE
mv -f $TMPFILE /etc/security/limits.conf

systemctl restart tuned.service || echo "#####  ---  ERROR restarting tuned  ---  #####"

# sanity, seen on a few hosts, not sure if this is a bug of 2.0.1-3.16.1, saptune-2.0.2-3.21.1.x86_64
grep -q "SAPTUNE_VERSION=" /etc/sysconfig/saptune || echo 'SAPTUNE_VERSION="2"' >> /etc/sysconfig/saptune

# ---------------------------------------------------------------------------
## INFO: There is already one solution applied. Applying another solution is NOT supported.
## So, if you have more than (1) solutions applied, the first one gets activated! (difference to saptune v1)

for f in ${SOLUTION}
do
    echo "#### Solution: $f"
    saptune solution apply $f 2>/dev/null
    saptune solution verify $f
done

for f in ${NOTES}
do
    echo "#### Note: $f"
    saptune note apply $f 2>/dev/null
    saptune note verify $f
done

# sanity, seen on a few hosts, not sure if this is a bug of 2.0.1-3.16.1, saptune-2.0.2-3.21.1.x86_64
grep -q "SAPTUNE_VERSION=" /etc/sysconfig/saptune || echo 'SAPTUNE_VERSION="2"' >> /etc/sysconfig/saptune
rpm -q saptune
saptune version
RET=$?
exit $RET
# ---------------------------------------------------------------------------
