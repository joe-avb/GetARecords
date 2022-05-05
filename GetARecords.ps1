#!/bin/pswh
#################################################################
#  This script takes import from a CSV containing a url and
#  gets the A records for that domain. Input file is selected
#  as the -csvfile parameter, and output file is DnsARecord.csv
#  which will be saved in the directory that the script is run
#  in.
#
#  ex. PS> .\GetARecords.ps1 -csvfile website-list.csv
#################################################################
param (
    [parameter(Mandatory, HelpMessage = "Please provide the path and filename")]
    [string] $csvfile
)


$UrlImport = Import-Csv $csvfile
foreach ($u in $UrlImport) {
    [uri]$URL = $u.url
    $domain = Resolve-DnsName -Type SOA $URL.Authority | Select-Object -Property NameHost
    if ($domain.NameHost -eq $Null) {
        $domain = Resolve-DnsName -Type SOA $URL.Authority | Select-Object -Property Name
        $domain = $domain.Name | Out-String
    }
    else {
        $domain = $domain.Namehost | Out-String
    }
    $domain.trim()
    $DnsAList += Resolve-DnsName $domain.trim() 
} 

$DnsAListSorted = $DnsAList |
Select-Object -Unique Name,@{N='IP_1';E={$_.IPAddress}} |
Sort-Object -Property Name,IP_1 
$convRecords = [System.Linq.Enumerable]::Aggregate($DnsAListSorted, [System.Func[System.Object, System.Object, System.Object]]{
  $args[0]

  $procDomName = $args[1].Name
  $chkDom = $args[0] | Where-Object { $_.Name -eq $procDomName }

  if ($chkDom) {
    [Int]$idx = 1

    do {
      $idx++
    } while ($chkDom."IP_$idx")
    
    Add-Member -InputObject $chkDom -NotePropertyName ("IP_$idx") -NotePropertyValue $args[1].IP_1
  } else {
    $args[1]
  }
})
[Int]$maxIdx = 1

$convRecordsCompleted = $convRecords | Sort-Object { $_.PSObject.Properties.Count } -Descending | ForEach-Object {
  if ($maxIdx -eq 1) { # As per the sort definition, the first object processed is the one with the most properties, which in turn means the most IP_* properties
    # Let's extract the highest index value from the said first object
    foreach ($prop in $_.PSObject.Properties) {
      if ($prop.MemberType -eq "NoteProperty") {
        if ($prop.Name -like "IP_*") {
          $idx = [Int]$prop.Name.Substring($prop.Name.IndexOf("_") + 1)
          if ($idx -gt $maxIdx) {
            $maxIdx = $idx
          }
        }
      }
    }
  } else {
    # As soon as the highest index value has been extracted (see above), we're able to add "missing" IP_* properties to the rest of the objects as required
    for ($idx = 2; $idx -le $maxIdx; $idx++) {
      if (-not $_."IP_$idx") {
        Add-Member -InputObject $_ -NotePropertyName ("IP_$idx") -NotePropertyValue ""
      }
    }
  }

  return $_
}

$convRecordsCompleted | Export-Csv -Path ".\DnsAList.csv"
