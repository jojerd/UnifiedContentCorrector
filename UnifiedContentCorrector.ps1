<#
.NOTES
	Name: UnifiedContentCorrector.ps1
    Author: Josh Jerdon
    Email: jojerd@microsoft.com
	Requires: Administrative Priveleges
	Version History:
	1.0 - 12/16/2019 - Initial Release

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
.SYNOPSIS
    Corrects the Unified Content folder path so that the cleanup probe can check the directory for 
    files that need to be cleaned up and removed. This only needs to be run on Exchange 2013,2016, and 2019 servers
    if both conditions are met.
    1.) Exchange 2013, 2016, 2019 installed outside of the default installation path (example C:\Program Files\Microsoft\Exchange Server\v15\)
    2.) You are actively utilizing the built in Antimalware agent. If you are not, then this behavior is a non-issue.

#>
param(
    [switch]$AllExchangeServers
)

function UpdateAllExchangeServers {
    # Check if script has been executed as an Administrator
    $Admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    if ($Admin -eq 'True') {
        Write-Host "Script was executed with elevated permissions, continuing..." -ForegroundColor Green
        Start-Sleep -Seconds 3
        Clear-Host
    }
    # If script is not executed as an Administrator, stop the script.
    else {
        Write-Error 'This Script needs to be executed under Powershell with Administrative Privileges...' -ErrorAction Stop
    }
    #Check for Exchange Management Shell, if found continue, if not add it.
    $CheckSnapin = (Get-PSSession | Where-Object { $_.Name -eq "Microsoft.Exchange.Management.Powershell.E2010" } | Select-Object Name)
    if ($CheckSnapin -like "*Exchange.Management.Powershell*") {
        Write-Host "Exchange Snap-In already loaded, continuing...." -ForegroundColor Green
    }
    else {
        Write-Host "Loading Exchange Snap-in, Please wait..."
        Add-PSSnapin Microsoft.Exchange.Management.Powershell.E2010 -ErrorAction SilentlyContinue
    }
    $ADSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name
    $ExchangeServers = Get-ExchangeServer | Where-Object { $_.IsHubTransportServer -eq $true -and $_.AdminDisplayVersion -match "^Version 15" -and ($_.Site -match "$ADSite") }
    $Report = @()
    if ($ExchangeServers.count -gt 0) {
        foreach ($Server in $ExchangeServers) {
            $EXServer = $Server.Name
            Write-Host "Checking $EXServer..."
            $InstallPath = $null

            try {
                $InstallPath = Invoke-Command -ComputerName $EXServer -ScriptBlock { $env:Exchangeinstallpath } -ErrorAction Stop
            }
            catch {
                Write-Warning $_.Exception.Message
                $InstallPath = "Unable to connect to server"
            }
            else {
                Write-Error "Unable to locate any Exchange servers..." -ErrorAction Stop
            }
        }
    }
}

if ($AllExchangeServers) { UpdateAllExchangeServers; exit; }

# Check if script has been executed as an Administrator
$Admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if ($Admin -eq 'True') {
    Write-Host "Script was executed with elevated permissions, continuing..." -ForegroundColor Green
    Start-Sleep -Seconds 3
    Clear-Host
}
# If script is not executed as an Administrator, stop the script.
else {
    Write-Error 'This Script needs to be executed under Powershell with Administrative Privileges...' -ErrorAction Stop
}
# Get Exchange installation path, set pathing variables, load file to be modified into memory.
$ExchangePath = $env:Exchangeinstallpath
$UnifiedContentPath = $ExchangePath + "TransportRoles\data\Temp\UnifiedContent"
$AntimalwareFile = $ExchangePath + "Bin\Monitoring\Config\Antimalware.xml"
$AntimalwareFilePath = $ExchangePath + "Bin\Monitoring\Config"
if ([System.IO.File]::Exists($AntimalwareFile) -eq 'True') {
    Clear-Host
    Write-Host "Located Antimalware.xml file to modify, loading file into memory..." -ForegroundColor Green
    Start-Sleep -Seconds 3
    [xml]$LoadFile = Get-Content $AntimalwareFile
    Clear-Host
}
# If script is not able to verify the UnifiedContent folder path, end script execution.
else {
    Write-Error 'Unable to locate file to modify' -ErrorAction Stop
}
# Test UnifiedContent file Path to confirm it exists before file modification.
$TestUnifiedPath = Test-Path -Path $UnifiedContentPath -IsValid
# If test path is successful, change working location.
if ($TestUnifiedPath -eq 'True') {
    Write-Host "UnifiedContent Folder path is correct, creating a backup of the original file before proceeding..." -ForegroundColor Green
    Start-Sleep -Seconds 3
    Clear-Host
    Set-Location $AntimalwareFilePath
}
# If test path fails, halt script.
else {
    Write-Error 'Unified Content Folder Path is not valid no changes will be made' -ErrorAction Stop
}
# Verify if backup directory exists, if so copy Antimalware.xml file.
$xmlbackuppath = $AntimalwareFilePath + "\xmlbackup"
if ([System.IO.Directory]::Exists($xmlbackuppath) -eq 'True') {
    Write-Host "Creating file backup..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    Clear-Host 
    Copy-Item Antimalware.xml .\xmlbackup -Force
}
else {
    # If directory does not exist, create it and copy Antimalware.xml file.
    New-Item -Name xmlbackup -ItemType Directory
    Copy-Item Antimalware.xml .\xmlbackup -Force
}   
# Confirm backup is successfully saved, if so make xml file changes.
$BackupFile = $AntimalwareFilePath + "\xmlbackup\Antimalware.xml"
[string]$NewPath = "D:\ExchangeTemp\TransportCts\UnifiedContent;C:\Windows\Temp\UnifiedContent;C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\data\Temp\UnifiedContent", "D:\ExchangeTemp\TransportCts\UnifiedContent;C:\Windows\Temp\UnifiedContent;$UnifiedContentPath"
if ([System.IO.File]::Exists($BackupFile) -eq 'True') {
    Clear-Host
    Write-Host "Previous Antimalware file was backed up successfully, making required changes" -ForegroundColor Green
    Start-Sleep -Seconds 3
    $LoadFile.Definition.MaintenanceDefinition.ExtensionAttributes.CleanupFolderResponderFolderPaths = $NewPath
    $LoadFile.Save((Resolve-Path "Antimalware.xml")) 
}
else {
    # If not able to locate the backup file, stop script no changes will be made.
    Write-Error "Unable to confirm file backup, script will not continue..." -ErrorAction Stop
}
# Confirm that the Antimalware.xml file has been updated with the correct file path.
Clear-Host
Write-Host 'Checking to confirm file was updated as expected...'
Start-Sleep -Seconds 3

[xml]$LoadModifiedFile = Get-Content .\Antimalware.xml
if ($LoadModifiedFile.Definition.MaintenanceDefinition.ExtensionAttributes.CleanupFolderResponderFolderPaths -match $NewPath ) {
    Write-Host 'Antimalware file has been modified to reflect the accurate UnifiedContent folder location' -ForegroundColor Green
    Write-Host 'Please reboot the server for the changes to take affect...' -ForegroundColor Green
    Write-Host " "
    Read-Host  'Press Enter key to exit.'
    Exit
}
else {
    Write-Error "File has not been modifed."
    Read-Host 'Press Enter key to exit.'
    Exit
}


