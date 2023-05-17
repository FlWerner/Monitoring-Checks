#!/bin/bash
# Nutzung:   /usr/lib/nagios/plugins/check_otc_api_vpn_status.sh -u <user> -p <passwort> -d <domain-name> -c <connection-id>
# Voraussetzung: lesender User in der API und Zugriff auf die zu überwachende IPSec VPN; Paket jq und awk

# Diese Pfade sollten auf jedem System getestet werden.
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
export PATH
PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
VERSION=1.0
VERBOSE=0

. $PROGPATH/utils.sh

printHelp() {
        echo
        echo "Usage: $PROGNAME [-u] [-p] [-d] [-c] [-v] [-V] [-h] "
        echo
        echo " -u User"
        echo " -p Passwort"
        echo " -d Domain-Name des Users"
        echo " -c Connection-ID der IPSec VPN Verbindung"
        echo " -v verbose output"
        echo " -V Version"
        echo " -h Hilfe"
        echo
        echo " Script um in der OTC Cloud den IPSec VPN Verbindungsstatus ueber die API Schnittstelle abzufragen"
        echo
}

printVersion() {
        echo
        echo "$PROGNAME Version $VERSION"
        echo
}

checkOptions() {
   while getopts "u:p:d:c:vVh" OPTIONS $@; do
      case $OPTIONS in
        u) user=$OPTARG
           ;;
        p) passwort=$OPTARG
           ;;
        d) domainname=$OPTARG
           ;;
        c) vpnid=$OPTARG
           ;;
        h) printHelp
           exit $STATE_UNKNOWN
           ;;
        v) VERBOSE=1
           ;;
        V) printVersion
           exit $STATE_UNKNOWN
           ;;
        ?) printHelp
           exit $STATE_UNKNOWN
           ;;
      esac
   done
}
checkOptions $@

#Variablen
proxy="http://100.48.1.10:3128"
webtoken="https://iam.eu-de.otc.t-systems.com/v3/auth/tokens"

#Test
#echo $proxy
#echo $webtoken
#echo $user
#echo $passwort
#echo $domainname
#echo $vpnid
#set -x

#Token herausfinden
token=$(curl -i -s -x "$proxy" "$webtoken" -X POST -d '{"auth": {"identity": {"methods": ["password"],"password": {"user": {"name":"'"$user"'","domain": {"name":"'"$domainname"'"},"password":"'"$passwort"'"}}},"scope": {"project": {"name":"eu-de"}}}}' | awk '/X-Subject-Token/ { print $2 }' )
#echo $token

#Status herausfinden
data=$(curl -s -x "$proxy" -H "Content-Type:application/json" -H "X-Auth-Token:$token" -X GET "https://vpc.eu-de.otc.t-systems.com/v2.0/vpn/ipsec-site-connections/$vpnid" | jq -r '.ipsec_site_connection.status')

#Test der Abfragen weiter unten
#echo $data
#data=ACTIVE
#data=DOWN
#data=BUILD
#data=ERROR
#data=PENDING_CREATE
#data=PENDING_UPDATE
#data=PENDING_DELETE

#echo $data

        if [[ $data == null ]]; then
                        echo -n "Kritisch | Es ist ein Fehler beim Script aufgetreten. Bitte Monitoring Admin benachrichtigen"
                        exitCode=2
        elif [[ $data == ACTIVE ]] ; then
                        echo -n "OK | Die IPSec VPN Verbindung ist ACTIVE. VPN-ID: $vpnid"
                          exitCode=0
        elif [[ $data == DOWN ]]; then
                        echo -n "Kritisch | Die IPSec VPN Verbindung ist DOWN. VPN-ID: $vpnid"
                        exitCode=2
        elif [[ $data == BUILD ]] ; then
                        echo -n "WARNING | Die IPSec VPN Verbindung ist im Status BUILD. VPN-ID: $vpnid"
                          exitCode=1
        elif [[ $data == ERROR ]]; then
                        echo -n "Kritisch | Die IPSec VPN Verbindung ist im Status ERROR. VPN-ID: $vpnid"
                        exitCode=2
        elif [[ $data == PENDING_CREATE ]] ; then
                        echo -n "WARNING | Die IPSec VPN Verbindung ist im Status PENDING_CREATE. VPN-ID: $vpnid"
                          exitCode=1
        elif [[ $data == PENDING_UPDATE ]] ; then
                        echo -n "WARNING | Die IPSec VPN Verbindung ist im Status PENDING_UPDATE. VPN-ID: $vpnid"
                          exitCode=1
        elif [[ $data == PENDING_DELETE ]] ; then
                        echo -n "WARNING | Die IPSec VPN Verbindung ist im Status PENDING_DELETE. VPN-ID: $vpnid"
                          exitCode=1
        else
                        echo -n "UNKNOWN - Keine Ermittlung des Status! Bitte Monitoring Admin benachrichtigen"
                        exitCode=3
        fi

exit $exitCode
