<#********************************************Description********************************************

This script is an example of how to use Find-HPiLO to find all the iLO servers 
within a server IP Range.

***************************************************************************************************#>

#Example 1: Find-HPiLO with a single IP address:
Find-HPiLO 192.168.1.1

#Example 2: Find-HPiLO with a search range 
#(if a comma is included in the range, double quotes are required)
Find-HPiLO 192.168.1.1-11
Find-HPiLO -Range “192.168.1.1,15"
Find-HPiLO -Range “192.168.217,216.93,103”
Find-HPiLO -Range “192.168.1.1,15"

#Example 3: Piping output from Find-HPiLO to another cmdlet
Find-HPiLO 192.168.217.97-103 -Verbose |
% {Add-Member -PassThru -InputObject $_ Username "username"}|
% {Add-Member -PassThru -InputObject $_ Password "password"}|
Get-HPiLOFirmwareVersion -Verbose