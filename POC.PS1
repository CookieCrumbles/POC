cls
$DebugPreference = "Continue"
$VerbosePreference = "Continue"
#https://gallery.technet.microsoft.com/scriptcenter/Powershell-printer-config-db0465bd
#https://serverfault.com/questions/833951/exporting-and-importing-printer-settings-using-powershell
#https://stackoverflow.com/questions/26380502/get-and-set-printer-acl-in-powershell
$input = read-host "Input networkprinter IP-address (found on the label of the printer)"
$portname = Read-Host "Input portname"
#---------------------------------------------------------------------------------------------------------#

Write-debug "Moving default printer assignment..."
(Get-WmiObject -Class Win32_Printer -Filter "Name='Microsoft Print to PDF'").SetDefaultPrinter() | Out-Null
sleep 2
#---------------------------------------------------------------------------------------------------------#

Write-debug "Removing existing loketprinter..."
Remove-Printer -Name "Loketprinter" -ErrorAction SilentlyContinue
#---------------------------------------------------------------------------------------------------------#

Write-debug "Removing printerport..."
Remove-PrinterPort  -Name "$input" -ComputerName ($env:COMPUTERNAME) -ErrorAction SilentlyContinue
sleep 10 # Needed, there is a delay on the removing of a port, if you add them to quickly, it will fail.
#---------------------------------------------------------------------------------------------------------#

Write-debug "Adding printerport..."
Add-PrinterPort -Name "$portname" -PrinterHostAddress "$input" -ComputerName ($env:COMPUTERNAME) -ErrorAction SilentlyContinue
sleep 2
#---------------------------------------------------------------------------------------------------------#

Write-debug "Installing Canon Generic PCL6 Driver printdriver..."
pnputil.exe /a  .\GenericDriver\x64\Driver\CNP60MA64.INF /i | out-null

# Calls the driver by its driver name (The name can be found in the .INF file) (needs to be installed or present on PC.)
Add-PrinterDriver -Name "Canon Generic PCL6 Driver"
sleep 2
#---------------------------------------------------------------------------------------------------------#

Write-debug "Installing new loketprinter..."

$perms = Get-Content "$PSScriptRoot\acl.txt" ##(Get-Printer 'Loketprinter' -Full).PermissionSDDL | Out-File 'C:\temp\acl.txt'
Add-Printer -Name "Loketprinter" -DriverName "Canon Generic PCL6 Driver" -PortName "$input" -PermissionSDDL $perms 
sleep 2
#---------------------------------------------------------------------------------------------------------#

Write-debug "Configuring printer preferences..."
# Configure LowerTray -  following code used to create file
#$GPC = get-printconfiguration  -PrinterName "Loketprinter LowerTray" -ComputerName pc1
#$GPC.PrintTicketXML | out-file C:\Temp\LowerTray.xml

$XMLA = Get-Content "$PSScriptRoot\PrintPreferences\LowerTray.xml" | Out-String  
Set-PrintConfiguration -PrinterName "Loketprinter LowerTray" -PrintTicketXml $XMLA
sleep 2
#---------------------------------------------------------------------------------------------------------#

Write-debug "Setting up the default printer..."
(Get-WmiObject -Class Win32_Printer -Filter "Name='Loketprinter'").SetDefaultPrinter() | Out-Null
Write-debug "Installation completed."
<#
# Secundary method for exporting and importing printer preferences.
#rundll32 printui.dll,PrintUIEntry /Ss /n "Loketprinter LowerTray" /a "c:\temp\file.dat" 
#rundll32 printui.dll,PrintUIEntry /Sr /n "Loketprinter LowerTray" /a "c:\temp\file.dat"
#>
pause
