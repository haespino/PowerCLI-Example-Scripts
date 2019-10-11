﻿
<#==================================================
 Generated On: 6/27/2014 2:49 PM
 Generated By: Brian Graf
 VMware Technical Marketing Engineer - Automation
 Organization: VMware
 vCenter Sysprep File Transfer 
==================================================
--------------------------------------------------
==================USAGE===========================
 This script has been created to aid users who
 upload multiple sysprep files to vCenter Server.
 The upload button in vCenter only allows a single
 file per upload. This script will allow the user
 to upload as many files as they please.
--------------------------------------------------
===============REQUIREMENTS=======================
 Fill in the environment variables below. There
 Is a $DefaultVIServer and a $target_vcenter. 
 This is because some customers may be running 
 their target vCenter server within a different
 vCenter environment.
 
 On your local machine, you will need a directory
 that includes the following folders:
 * 2k
 * svr2003-64
 * svr2003
 * xp
 * 1.1
 * xp-64
 
 Place all sysprep files within their respective
 folders.
 
 Run the script. The script will determine if
 the target_vCenter is a Windows VM or VCSA
 and place the files accordingly.
 
 ***NOTE*** This script will give an error if 
 it tries to upload a filename that already exists
 in the vCenter directory. If you wish for the 
 script to overwrite any file with the same name
 add '-force' to the end of the copy-vmguestfile
 command.
--------------------------------------------------
#>

# ----------------------------------------
#   USER CONFIGURATION - EDIT AS NEEDED
# TEST HE
# ----------------------------------------
$DefaultVIServer = "vcsa.lab.local"
$vCUser = "root"
$vCPass = "VMware1!"
$target_vcenter = "VCSA"
$target_vcenter_user = "root"
$target_vcenter_password = "VMware1!"
$Location = "C:\temp"
$vC_Partition = "C:"
# ----------------------------------------
#  END USER CONFIGURATION
# ----------------------------------------

# Sysprep Folders on vCenter 
$folders = @("2k","svr2003-64","svr2003","xp","1.1","xp-64")

# Add PowerCLI Snapin
Add-PSSnapin vmware.vimautomation.core

# Connect to vCenter
connect-viserver $DefaultVIServer -user $vCUser -password $vCPass

# Get view of the vCenter data
$myVC= get-vm $target_vcenter | get-view

# $OS captures the Operating System Name
$OS = $myVC.config.GuestFullName

# Switch of Operating System
switch -wildcard ($OS)
{
# As per the compatibility guide, all OS's from the compatibility guide have been added
"*SUSE*" {Write-Host "This is a SUSE Machine" -ForegroundColor Green; $OS = "VCSA"}
"* XP *" {Write-Host "This is a Windows XP Machine" -ForegroundColor Green}
"* 2003 *" {Write-Host "This is a Windows Server 2003 Machine" -ForegroundColor Green}
"* 2008 *" {Write-Host "This is a Windows Server 2008 Machine" -ForegroundColor Green}
"* 2012 *" {Write-Host "This is a Windows Server 2012 Machine" -ForegroundColor Green}
Default {Write-Host "This is the default" -ForegroundColor Green}
}
Write-Host ""

# If Location is not set, ask user to input location
if ($Location -eq ""){
$Location = Read-Host "Where is the sysprep file located? (ex. c:\temp) "
}

# Cycle through Sysprep Folders on local machine
foreach($folder in $folders){
if ($OS -eq "VCSA"){$Destination = "/etc/vmware-vpx/sysprep/$folder"} else {$Destination = "$vC_Partition\ProgramData\VMware\VMware VirtualCenter\Sysprep\$folder"}

# Get files from each folder
Get-ChildItem "$($Location)\$($folder)" -ErrorAction SilentlyContinue | ForEach-Object {
$source = "$($Location)\$($folder)\$_"

Write-Host "Transferring File `"$_`" " -ForegroundColor Green #Source = $source" -ForegroundColor Green
Write-Host "Destination = $Destination" -ForegroundColor Green

# Copy Files to vCenter Sysprep folders
Copy-vmguestfile -source "$source" -Destination "$Destination" -VM "$target_vcenter" -LocalToGuest -GuestUser "$target_vcenter_user" -GuestPassword "$target_vcenter_password"

}
}
Disconnect-viServer -confirm:$false
