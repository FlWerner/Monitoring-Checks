#!/bin/bash
# Nutzung:   /usr/lib/nagios/plugins/check_galera_node_status.sh -u <user> -p <passwort> 
# Voraussetzung: lesender User in mariadb; galera4; awk

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
export PATH
PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
VERSION=1.0
VERBOSE=0

. $PROGPATH/utils.sh

printHelp() {
        echo
        echo "Usage: $PROGNAME [-u] [-p] [-v] [-V] [-h] "
        echo
        echo " -u User"
        echo " -p Passwort"
        echo 
        echo " -v verbose output"
        echo " -V Version"
        echo " -h Hilfe"
        echo
        echo " Script für mariadb um Abfragen zum Status des Clusters des lokalen Galera Node zu erhalten"
        echo
}

printVersion() {
        echo
        echo "$PROGNAME Version $VERSION"
        echo
}

checkOptions() {
   while getopts "u:p:vVh" OPTIONS $@; do
      case $OPTIONS in
         u) user=$OPTARG
            ;;
         p) passwort=$OPTARG
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

data=$(mysql -u$user -p$passwort --execute="SHOW STATUS LIKE 'wsrep%';" | grep wsrep_cluster_status)
#echo $data

# Set data
data1=$(echo $data | awk '{print $2}')
#echo $data1

        if [[ $data1 = "Primary" ]] ; then
                        echo -n "Node is connected to the Primary Component"
                          exitCode=0
        elif [[ $data1 = "Disconnected" ]]; then
                        echo -n "Node is not connected to the Primary Component"
                        exitCode=1
        elif [[ $data1 = "Non-Primary" ]]; then
                        echo -n "Node is not connected to the Primary Component"
                        exitCode=2
        else
                        echo -n "UNKNOWN - Keine Ermittlung des Status!"
                        exitCode=3
        fi
        
        echo ""
        echo -n "The Node Status: '$data1'"

exit $exitCode
