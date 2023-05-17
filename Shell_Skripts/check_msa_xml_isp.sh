#!/bin/bash
#
# /usr/lib/nagios/plugins/check_msa_xml_isp.sh [-H] [-u] [-p] [-s] [--Version] [-h | ? | --help]
#
# Voraussetzungen:
#       Ein leseberechtiger User im MSA fürs Monitoring
#       Paket curl und xmlstarlet muss installiert sein
#       apt install curl
#       apt install xmlstarlet

setzepfade() {
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
   echo "Usage: $PROGNAME [-H] [-u] [-p] [--Version] [-h | ? | --help] "
   echo
   echo " -H oder --hostname || Hostname || Pflichteintrag"
   echo " -u oder --user || User || Pflichteintrag"
   echo " -p oder --passwort || Passwort || Pflichteintrag"
   echo " -s oder --show || Show Variable für die CLI/API z.B. disk oder controller usw. || Pflichteintrag"
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
    -s|--show)
       show="$2"
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

sha="$(echo -n "${user}_${passwort}" | sha256sum | cut -c1-64)"

sessionkey="$(curl -ks -H "Accept: application/xml" https://$hostname/api/login/$sha | xmlstarlet sel -t -v '//RESPONSE/OBJECT/PROPERTY[@name="response"]/text()')"

health=($(curl -ks -H "sessionKey: $sessionkey" https://$hostname/api/show/$show | xmlstarlet sel -t -v '//RESPONSE/OBJECT/PROPERTY[@name="health"]/text()'))

# Variablen für Anzahlermittlung der Variable Ausgabe
z_gesamt=0
z_ok=0
z_degraded=0
z_fault=0
z_n_a=0
z_unknown=0

for ((i=0; i<${#health[@]}; i++)); do
                z_gesamt=$((z_gesamt+1))
        if [[ "${health[$i]}" = "OK" ]] ; then
                echo -e "\nDer Health Status der Komponente ist ${health[$i]}"
                z_ok=$((z_ok+1))
        elif [[ "${health[$i]}" = "Degraded" ]] ; then
                echo -e "\nDer Health Status der Komponente ist ${health[$i]}"
                z_degraded=$((z_degraded+1))
        elif [[ "${health[$i]}" = "Fault" ]] ; then
                echo -e "\nDer Health Status der Komponente ist ${health[$i]}"
                z_fault=$((z_fault+1))
        elif [[ "${health[$i]}" = "N/A" ]] ; then
                echo -e "\nDer Health Status der Komponente ist ${health[$i]}"
                z_n_a=$((z_n_a+1))
        elif [[ "${health[$i]}" = "Unknown" ]] ; then
                echo -e "\nDer Health Status der Komponente ist ${health[$i]}"
                z_unknown=$((z_unknown+1))
        else
                echo -e "\nScript hat einen unbekannten Wert: ${health[$i]} und muss geprüft werden"
                exit $STATE_UNKNOWN
        fi
done

if [[ $z_gesamt -eq $z_ok ]] ; then
          exit $STATE_OK
     elif [[ $z_fault -gt 0  ]] ; then
          exit $STATE_CRITICAL
     elif [[ $z_degraded -gt 0  ]] || [[ $z_unknown -gt 0  ]] || [[ $z_n_a -gt 0  ]] ; then
          exit $STATE_WARNING
     else
          echo -e "\nScript auf dem Satellit muss geprüft werden"
          exit $STATE_UNKNOWN
fi
