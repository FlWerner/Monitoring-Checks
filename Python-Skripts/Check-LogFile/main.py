#!/usr/bin/env python3

import argparse
import os.path
import sys
from builtins import print

__version__ = '1.0'




def check_file(logdatei):
    if logdatei is None:
        print("Kein Pfad vorhanden")
        exit(3)

    if not os.path.isfile(logdatei):
        print("Kein Gültiger Pfad vorhanden")
        exit(3)


def check_event(event):
    if event is None:
        print("Keine Event Übergeben")
        exit(3)


def check_log(args):
    path = args.logdatei
    event = args.event


    check_file(path)
    check_event(args.event)

    filetoday = open(path)
    filetodaycount = 0
    eventtoday = ""

    fileyesterday = open(path + ".1")
    fileyesterdaycount = 0
    eventyesterday = ""

    for line in filetoday:
        if event in line:
            filetodaycount += 1
            eventtoday = line

    for line in fileyesterday:
        if event in line:
            fileyesterdaycount += 1
            eventyesterday = line


    if filetodaycount == 0 and fileyesterdaycount == 0:
        print("Log Eintrag erfolgreich geprüft - keine passende Einträge gefunden")
        exit(0)

    elif fileyesterdaycount > 0 and filetodaycount > 0:
        totalcount = fileyesterdaycount+ filetodaycount
        print("In dem heutigen und in dem rotierten LOG wurden (" + str(totalcount) + ")")
        print("Letzte Eintrag heute: " + eventtoday)
        exit(2)

    elif filetodaycount > 0 and fileyesterdaycount == 0:
        print("In dem heutigen LOG wurden (" + str(filetodaycount) + ") Treffer gefunden. Der letzte Eintrag:")
        print(eventtoday)
        exit(2)

    elif fileyesterdaycount > 0 and filetodaycount == 0:
        print("Im rotierten LOG wurden (" + str(fileyesterdaycount) + ") Treffer gefunden. Der letzte Eintrag: ")
        print(eventyesterday)
        exit(2)
    else:
        print("Problem")
        exit(3)


if __name__ == '__main__':
    try:
        parser = argparse.ArgumentParser()
        parser.add_argument('-V', '--version', action='version',
                            version='%(prog)s v' + sys.modules[__name__].__version__)
        parser.add_argument('-L', '--logdatei', help='Pfad + Logfile', required=True)
        parser.add_argument('-E', '--event', required=True)

        args = parser.parse_args()
        check_log(args)

    except Exception:
        print("Fehler in der Ausführung")
        exit(3)

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
