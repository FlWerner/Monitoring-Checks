### Die Systemsprachenparameter festlegen
if (([cultureInfo]::InstalledUICulture).Name -eq "de-DE")
{
  $Parameter='Anforderungs-ID','Seriennummer','Ablaufdatum des Zertifikats','Antragstellername','Benutzer­prinzipal­name','Sperrungsgrund','Zertifikatvorlagen','Ausgestellter Name'
}
elseif (([cultureInfo]::InstalledUICulture).Name -eq "en-US") 
{
  $Parameter='Request ID','Serial Number','Certificate Expiration Date','Requester Name','User Principal Name','Revocation Reason','Certificate Template','Issued Common Name'
}
else
{
  Write-Warning "System nicht geeignet. Bitte die Ausgabe von Certutil ansehen und die Parameter anpassen"
  Exit
}

### Ablaufdatum Zeitraum in Tagen ab heute bitte unter $tage eintragen
$tage = 96

### Tabelle
$table = @()

### Datum abfragen und Zeitraum aufrechnen
$heute = Get-Date
$heuteplus = $heute.AddDays($tage)

### Werte der Zertifikate mit den Parametern aus der CA auslesen
### es werden keine Werte mit leeren Ablaufdatum/Certificate Expiration Date oder mit befüllten Sperrungsgrund/Revocation Reason eingelesen  
$cert=certutil.exe -view csv | ConvertFrom-Csv | Where-Object {($_."Certificate Expiration Date" -notcontains 'LEER') -and ($_."Certificate Expiration Date" -notcontains 'EMPTY') -and ($_."Revocation Reason" -contains 'EMPTY')} | Select-Object -Property $Parameter[0],$Parameter[1],$Parameter[2],$Parameter[3],$Parameter[4],$Parameter[5],$Parameter[6],$Parameter[7]

### Schleife fuer die Datenabfrage
foreach ($date in $cert){

### Parameter einlesen
$par0=$date."Request ID"
$par1=$date."Serial Number"
$par2=$date."Certificate Expiration Date"
$par3=$date."Requester Name"
$par4=$date."User Principal Name"
$par5=$date."Renewed"
$par6=$date."Certificate Template"
$par7=$date."Issued Common Name"

### hier wird nur der Wert Web und der Wert Kerberos aus den Certificate Templates herausgefiltert
if (($par6 -match "Web") -or ($par6 -match "Kerberos"))
{

### hier wird nur der Wert Ablaufdatum herausgefiltert
$date=$date."Certificate Expiration Date"
### hier werden die richtigen Datumsformate gesetzt
$datumrichtig = [DateTime]::ParseExact($par2, "g", $null)

if  ($datumrichtig -gt $heute -and  $datumrichtig -lt $heuteplus)
{
  $table += "`n" + "Request ID:`t" + $par0 + "`n" + "Certificate Expiration Date:`t" + $par2 + "`n" + "Issued Common Name:`t" + $par7 + "`n" + "`n" + "Certificate Template:`t" + $par6 + "`n" + "Revocation Reason:`t" + $par5 + "`n"
}
}
}

### hier wird ab einem Zertifikat eine Warnung ausgegeben
if ($table.Count -eq 1)
{
  echo "WARNUNG - Bitte Zertifikat erneuern"
  Write-Host $table
  $returnCode=1
}
### hier wird ab einem zusaetzlichen Zertifikat eine kritische Meldung ausgegeben
elseif ($table.Count -gt 1)
{

  echo "Kritisch - Mehr als 1 Zertifikat muss erneuert werden"
  Write-Host $table
  $returnCode=2
}

else
{
  echo "OK - Keine Zertifikate die nach $monate Monaten ablaufen"
  $returnCode=0
}
	 
exit ($returnCode)
