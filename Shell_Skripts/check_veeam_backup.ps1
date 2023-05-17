# Icinga2 Variablen
$jobname = $args[0]

# Datenabfrage
$daten = Get-VBRJob -WarningAction SilentlyContinue | ?{$_.Name -eq $jobname}
$datentape = Get-VBRTapeJob -WarningAction SilentlyContinue | ?{$_.Name -eq $jobname}
$statustape = $datentape | select -ExpandProperty "LastResult"
$statustape1 = $datentape | select -ExpandProperty "LastState"

# Schleife
if (($daten.Info.LatestStatus -match "Warning") -or ($statustape -match "Warning"))
    {
      Write-Host "Job Name:" $daten.Name $datentape.Name
      echo "Warnung - Backup hat ein Fehler"
      $returnCode=1
      }
elseif (($daten.Info.LatestStatus -match "Failed") -or ($statustape -match "Failed"))
    {
      Write-Host "Job Name:" $daten.Name $datentape.Name
      echo "Kritisch - Fehler im Backup"
      $returnCode=2
      }
elseif (($daten.Info.LatestStatus -match "Error") -or ($statustape -match "Error"))
    {
      Write-Host "Job Name:" $daten.Name $datentape.Name
      echo "Kritisch - Fehler im Backup"
      $returnCode=2
      }
elseif (($daten.Info.LatestStatus -match "Success") -or ($statustape -match "Success"))
    {
      Write-Host "Job Name:" $daten.Name $datentape.Name
      echo "OK - Kein Fehler im Backup"
      $returnCode=0
      }
elseif (($daten.Info.LatestStatus -match "Working") -or ($statustape1 -match "Working"))
    {
      Write-Host "Job Name:" $daten.Name $datentape.Name
      echo "OK - Der Backup Job arbeitet gerade"
      $returnCode=0
      }
else
    {
       echo "Achtung - Es gibt ein Fehler im Script"
       $returnCode=3
       }

exit ($returnCode)
