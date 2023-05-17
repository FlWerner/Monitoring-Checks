#!/bin/bash
# Nutzung:   /usr/lib/nagios/plugins/check_log_isp -l <logdateipfad> -e <logeintrag>
# Das Script prüft die Log-Datei <logdateipfad> auf einen Eintrag <logeintrag>
#
# Voraussetzung Linux Client:
# Software: apt install bc
# Es sollte logrotate auf der Log-Datei <logdateipfad> laufen
# logrotate sollte so eingestellt sein das die Verzeichnisstruktur so aussieht:
# -rw-r--r-- 1 syslog adm         0 Sep 29 06:25 10.99.68.111.log
# -rw-r--r-- 1 syslog adm     11191 Sep 28 15:39 10.99.68.111.log.1
# Wichtig ist hier der aktuelle Eintrag mit *.log und der Eintrag *.log.1
# Wenn logrotate leere logs nicht rotiert (*.log) wird ein Fehler weiterhin angezeigt wenn er in der rotierten Datei (*.log.1) steht.
# Dies kann mit diesem Befehl auf dem Server manuell rotiert werden. Beispiel: logrotate -df /etc/logrotate.d/nginx
#
# Voraussetzung Syslog Server:
# Der Satellit mus als Syslog Server (rsyslogd) eingerichtet werden um Logs empfangen zu können.
# Der Port 514 UDP muss zwischen dem Satellit und dem sendenden Server frei sein.
# Der neue log Ordner des sendenden Servers auf dem Satellit muss ins logrotate aufgenommen werden.
# Das zu überwachende System muss zum Satellit die erforderlichen Logs versenden.
#
# Bitte beachten:
# Durch logrotate wird die zu überwachende Datei jeden morgen (ca. 6:30 Uhr) erneuert.
# Dadurch ist ein vorhandener Eintrag wieder verschwunden (falls das System einen Fehler nur einmalig meldet) und diese Meldung wandert in die Datei *.log.1
# Das Script prüft beide Dateien *.log *.log.1 auf den logeintrag.
# Das bedeutet im Icinga2 ist die Meldung 2 Tage bis diese durch die Rotation wieder verschwindet, falls das System einen Fehler nur einmalig meldet.
#

setzepfade() {
P1="/usr/local/sbin"
P2="/usr/local/bin"
P3="/sbin"
P4="/bin"
P5="/usr/sbin"
P6="/usr/bin"
P7="/usr/lib/nagios/plugins"

# prüfe ob vorhanden
if [ -d $P1 ] && [ -d $P2 ] && [ -d $P3 ] && [ -d $P4 ] && [ -d $P5 ] && [ -d $P6 ] && [ -d $P7 ] ; then
   PATH="$P1:$P2:$P3:$P4:$P5:$P6:$P7"
else
   echo "Ein wichtiges Verzeichnis ist nicht vorhanden"
   exit
fi

# pfade setzen
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
   echo "Usage: $PROGNAME [-l] [-e] [--Version] [-h | ? | --help] "
   echo
   echo " -l oder --logdateipfad Logdatei Ordnerpfad "
   echo " -e oder --logeintrag Logeintrag gesucht "
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

# Script vorbereiten
setzepfade
tooleinlesen

# Argumente einlesen
argumente=()

while [[ $# -gt 0 ]]; do # wenn wir -l WERT und -e WERT haben, ist die Zahl 4
  case $1 in
    -l|--logdateipfad)
       logdateipfad="$2"   # wir haben zwei Argumente zu verarbeiten deshalb $2 Beispiel: ./check_log_isp -l <logdateipfad> -e <logeintrag>
       shift # verschieben von $2 nach $1 alle Argumente landen zwangsläufig in $1
       ;;
    -e|--logeintrag)
       logeintrag="$2"     # wir haben zwei Argumente zu verarbeiten deshalb $2
       shift # verschieben von $2 nach $1 alle Argumente landen zwangsläufig in $1
      ;;
    -h|-?|--help)
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
      argumente+=("$1") # speichern der argumente und von der Zahl 4 herunterzählen
      shift # verschieben von $1
      ;;
  esac
done

checkOptions() {
if [[ -z $logdateipfad ]] || [[ -z $logeintrag ]] ; then
   printHelp
   exit $STATE_UNKNOWN
elif [[ ! -e $logdateipfad ]] ; then
   echo "Problem: Die Datei $logdateipath existiert nicht! Bitte Vorraussetzungen prüfen"
   exit $STATE_UNKNOWN
elif [ ! -r $logdateipfad ] ; then
   echo "Problem: Die Datei $logdateipath kann nicht gelesen werden! Bitte prüfen"
   exit $STATE_UNKNOWN
fi
}

# Prüfungen
checkOptions

# Treffer suchen
anzahltrefferheute=$(grep -c "${logeintrag}" ${logdateipfad})
anzahltreffergestern=$(grep -c "${logeintrag}" ${logdateipfad}.1)
letztereintragheute=$(grep "${logeintrag}" ${logdateipfad} | tail -1)
letztereintraggestern=$(grep "${logeintrag}" ${logdateipfad}.1 | tail -1)
anzahlgesamt=$(echo "$anzahltrefferheute + $anzahltreffergestern" | bc -l )

if [[ "$anzahltrefferheute" = "0" ]] && [[ "$anzahltreffergestern" = "0" ]] ; then
    echo "Log Eintrag erfolgreich geprüft - keine passende Einträge gefunden"
    exit $STATE_OK
elif [[ "$anzahltrefferheute" > "0" ]] && [[ "$anzahltreffergestern" = "0" ]] ; then
    echo " In dem heutigen LOG wurden ($anzahltrefferheute) Treffer gefunden. Der letzte Eintrag:  $letztereintragheute "
    exit $STATE_CRITICAL
elif [[ "$anzahltrefferheute" = "0" ]] && [[ "$anzahltreffergestern" > "0" ]] ; then
    echo " Im rotierten LOG wurden ($anzahltreffergestern) Treffer gefunden. Der letzte Eintrag:  $letztereintraggestern "
    exit $STATE_CRITICAL
elif [[ "$anzahltrefferheute" > "0" ]] && [[ "$anzahltreffergestern" > "0" ]] ; then
    echo " In dem heutigen und in dem rotierten LOG wurden ($anzahlgesamt) Treffer gefunden. Der letzte Eintrag:  $letztereintragheute "
    exit $STATE_CRITICAL

else
    echo "Problem"
    exit $STATE_UNKNOWN
fi
