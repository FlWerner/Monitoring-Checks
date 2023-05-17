#!/usr/bin/env python3
import argparse
import requests
from requests.auth import HTTPBasicAuth
import sys
import urllib3

__version__ = '0.2'


urllib3.disable_warnings()

output_is_ok = []
output_is_warning = []
output_is_critical =[]

def check_input(input, typ):
    if input is None:
        print("Fehlerhafte eingabe, Bitte Wert: " + typ+ " eingeben.")
        exit(3)


def print_system(stateDefinition, stateID):
    if output_is_ok != []:
        for object in output_is_ok:
            print(stateDefinition + " ID: " + str(object[stateID]) + " is " +str(object["status"])+ ".-- Airflow: " + str(object["air-flow"]))

    if output_is_critical == [] and output_is_warning != []:
        for object in output_is_warning:
            print(stateDefinition + " ID: " + str(object[stateID]) + " is " +str(object["status"])+ ".-- Airflow: " + str(object["air-flow"]))
        exit(1)

    elif output_is_critical != [] and output_is_warning == []:
        for object in output_is_critical:
            print(stateDefinition + " ID: " + str(object[stateID]) + " is " +str(object["status"])+ ".-- Airflow: " + str(object["air-flow"]))
        exit(2)

    elif output_is_critical != [] and output_is_warning != []:
        for object in output_is_warning:
            print(stateDefinition + " ID: " + str(object[stateID]) + " is " +str(object["status"])+ ".-- Airflow: " + str(object["air-flow"]))
        for psu in output_is_critical:
            print(stateDefinition + " ID: " + str(object[stateID]) + " is " +str(object["status"])+ ".-- Airflow: " + str(object["air-flow"]))
        exit(2)


def print_environment():
    if output_is_ok != []:
        for object in output_is_ok:
            print("Thermalsensor: " + str(object["sensor-name"]) + " hat folgende Temperatur: " + str(object["sensor-temp"]) + " Celsius")

    if output_is_critical == [] and output_is_warning != []:
        for object in output_is_warning:
            print("Thermalsensor: " + str(object["sensor-name"]) + " hat folgende Temperatur: " + str(object["sensor-temp"]) + " Celsius -> Warning")
        exit(1)
    elif output_is_critical != [] and output_is_warning == []:
        for object in output_is_critical:
            print("Thermalsensor: " + str(object["sensor-name"]) + " hat folgende Temperatur: " + str(object["sensor-temp"]) + " Celsius -> Critical")
        exit(2)
    elif output_is_critical != [] and output_is_warning != []:
        for object in output_is_warning:
            print("Thermalsensor: " + str(object["sensor-name"]) + " hat folgende Temperatur: " + str(object["sensor-temp"]) + " Celsius -> Warning")
        for object in output_is_critical:
            print("Thermalsensor: " + str(object["sensor-name"]) + " hat folgende Temperatur: " + str(object["sensor-temp"]) + " Celsius -> Critical")
        exit(2)
    exit(0)

def print_interface():
    if output_is_ok != []:
        for object in output_is_ok:
            print("Interface: " + str(object["name"]) + " ADMIN-State: " + str(object["admin-status"]) + " + Oper-State: " + str(object["oper-status"]))
            exit(0)

    if output_is_critical == [] and output_is_warning != []:
        for object in output_is_warning:
            statistics = object["statistics"]
            errors = int(statistics["in-errors"])
            discards = int(statistics["in-discards"])
            print("Interface: "+ str(object["name"]) + " - Paketfehler: IN-Discards: "+ str(discards) + " IN-Error: " + str(errors))
            exit(1)

    elif output_is_critical != []:
        for object in output_is_critical:
            print("Interface: "+ str(object["name"]) + " ADMIN-State: " + str(object["admin-status"]) + " + Oper-State: " + str(object["oper-status"]))
            exit(2)


def check_system(output, device):
    for object in output[device]:
        if object["status"] == "up" and object["air-flow"] == "NORMAL":
            output_is_ok.append(object)
        elif object["status"] == "up" or object["air-flow"] != "NORMAL":
            output_is_warning.append(object)
        elif object["status"] != "up" or object["air-flow"] == "NORMAL":
            output_is_critical.append(object)
        elif object["status"] != "up" or object["air-flow"] != "NORMAL":
            output_is_critical.append(object)

def check_environment(output, device):
    for object in output[device]:
        if object["sensor-temp"] >= 60:
            output_is_critical.append(object)
        elif object["sensor-temp"] >= 50:
            output_is_warning.append(object)
        else:
            output_is_ok.append(object)

def check_interface(output, device):
    for interface in output[device]:
        if interface["admin-status"] != "up" or interface["oper-status"] != "up":
            output_is_critical.append(interface)

        statistics = interface["statistics"]
        errors = int(statistics["in-errors"])
        discards = int(statistics["in-discards"])

        if errors >= 1 or discards >= 1:
            output_is_warning.append(interface)

        else:
            output_is_ok.append(interface)


def httpRequest(url, auth):
    try:
        res = requests.get(url, auth=auth, verify=False)
        output = res.json()
        return output
    except Exception:
        print("Das kommt später")


def main(args):
    user = args.user
    password = args.password
    host = args.host
    device = args.device

    

    auth = HTTPBasicAuth(username= user, password=password)

    if device == "power-supply":
        url = "https://"+host+"/restconf/data/dell-equipment:system/node/"+device
        output = httpRequest(url, auth)
        check_system(output, "dell-equipment:power-supply")
        print_system("Powersupply-Unit", "psu-id")

    elif device == "fan-tray":
        url = "https://"+host+"/restconf/data/dell-equipment:system/node/"+device
        output = httpRequest(url, auth)
        check_system(output, "dell-equipment:fan-tray")
        print_system("Fan-Tray", "fan-tray-id")

    elif device == "thermal-sensor":
        url = "https://"+host+"/restconf/data/dell-equipment:system/environment/thermal-sensor"
        output = httpRequest(url, auth)
        check_environment(output, "dell-equipment:thermal-sensor")
        print_environment()

    elif device == "interface":
        interface = args.interface
        interface = interface.replace("/", "%2F")
        url = "https://"+host+"/restconf/data/ietf-interfaces:interfaces-state/interface="+ interface
        output = httpRequest(url, auth)
        check_interface(output, "ietf-interfaces:interface")
        print_interface()

    else:
        print("Fehler beim Ausführen")
        exit(3)

if __name__ == '__main__':
    try:

        parser = argparse.ArgumentParser()
        parser.add_argument('-V', '--version', action='version', version='%(prog)s v' + sys.modules[__name__].__version__)
        parser.add_argument('-U', '--user', required=True)
        parser.add_argument('-P', '--password', required=True)
        parser.add_argument('-H', '--host', required=True)
        parser.add_argument('-D', '--device', required=True, choices=["power-supply", "fan-tray", "thermal-sensor", "interface"])
        parser.add_argument('-I', '--interface', help="Wird nur bei der Auswahl von Interfaces benötigt")

        args = parser.parse_args()
        check_input(args.device, "Device")
        check_input(args.user, "Benutzer")
        check_input(args.password, "Passwort")
        check_input(args.host, "Host")

        if (args.device == "interface"):
            check_input(args.interface, "interface")

        main(args)

    except Exception as e:
        print("Fehler bei der Ausführung")
        print(str(e))
        exit(3)

