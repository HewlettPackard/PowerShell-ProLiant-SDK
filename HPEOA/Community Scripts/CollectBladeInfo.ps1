# A sample script to collect general blade info from a list of OAs (20170131)
#
# Step 1:  Save this script on the server with OA Cmdlts loaded
#
# Step 2: create a CSV file with OA info (headers: "IP", "UserName", "Password") 
#   IP,      Username,     Password
#  10.1.1.20,Administrator,mypassword
#  10.1.1.21,Administrator,mypassword
#
# Step 3:  run this PS script with 1 param, the CSV file name
#
#    > .\CollectBladeInfo.ps1 .\myOAs.csv
#
# Step 4:  Review results
#    The new "output" file will be in the same directory as input file
#     example:  .\myOAs-output.csv

Param(
  [string]$OAListFile  
)

if ( -not (Test-path $OAListFile)) 
{
  write-host  "`n  Parameter of 'CSV file' not valid!   '$OAListFile' `n"
  exit
}

# Import/load the HPE OA Cmdlet
Import-Module HPOACmdlets

# Read in the CSV content
write-host "`n Reading $($OAListFile) file.... "
$OA_List = Import-Csv $OAListFile

# Set output CSV file name
$outputfile = "$((Get-Item $OAListFile).Basename)-output.csv"

# Delete output file if already exists
if (Test-Path $outputfile)
{ 
    Remove-Item $outputfile
}

# Loop through each OA specified in CSV file
foreach ( $OA in $OA_List ) 
{
    write-host "`n Connecting to OA  - $($OA.IP) using user name: $($OA.UserName)  (this may take a few secs...) "
    $OAConnection = Connect-HPOA -OA $OA.IP -Password $OA.Password -Username $OA.UserName 
    if ($?)  # Check if the above connect command was successful
    {
        if ( $((Get-HPOAStatus -Connection $OAConnection).OnboardAdministrator.Role) -like "Active" ) 
        {
            write-host "      gathering blade info.... "
            $OACollectData = Get-HPOAServerInfo -Connection $OAConnection
            write-host "        writing information to csv file '$outputfile'  "
            $OACollectData.ServerBlade | select @{Name='OA';Expression={$($OA.IP)}}, Bay, Type, ProductName, PartNumber, SerialNumber, Memory | Export-Csv -Append $outputfile -notypeinformation   
            write-host "         disconnecting from OA. "
            Disconnect-HPOA -Connection $OAConnection  
        } 
        else 
        {
            write-host "    OA status is not 'Active', OA skipped. "
        }
    }
    else 
    {
        write-host "    Failed to connect to $($OA.IP) using user name: $($OA.UserName)  OA skipped. "
    }
}
