# Icinga2 Variablen
$jobname = $args[0]
#$jobname = "TAPE_Tapesicherung_(CLU_Agent_3M_VOLA2)"

# Datenabfrage
$daten=(Get-VBRTapeJob -Name $jobname)

# Schleife
if ($daten.LastResult -match "Warning")
    {
      Write-Host "Job Name:" $daten.Name
      echo "Warnung - Backup hat ein Fehler"
      $returnCode=1
      }
elseif ($daten.LastResult -match "None")
    {
      Write-Host "Job Name:" $daten.Name
      echo "Warnung - Backup liefert momentan den Wert None zurück"
      $returnCode=1
      }
elseif ($daten.LastResult -match "Failed")
    {
      Write-Host "Job Name:" $daten.Name
      echo "Kritisch - Fehler im Backup"
      $returnCode=2
      }
elseif ($daten.LastResult -match "Success")
    {
      Write-Host "Job Name:" $daten.Name 
      echo "OK - Kein Fehler im Backup"
      $returnCode=0
      }
else
    {
       echo "Achtung - Es gibt ein Fehler im Script"
       $returnCode=3
       }

exit ($returnCode)

