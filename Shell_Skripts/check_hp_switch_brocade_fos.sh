#!/bin/bash
# Nutzung:
#
#    /usr/lib/nagios/Plugins/check_hp_switch_brocade_fos.sh -H <hostname> -u <user> -p <passwort> -a <variable_a> -b <variable_b> -c <variable_c> -d <variable_d> -e <variable_e> -f <variable_f> -g <variable_g> -j <json>
# Voraussetzung:
#
#    Paket curl und jg muss installiert sein
#    es muss ein User mit lesenden Rechten am Switch hinterlegt sein

# Diese Pfade sollten auf jedem System getestet werden.
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

if [ $? -eq 0 ]; then
PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
VERSION="1.0"
. $PROGPATH/utils.sh
else
  echo "Bei der Pfadsetzung ist ein Fehler aufgetreten"
  exit
fi
}

setzepfade

printHelp() {
        echo
        echo "Usage: $PROGNAME [-H] [-u] [-p] [-a] [-b] [-c] [-d] [-e] [-f] [-g] [-j] [-v] [-V] [-h]"
        echo
        echo " -H Server IP"
        echo " -u User"
        echo " -p Passwort"
        echo " -a -b -c -d -e -f -g Variablen die von Icinga am Master aufgrund der Schnittstelle in der API übergeben werden"
        echo " -j Json Data"
        echo " -v verbose output"
        echo " -V Version"
        echo " -h Hilfe"
        echo
        echo " Script für Rest API Abfrage eines Status am Switch"
        echo
}

printVersion() {
        echo
        echo "$PROGNAME Version $VERSION"
        echo
}

checkOptions() {
   while getopts "H:u:p:a:b:c:d:e:f:g:j:vVh" OPTIONS $@; do
      case $OPTIONS in
         H) hostname=$OPTARG
            ;;
         u) user=$OPTARG
            ;;
         p) passwort=$OPTARG
            ;;
         a) a=$OPTARG
            ;;
         b) b=$OPTARG
            ;;
         c) c=$OPTARG
            ;;
         d) d=$OPTARG
            ;;
         e) e=$OPTARG
            ;;
         f) f=$OPTARG
            ;;
         g) g=$OPTARG
            ;;
         j) j=$OPTARG
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

if [[ $# = 0 ]]; then
   printHelp
   exit $STATE_OK
fi

# Curl Variablen
prog="/usr/bin/curl"
curlpar1="-ks"
curlpar2="-I -X POST"
curlpar3="-X POST"
header1="Content-type: application/yang-data+xml"
header3="Accept: application/yang-data+json"
urllogin="http://$hostname/rest/login"
urllogout="http://$hostname/rest/logout"

# Login
# curl -ks -I -X POST -u "monitoring:XXXXXXXXXXXXXXX" -H "Accept: application/yang-data+xml" -H "Content-type: application/yang-data+xml" "http://172.18.0.36/rest/login" | grep Authorization
# Authorization: Custom_Basic bW9uaXRvcmluZzp4eHg6M2Q3MjMwZjg4MzFkODg4MmY2MzNhZjdmNzM0NDZmMWMzODViNTNmMzIwMjhiMDRjZjM5MGYwNDNjYzlhZjU4OQ==
# Wir machen grep auf Authorization 
auth=$($prog $curlpar1 $curlpar2 -u $user:$passwort -H $header3 -H $header1 $urllogin | grep "Authorization")

# Check
# curl -ks -H "Authorization:Custom_Basic XXXXXXXXX" -H "Accept: application/yang-data+json" "http://172.18.0.36/rest/running/brocade-interface/fibrechannel/name/0%2f23/operational-status" | jq -r '.Response.fibrechannel."operational-status"'
# data=$(curl -ks -v -H "'"$value"'"  -H "Accept: application/yang-data+json" "http://$hostname/rest/running/brocade-interface/fibrechannel/name/0%2f23/operational-status" | jq -r '.Response.fibrechannel."operational-status"')
# data=$($prog $curlpar2 -H "${auth[@]}" -H "$header1" "http://$hostname/rest/running/brocade-interface/fibrechannel/name/0%2f23/operational-status" | jq -r '.Response.fibrechannel."operational-status"')
# curl -ks -H "Authorization: Custom_Basic " -H "Accept: application/yang-data+json" "http://172.18.0.36/rest/running/brocade-maps/switch-status-policy-report" | jq -r '.Response."switch-status-policy-report"."switch-health"'
# check=$($prog $curlpar2 -H "${auth[@]}" -H "$header1" "http://$hostname/rest/running/brocade-maps/switch-status-policy-report" | jq -r '.Response."switch-status-policy-report"."switch-health"')
        if [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -z "$b" && -z "$c" && -z "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -z "$c" && -z "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a/$b" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -z "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a/$b/$c" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a/$b/$c/$d" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -n "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a/$b/$c/$d/$e" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -n "$e" && -n "$f" && -z "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a/$b/$c/$d/$e/$f" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -n "$e" && -n "$f" && -n "$g"  && -n "$j" ]]; then
                check=($($prog $curlpar1 -H "${auth::-1}" -H "$header3" "http://$hostname/rest/running/$a/$b/$c/$d/$e/$f/$g" | jq -r '.'"$j"''))

        else
                echo "Es ist bei der Variablen Abfrage ein Fehler aufgetreten"
               exitCode=3
fi

#Variablen
gesamtanzahl=0
anzahlhealthy=0
anzahlunknown=0
anzahlmarginal=0
anzahlcritical=0

for ((i=0; i<${#check[@]}; i++)); do
                gesamtanzahl=$((gesamtanzahl+1))
        if [[ "${check[$i]}" = "healthy" ]] ; then
                echo "Der Status der Komponente ist: ${check[$i]}"
                anzahlhealthy=$((anzahlhealthy+1))
        elif [[ "${check[$i]}" = "unknown" ]] ; then
                echo "Der Status der Komponente ist: ${check[$i]}"
                anzahlunknown=$((anzahlunknown+1))
        elif [[ "${check[$i]}" = "marginal" ]] ; then
                echo "Der Status der Komponente ist: ${check[$i]}"
                anzahlmarginal=$((anzahlmarginal+1))
        elif [[ "${check[$i]}" = "down" ]] ; then
                echo "Der Status der Komponente ist: ${check[$i]}"
                anzahlcritical=$((anzahlcritical+1))
        fi
done

     if [[ $anzahlhealthy -gt 0  ]] ; then
                exitCode=0
     elif [[ $anzahlmarginal -gt 0  ]] ; then
                exitCode=1
     elif [[ $anzahlcritical -gt 0  ]] ; then
                exitCode=2
     elif [[ $anzahlunknown -gt 0  ]] ; then
                exitCode=3
     else
                exitCode=3
fi

# Logout
# /usr/bin/curl  -X POST http://172.18.0.36/rest/logout -H 'Authorization: Custom_Basic bW9uaXRvcmluZzp4eHg6M2Q3MjMwZjg4MzFkODg4MmY2MzNhZjdmNzM0NDZmMWMzODViNTNmMzIwMjhiMDRjZjM5MGYwNDNjYzlhZjU4OQ=='
$prog $curlpar1 $curlpar3 $urllogout -H "${auth::-1}"

exit $exitCode
