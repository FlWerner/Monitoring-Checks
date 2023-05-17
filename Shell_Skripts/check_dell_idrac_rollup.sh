#!/bin/bash
# Nutzung:   /usr/lib/nagios/plugins/check_idrac_rollup.sh -H <hostname> -u <user> -p <passwort> -m <module>
# Voraussetzung: Lesender User im IDRAC
# und Paket curl und jq muss installiert sein:    apt install curl | apt install jq
# Test des Scriptes und Ausgabe aller Befehle
#set -x

printHelp() {
   echo
   echo "Usage: $PROGNAME [-H] [-u] [-p] [-m] [-V] [-h|?] "
   echo
   echo " -H oder --hostname | IDRAC IP Addresse"
   echo " -u oder --user | User"
   echo " -p oder --passwort | Passwort"
   echo " -m oder --modul | Modul des DELLSystems was angesprochen werden soll (BatteryRollupStatus oder CPURollupStatus usw.)"
   echo " -V Version"
   echo " -h oder ? | Hilfe"
   echo
   echo " Script für IDRAC Abfrage zur Schnittstelle REST API "
   echo
}

printVersion() {
   echo
   echo "$PROGNAME Version $VERSION"
   echo
}

pfad_utils() {
P1="/usr/local/sbin"
P2="/usr/local/bin"
P3="/sbin"
P4="/bin"
P5="/usr/sbin"
P6="/usr/bin"
P7="/usr/lib/nagios/plugins"

if [ -d $P1 ] && [ -d $P2 ] && [ -d $P3 ] && [ -d $P4 ] && [ -d $P5 ] && [ -d $P6 ] && [ -d $P7 ] ; then
   PATH="$P1:$P2:$P3:$P4:$P5:$P6:$P7"
else
   echo "Ein wichtiges Verzeichnis ist nicht vorhanden. Bitte die Pfade im Script und auf dem Server kontrollieren."
   exit
fi

export PATH

if [ $? -eq 0 ]; then
PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
VERSION="1.0"
. $PROGPATH/utils.sh
else
  echo "Beim Laden der Icinga2 Utils ist ein Fehler aufgetreten"
  exit
fi
}

pfad_utils

if [[ $# = 0 ]]; then
   printHelp
fi

argumente=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -H|--hostname)
       hostname="$2"
       shift
       ;;
    -u|--user)
       user="$2"
       shift
      ;;
    -p|--passwort)
       passwort="$2"
       shift
      ;;
    -m|--modul)
       modul="$2"
       shift
      ;;
    -h|-?|?|--help)
      printHelp
      exit $STATE_OK
      ;;
    --Version)
      printVersion
      exit $STATE_OK
      ;;
    -*|--*)
      echo "Diese Option ist nicht bekannt $1"
      exit $STATE_UNKNOWN
      ;;
    *)
      argumente+=("$1")
      shift
      ;;
  esac
done

dellidrac=$(curl -ks https://$hostname/redfish/v1/Systems/System.Embedded.1 -u $user:$passwort | jq -r '.Oem.Dell.DellSystem."'"$modul"'"')

        if [[ $dellidrac = "OK" ]] ; then
                        echo -n "OK - $modul hat folgenden Status: OK"
                        exit $STATE_OK
        elif [[ $dellidrac = "Degraded" ]]; then
                        echo -n "DEGRADED - $modul hat folgenden Status: Degraded"
                        exit $STATE_WARNING
        elif [[ $dellidrac = "Error" ]]; then
                        echo -n "CRITICAL - $modul hat folgenden Status: CRITICAL"
                        exit $STATE_CRITICAL
        elif [[ $dellidrac = "Unknown" ]]; then
                        echo -n "UNKNOWN - $modul hat folgenden Status: Unknown"
                        exit $STATE_UNKNOWN
        else
                        echo -n "UNKNOWN - $modul hat folgenden Status: Unknown"
                        exit $STATE_UNKNOWN
        fi
