#!/bin/bash
# Nutzung:   /usr/lib/nagios/plugins/check_galera_node_size.sh -u <user> -p <passwort> -a <anzahl>
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
        echo "Usage: $PROGNAME [-u] [-p] [-a] [-v] [-V] [-h] "
        echo
        echo " -u User"
        echo " -p Passwort"
        echo
        echo " -a Anzahl der Galera Nodes"
        echo " -v verbose output"
        echo " -V Version"
        echo " -h Hilfe"
        echo
        echo " Script um die Anzahl der Nodes im Galera Cluster abzufragen"
        echo
}

printVersion() {
        echo
        echo "$PROGNAME Version $VERSION"
        echo
}

checkOptions() {
   while getopts "u:p:a:vVh" OPTIONS $@; do
      case $OPTIONS in
        u) user=$OPTARG
           ;;
        p) passwort=$OPTARG
           ;;
        a) anzahl=$OPTARG
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

groesse=$anzahl
#echo $groesse

data=$(mysql -u$user -p$passwort --execute="SHOW STATUS LIKE 'wsrep%';" | grep wsrep_cluster_size)
#echo $data

# Set data
data1=$(echo $data | awk '{print $2}')
#echo $data1

        if [[ -z $data1 ]]; then
                        echo -n "Kritisch | Es ist ein Fehler beim Script aufgetreten"
                        exitCode=2
        elif  [[ $groesse -eq $data1 ]] ; then
                        echo -n "OK | Die Anzahl der Nodes im Galera Clusters beträgt $data1"
                          exitCode=0
        elif [[ $groesse -ne $data1 ]]; then
                        echo -n "Warnung | Die Anzahl der Nodes im Cluster weicht von der angegebenen Variablen -a ab"
                        exitCode=1
        elif [[ $data1 -eq 1 ]]; then
                        echo -n "Kritisch | Die Anzahl der Nodes im Galera Clusters beträgt $data1"
                        exitCode=2
        else
                        echo -n "UNKNOWN - Keine Ermittlung des Status!"
                        exitCode=3
        fi

        echo ""
        echo -n "Die Anzahl der Nodes im Cluster: '$data1'"

exit $exitCode
