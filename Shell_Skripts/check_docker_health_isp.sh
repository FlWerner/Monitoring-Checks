#!/bin/bash
#
# /usr/lib/nagios/plugins/check_docker_health_isp.sh -j State.Health.Status
#
# Voraussetzungen:
#       Ein leseberechtiger User auf dem Server beim Docker Dienst
#       Paket curl und jq muss installiert sein

setzepfade() {
P1="/usr/local/sbin"
P2="/usr/local/bin"
P3="/sbin"
P4="/bin"
P5="/usr/sbin"
P6="/usr/bin"
P7="/usr/lib64/nagios/plugins"

if [ -d $P1 ] && [ -d $P2 ] && [ -d $P3 ] && [ -d $P4 ] && [ -d $P5 ] && [ -d $P6 ] && [ -d $P7 ] ; then
   PATH="$P1:$P2:$P3:$P4:$P5:$P6:$P7"
else
   echo "Ein wichtiges Verzeichnis ist nicht vorhanden"
   exit
fi

export PATH
}

tooleinlesen() {
PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
VERSION="1.0"
. $PROGPATH/utils.sh
}

printHelp() {
   echo
   echo "Usage: $PROGNAME [-j] [--Version] [-h | ? | --help] "
   echo
   echo " -j oder --json || Json Abfrage || Pflichteintrag"
   echo
   echo
   echo " --Version "
   echo " -h Hilfe "
   echo " ? Hilfe "
   echo " --help Hilfe "
   echo
}

printVersion() {
   echo
   echo "$PROGNAME Version $VERSION"
   echo
}

setzepfade
tooleinlesen

if [[ $# = 0 ]]; then
   printHelp
   exit $STATE_OK
fi

argumente=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -j|--json)
       json="$2"
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

#Variable für die Anzahlermittlung
        #health=(starting|healthy|unhealthy|none|null)
        gesamtanzahl=0

#Alle mit Icinga2 Health OK
        anzahlok=0
        anzahlhealthy=0

#Alle mit Icinga2 Health WARNING
        anzahlwarning=0
        anzahlstarting=0

#Alle mit Icinga2 Health CRITICAL
        anzahlcritical=0
        anzahlunhealthy=0
        anzahlnone=0

#Alle mit Icinga2 Health UNKNOWN
        anzahlunknown=0
        anzahlnull=0
		
id=($(curl -ks --unix-socket /var/run/docker.sock http://localhost/v1.41/containers/json | jq -r '.[]|.Id'))

if [[ "${#id[*]}" = 0 ]]; then
        echo "Fehler in der Variable id. Es wurde nichts hinterlegt"
        exit $STATE_UNKNOWN
fi

for ((i=0; i<${#id[*]}; i++)); do
        gesamtanzahl=$((gesamtanzahl+1))

        health+=($(curl -ks --unix-socket /var/run/docker.sock http://localhost/v1.41/containers/${id[$i]}/json | jq -r '.'"$json"''))
 
        name+=($(curl -ks --unix-socket /var/run/docker.sock http://localhost/v1.41/containers/${id[$i]}/json | jq -r '.Name' | cut -c2-))

done

if [[ "${#health[*]}" = 0 ]]; then
        echo "Fehler in der Variable health. Es wurde nichts hinterlegt"
        exit $STATE_UNKNOWN
fi

for ((i=0; i<${#health[*]}; i++)); do
        if [[ "${health[$i]}" = "healthy" ]] ; then
                echo "Der Container Name: ${name[$i]} mit der ID: ${id[$i]} hat folgenden Health: ${health[$i]}"
                anzahlok=$((anzahlok+1))
        elif [[ "${health[$i]}" = "starting" ]] ; then
                echo "Der Container Name: ${name[$i]} mit der ID: ${id[$i]} hat folgenden Health: ${health[$i]}"
                anzahlwarning=$((anzahlwarning+1))
        elif [[ "${health[$i]}" = "unhealthy" ]] ; then
                echo "Der Container Name: ${name[$i]} mit der ID: ${id[$i]} hat folgenden Health: ${health[$i]}"
                anzahlcritical=$((anzahlcritical+1))
        elif [[  "${health[$i]}" = "none" ]] ; then
                echo "Der Container Name: ${name[$i]} mit der ID: ${id[$i]} hat folgenden Health: ${health[$i]}"
                anzahlcritical=$((anzahlcritical+1))
        elif [[  "${health[$i]}" = "null" ]] ; then
                echo "Der Container Name: ${name[$i]} mit der ID: ${id[$i]} hat folgenden Health: ${health[$i]}"
                anzahlunknown=$((anzahlunknown+1))
        else
               echo "Der health des Docker Containers ist nicht feststellbar"
        fi
done

if [[ $gesamtanzahl -eq $anzahlok ]] ; then
        exit $STATE_OK

        elif [[ $anzahlwarning -gt 0  ]] ; then
        exit $STATE_WARNING

        elif [[ $anzahlcritical -gt 0  ]] ; then
        exit $STATE_CRITICAL

        elif [[ $anzahlunknown -gt 0  ]] ; then
        exit $STATE_UNKNOWN

        else
        exit $STATE_UNKNOWN
fi

exit
