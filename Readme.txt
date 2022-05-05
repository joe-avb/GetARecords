Unzip these files to their own folder. 
Contains the script and a sample input file.

This script takes import from a CSV containing a url and
gets the A records for that domain. Input file is selected
as the -csvfile parameter, and output file is DnsARecord.csv
which will be saved in the directory that the script is run
in.

ex. 
PS> .\GetARecords.ps1 -csvfile website-list.csv