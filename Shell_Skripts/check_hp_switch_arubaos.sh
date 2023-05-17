#!/bin/bash
#    /usr/lib/nagios/Plugins/check_hp_switch_arubaos.sh -H <hostname> -u <user> -p <passwort> -a <variable_a> -b <variable_b> -c <variable_c> -d <variable_d> -e <variable_e> -f <variable_f> -g <variable_g> -j <json>
# Voraussetzung:
#
#    Paket curl und jg muss installiert sein
#    apt install curl
#    apt  install jq
#    es muss ein User mit lesenden Rechten am Switch hinterlegt sein

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
        echo "Usage: $PROGNAME [-H] [-u] [-p] [-a] [-b] [-c] [-d] [-e] [-f] [-g] [-j] [-v] [-V] [-h] "
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
#echo $hostname
#echo $user
#echo $passwort

#Test
#set -x

#Login
#curl -k -s -X POST -c /tmp/auth_cookie_$hostname -H "Content-Type: multipart/form-data" "https://$hostname/rest/v10.04/login" -F "username=$user" -F "password=$passwort"
login=($(curl -k -s -X POST -c /tmp/auth_cookie_$hostname -H "Content-Type: multipart/form-data" "https://$hostname/rest/v10.04/login" -F "username=$user" -F "password=$passwort"))
#echo ${login[@]}

# Fehler abfangen
if [[ "${login[@]}" = "Login failed." ]] ; then
        echo "Es ist beim Login in die API ein Fehler aufgetreten"
        exitCode=3
        exit $exitCode
fi

#Test
#set -x

#Check
#Test
#check=$(curl -ks -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/system/subsystems/chassis,1/power_supplies/1%2F1" | jq -r '.status')

        if [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -z "$b" && -z "$c" && -z "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -z "$c" && -z "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a/$b" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -z "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a/$b/$c" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -z "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a/$b/$c/$d" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -n "$e" && -z "$f" && -z "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a/$b/$c/$d/$e" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -n "$e" && -n "$f" && -z "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a/$b/$c/$d/$e/$f" | jq -r '.'"$j"''))

        elif [[ -n "$hostname" && -n "$user" && -n "$passwort" && -n "$a" && -n "$b" && -n "$c" && -n "$d" && -n "$e" && -n "$f" && -n "$g"  && -n "$j" ]]; then
                check=($(curl -k -s -b /tmp/auth_cookie_$hostname -H "Content-Type:application/json" -H "Accept: application/json" "https://$hostname/rest/v10.04/$a/$b/$c/$d/$e/$f/$g" | jq -r '.'"$j"''))

        else
               echo "Es ist bei der Variablen Abfrage ein Fehler aufgetreten"
               abfrageerror=1
fi
#echo $check
#echo ${check[@]}
# Fehler abfangen
        if [[ $abfrageerror -gt 0  ]] ; then
                echo "Es ist bei der Abfrage der API ein Fehler aufgetreten"
                exitCode=3
                #Logout
                curl -k -s -X POST -b /tmp/auth_cookie_$hostname "https://$hostname/rest/v10.04/logout"
#                echo $exitCode
                exit $exitCode
fi

#set +x
#Variable für die Anzahlermittlung
gesamtanzahl=0

#Alle mit Icinga2 Status OK
anzahlok=0
anzahlready=0
anzahlup=0
anzahlpresent=0
anzahlnormal=0
anzahlsafe=0

#Alle mit Icinga2 Status WARNING
anzahlwarning=0
anzahlalert=0
anzahlunsupported=0
anzahlovertemp=0
anzahllow=0
anzahlhealth_alert=0
anzahlfailure_imminent=0
anzahlupdating=0
anzahlinitializing=0
anzahldiagnostic=0
anzahldeinitializing=0
anzahlno_member_port=0
anzahlno_member_forwarding=0
anzahlprivate_vlan_violation=0
anzahlnot_reported=0
#Alle mit Icinga2 Status CRITICAL
anzahlcritical=0
anzahldown=0
anzahlfault=0
anzahlempty=0
anzahlfault_absent=0
anzahlfault_input=0
anzahlfault_output=0
anzahlfault_poe=0
anzahlfault_norecov=0
anzahlcrit_low=0
anzahlfailed=0
anzahlfailover=0
anzahlerror=0
anzahladmin_down=0

#Alle mit Icinga2 Status UNKNOWN
anzahlunknown=0
anzahlnodata=0
anzahluninitialized=0

for ((i=0; i<${#check[@]}; i++)); do
                gesamtanzahl=$((gesamtanzahl+1))
        if [[ "${check[$i]}" = "ok" || "${check[$i]}" = "ready" || "${check[$i]}" = "up" || "${check[$i]}" = "present" || "${check[$i]}" = "normal" || "${check[$i]}" = "safe" ]] ; then
                echo "Der Status der Komponente ist: ${check[$i]}"
                anzahlok=$((anzahlok+1))

        elif [[ "${check[$i]}" = "warning" || "${check[$i]}" = "alert" || "${check[$i]}" = "unsupported" || "${check[$i]}" = "overtemp" || "${check[$i]}" = "low" || "${check[$i]}" = "health_alert" || "${check[$i]}" = "failure_imminent" || "${check[$i]}" = "updating" || "${check[$i]}" = "initializing" || "${check[$i]}" = "diagnostic" || "${check[$i]}" = "deinitializing" || "${check[$i]}" = "no_member_port" || "${check[$i]}" = "no_member_forwarding" || "${check[$i]}" = "private_vlan_violation" || "${check[$i]}" = "not_reported" ]] ; then
                echo "WARNING | Der Status der Komponente ist: ${check[$i]}"
                anzahlwarning=$((anzahlwarning+1))

        elif [[ "${check[$i]}" = "critical" || "${check[$i]}" = "down" || "${check[$i]}" = "fault" || "${check[$i]}" = "empty" || "${check[$i]}" = "fault_absent" || "${check[$i]}" = "fault_input" || "${check[$i]}" = "fault_output" || "${check[$i]}" = "fault_poe" || "${check[$i]}" = "fault_norecov" || "${check[$i]}" = "crit_low" || "${check[$i]}" = "failed" || "${check[$i]}" = "failover" || "${check[$i]}" = "error" || "${check[$i]}" = "admin_down" ]] ; then
                echo "CRITICAL | Der Status der Komponente ist: ${check[$i]}"
                anzahlcritical=$((anzahlcritical+1))

        elif [[ "${check[$i]}" = "unknown" || "${check[$i]}" = "nodata" || "${check[$i]}" = "uninitialized" ]] ; then
                echo "UNKNOWN | Der Status der Komponente ist: ${check[$i]}"
                anzahlunknown=$((anzahlunknown+1))


        else
               echo "Der Status der Komponente ist nicht feststellbar"
        fi
done

#echo $gesamtanzahl
#echo $anzahlok
#echo $anzahlready
#echo $anzahlup
#echo $anzahlwarning
#echo $anzahlcritical
#echo $anzahlfault
#echo $anzahlempty
#echo $anzahlfault_absent
#echo $anzahlfault_input
#echo $anzahlfault_output
#echo $anzahlfault_poe
#echo $anzahlfault_norecov
#echo $anzahlalert
#echo $anzahlunknown
#echo $anzahlunsupported
#echo $anzahldown

#set -x
     if [[ $gesamtanzahl -eq $anzahlok ]] ; then
                exitCode=0

     elif [[ $anzahlwarning -gt 0  ]] ; then
                exitCode=1

     elif [[ $anzahlcritical -gt 0  ]] ; then
                exitCode=2

     elif [[ $anzahlunknown -gt 0  ]] ; then
                exitCode=3

     else
                exitCode=3
fi

#echo $exitCode

#Logout
curl -k -s -X POST -b /tmp/auth_cookie_$hostname "https://$hostname/rest/v10.04/logout"

exit $exitCode
#set +x
