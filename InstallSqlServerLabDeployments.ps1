param ($ComputerName, $UserAccountName, $SqlServiceAccountName, $SqlServiceAccountPassword)

$InstallerLog = ".\InstallLog.txt"

function MakeDirectoryIfNotExists($DirectoryPath) {
    if (Test-Path $DirectoryPath) {
   
        Write-Host "Folder $DirectoryPath Already Exists"
    }
    else
    {
        New-Item $DirectoryPath -ItemType Directory
        Write-Host "Folder $DirectoryPath Created successfully"
    }
}

# IE ESC Disable script from https://serverspace.io/support/help/disable-enhanced-security-windows-server/
function Disable-IEESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 
}

#region - These routines writes the output string to the console and also to the log file.
# Originally taken from AzureMigration.ps1, now heavily modified due to Nick's need to complain
# about the code being formatted a specific way instead of looking at the functionality of the 
# important items that are running. But as you see now we have a very in depth case statement 
# across three concepts of info, infohighlight, and error. 
# Just to make it a bit more frustrating though I am going to have one log function, that these three
# functions call with a different parameter each.
# 
# I need to add to the story of how difficult this was and the fact that I burned 2 hours of my day
# converting this to a new method. Would you believe that in PowerShell if you try to use Enums
# the most basic of types might I add, you have to call functions without parentheses? 
#
# See below to see how ridiculous it is, now though, we have one, absolutely, obviously, fantastically
# managable function and an enum with loglevel types. We no longer have my sanity, dignity, or 
# general ability to think straight. But at least we have a nice contained function.

Enum LogLevel {
    info
    infohighlight
    success
    error
}

function Log {
    param (
        [Parameter(Mandatory=$true)]
        [LogLevel]
        $level,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputText
    )
    $TextColor = "White"
    switch($level) {
        [LogLevel]::info {$TextColor = "White"}
        [LogLevel]::infohighlight {$TextColor = "Cyan"}
        [LogLevel]::error {$TextColor = "Red"}
        [LogLevel]::success {$TextColor = "Green"}
    }
    Write-Host $OutputText -ForegroundColor $TextColor
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

function Log-Info([string] $OutputText)
{
    Log ([LogLevel]::info) $OutputText
}

function Log-InfoHighLight([string] $OutputText)
{
    Log ([LogLevel]::infohighlight) $OutputText
}

function Log-Success([string] $OutputText)
{
    Log ([LogLevel]::success) $OutputText
}

function Log-Error([string] $OutputText)
{
    Log ([LogLevel]::error) $OutputText
}
#endregion

# Full information needed for the installations, make sure to not have a trailing slash on extractPath
$sqlInstalls = @(
    @{
        isoUrl="https://sqlmigrationtraining.blob.core.windows.net/iso/en_sql_server_2019_developer_x64_dvd.iso";
        extractPath="C:\SQL2019Install";
        downloadPath="C:\ISOs\en_sql_server_2019_developer_x64_dvd.iso";
        instanceName="SQL2019";
        backupUrl="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak";
        backupPath="C:\Backups\AdventureWorks2019.bak";
        databaseName="AdventureWorks2019";
        registryKey="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQL2019";
        sqlVersion="2019";
        sqlRestoreArguments="-S $ComputerName\SQL2019 -U sa -P $SqlServiceAccountPassword -Q `"RESTORE DATABASE [AdventureWorks2019] FROM DISK='C:\Backups\AdventureWorks2019.bak' WITH FILE = 1, MOVE N'AdventureWorks2017' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks2019.mdf', MOVE N'AdventureWorks2017_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\AdventureWorks2019_log.ldf',  NOUNLOAD,  STATS = 5`"";
        argumentList = "/q /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=SQL2019 /SQLSVCACCOUNT=`"$ComputerName\$SqlServiceAccountName`" /SQLSVCPASSWORD=`"$SqlServiceAccountPassword`" /SQLSYSADMINACCOUNTS=`"$ComputerName\$UserAccountName`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /SQLSVCINSTANTFILEINIT=`"True`" /SECURITYMODE=SQL /SAPWD=`"$SqlServiceAccountPassword`" /IACCEPTSQLSERVERLICENSETERMS";
    }
    @{
        isoUrl="https://sqlmigrationtraining.blob.core.windows.net/iso/en_sql_server_2012_developer_edition_with_service_pack_4_x64_dvd.iso";
        extractPath="C:\SQL2012Install";
        downloadPath="C:\ISOs\en_sql_server_2012_developer_edition_with_service_pack_4_x64_dvd.iso";
        instanceName="SQL2012";
        backupUrl="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak";
        backupPath="C:\Backups\AdventureWorks2012.bak";
        databaseName="AdventureWorks2012";
        registryKey="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.SQL2012";
        sqlVersion="2012 SP4";
        sqlRestoreArguments="-S $ComputerName\SQL2012 -U sa -P $SqlServiceAccountPassword -Q `"RESTORE DATABASE [AdventureWorks2012] FROM DISK='C:\Backups\AdventureWorks2012.bak' WITH FILE = 1, MOVE N'AdventureWorks2012' TO N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQL2012\MSSQL\DATA\AdventureWorks2012.mdf', MOVE N'AdventureWorks2012_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQL2012\MSSQL\DATA\AdventureWorks2012_log.ldf',  NOUNLOAD,  STATS = 5`"";
        argumentList = "/q /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=SQL2012 /SQLSVCACCOUNT=`"$ComputerName\$SqlServiceAccountName`" /SQLSVCPASSWORD=`"$SqlServiceAccountPassword`" /SQLSYSADMINACCOUNTS=`"$ComputerName\$UserAccountName`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /SECURITYMODE=SQL /SAPWD=`"$SqlServiceAccountPassword`" /IACCEPTSQLSERVERLICENSETERMS";
    }
    @{
        isoUrl="https://sqlmigrationtraining.blob.core.windows.net/iso/enu_sql_server_2016_developer_edition_with_service_pack_3_x64_dvd.iso";
        extractPath="C:\SQL2016Install";
        downloadPath="C:\ISOs\enu_sql_server_2016_developer_edition_with_service_pack_3_x64_dvd.iso";
        instanceName="SQL2016";
        backupUrl="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2016.bak";
        backupPath="C:\Backups\AdventureWorks2016.bak";
        databaseName="AdventureWorks2016";
        registryKey="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.SQL2016";
        sqlVersion="2016 SP3";
        sqlRestoreArguments="-S $ComputerName\SQL2016 -U sa -P $SqlServiceAccountPassword -Q `"RESTORE DATABASE [AdventureWorks2016] FROM DISK='C:\Backups\AdventureWorks2016.bak' WITH FILE = 1, MOVE N'AdventureWorks2016_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA\AdventureWorks2016_Data.mdf', MOVE N'AdventureWorks2016_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA\AdventureWorks2016_log.ldf',  NOUNLOAD,  STATS = 5`"";
        argumentList = "/q /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=SQL2016 /SQLSVCACCOUNT=`"$ComputerName\$SqlServiceAccountName`" /SQLSVCPASSWORD=`"$SqlServiceAccountPassword`" /SQLSYSADMINACCOUNTS=`"$ComputerName\$UserAccountName`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /SQLSVCINSTANTFILEINIT=`"True`" /SECURITYMODE=SQL /SAPWD=`"$SqlServiceAccountPassword`" /IACCEPTSQLSERVERLICENSETERMS";
    }
)

$scriptPath = $MyInvocation.MyCommand.Path

$action=New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Unrestricted -File `"$scriptPath`" -ComputerName `"$ComputerName`" -UserAccountName `"$UserAccountName`" -SqlServiceAccountName `"$SqlServiceAccountName`" -SqlServiceAccountPassword `"$SqlServiceAccountPassword`""
$trigger=New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "ReRunSQLInstallProcess" -Description "Re-Run the SQL Installation custom script to handle reboots and errors" -User "NT AUTHORITY\LOCALSERVICE"

# Adding this line prevents the progress rendering and MASSIVELY improves download times
# Directly referenced from stackoverflow: https://superuser.com/a/693179
$ProgressPreference = "silentlyContinue"

# Create all download directories if they do not exist
Log-Info("Creating download directories, C:\SSMSSetup, C:\ISOs, C:\Backups")
MakeDirectoryIfNotExists("C:\SSMSSetup")
MakeDirectoryIfNotExists("C:\ISOs")
MakeDirectoryIfNotExists("C:\Backups")

# Install SSMS/Data Studio
try {
    Log-InfoHighLight("Step 1: Installing SSMS")
    # Verify SSMS is not installed via Reg Key
    $ssmsDownloadUrl = "https://aka.ms/ssmsfullsetup"
    $ssmsLocalPath = "C:\SSMSSetup\ssmssetup.exe"
    if(-not(Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server Management Studio\18")) {
        # Make Sure we haven't downloaded SSMS already
        if(-not(Test-Path  $ssmsLocalPath)) {
            Log-Info("Downloading SSMS Install bits from $ssmsDownloadUrl to $ssmsLocalPath")
            Invoke-WebRequest -UseBasicParsing -Uri $ssmsDownloadUrl -OutFile  $ssmsLocalPath
        } else {
            Log-Info("$ssmsLocalPath already exists, assuming we have already downloaded the installer, skipping to install.")
        }

        Log-Info("Running SSMS installer to add SSMS and Azure Data Studio")
        Start-Process -FilePath $ssmsLocalPath -ArgumentList "/install /passive /norestart" -Wait
        Log-Success("SSMS and Azure Data Studio successfully installed!")
    } else {
        Log-Info("SSMS Is already installed, continuing script")
    }
} catch {
    Log-Error("SSMS installation has encountered an error.")
    Log-Error($_)
    Log-Error("Terminating Script!")
    Exit 1
}

#Check if the local user doesn't exist as per https://www.reddit.com/r/PowerShell/comments/fligk9/comment/fkytdup/?utm_source=share&utm_medium=web2x&context=3
# This is where we create the SQL Service account (local account with admin access, not best practice, but good for labs)
Log-InfoHighLight("Step 2: Creating local SQL Service account named $SqlServiceAccountName.")
Log-Info("Step 2.1: Checking if local SQL Service account $SqlServiceAccountName exists")
if((Get-LocalUser $SqlServiceAccountName -ErrorAction SilentlyContinue) -eq $null) {
    try {
        Log-Info("Step 2.2: Creating local SQL Service account")
        $password = ConvertTo-SecureString $SqlServiceAccountPassword -AsPlainText -Force
        New-LocalUser -Name "$SqlServiceAccountName" -Password $password -FullName "$SqlServiceAccountName"
    }
    catch {
        Log-Error("Could not create the SQL Service account user.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit 1
    }
}
else {
    Log-Info("Local SQL Server Service account $SqlServiceAccountName already exists.")
}

try {
    Log-Info("Step 2.3: Checking if the account $SqlServiceAccountName is part of the Administrators local group")
    $members = Get-LocalGroupMember -Group "Administrators"
    ($adusers_list | Select -Expand samaccountname) -contains $target_aduser.samaccountname
    if(($members| Select -Expand Name) -contains "$ComputerName\$SqlServiceAccountName") {
        Log-Info("Local SQL Server Service account $SqlServiceAccountName is already part of the Administrators group.")
    } else {
        Log-Info("Step 2.4: Adding account $SqlServiceAccountName to the Administrators local group")
        Add-LocalGroupMember -Group "Administrators" -Member $SqlServiceAccountName
    }   
}
catch {
    Log-Error("Could not add the SQL Service account user to the Administrators group.")
    Log-Error($_)
    Log-Error("Terminating Script!")
    Exit 1
}

Log-Success("Local SQL Service account $SqlServiceAccountName exists and has valid permissions.")

$stepCounter = 3

foreach($sql in $sqlInstalls){
    $subStepCounter = 1
    Log-InfoHighLight("Step ${stepCounter}: Beginning creation of SQL Instance $($sql.instanceName) running SQL Version $($sql.sqlVersion).")
    $subStepCounter++
    try {
        if(-not(Test-Path $sql.downloadPath -PathType Leaf)) {
            Log-Info("Downloading $($sql.sqlVersion) installer iso from $($sql.isoUrl) to $($sql.downloadPath)")
            Invoke-WebRequest -UseBasicParsing -Uri $sql.isoUrl -OutFile $sql.downloadPath
            Log-Success("Successfully downloaded $($sql.isoUrl)")
        } else {
            Log-Info("$($sql.downloadPath) already exists, assuming we have already downloaded the iso, skipping to install.")
        }

        if(-not(Test-Path $sql.backupPath -PathType Leaf)) {
            Log-Info("Downloading $($sql.databaseName) backup from $($sql.backupUrl) to $($sql.backupPath)")
            Invoke-WebRequest -UseBasicParsing -Uri $sql.backupUrl -OutFile $sql.backupPath
            Log-Success("Successfully downloaded $($sql.backupUrl)")
        } else {
            Log-Info("$($sql.backupPath) already exists, assuming we have already downloaded the backup, skipping to install.")
        }
    }
    catch {
        Log-Error("ISO or Backup downloads have failed.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit 1
    }

    try {
        Log-InfoHighlight("Step $stepCounter.${subStepCounter}: Mounting the iso image $($sql.downloadPath) and extracting the data to $($sql.extractPath)")
        $subStepCounter++
        if(-not(Test-Path $($sql.extractPath + "\setup.exe") -PathType Leaf)) {
            Log-Info("Mounting the iso image $($sql.downloadPath)")
            $isoMount = Mount-DiskImage $sql.downloadPath
            $isoDriveLetter = $(Get-Volume -DiskImage $isoMount).DriveLetter

            Log-Info("Moving the installer bits to $($sql.extractPath)")
            Copy-Item -Path "${isoDriveLetter}:\" -Destination $sql.extractPath -Recurse -Force

            Log-Info("Dismounting the iso image $($sql.downloadPath)")
            DisMount-DiskImage $sql.downloadPath
            Log-Success("Installer bits successfully extracted to $($sql.extractPath)")
        } else {
            Log-Info("setup.exe already exists at $($sql.extractPath), assuming we've already extracted the ISO")
        }
    }
    catch {
        DisMount-DiskImage $sql.downloadPath -ErrorAction SilentlyContinue
        Log-Error("Mounting or extracting the ISO disk image $($sql.downloadPath) has failed.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit 1
    }

    try {
        Log-InfoHighLight("Step $stepCounter.${subStepCounter}: Beginning SQL install of $($sql.sqlVersion)")
        # Path we copied the setup bits to for SQL
        $SetupPath = $sql.extractPath + "\setup.exe"
        # Silent install options, Set instance name, use created sql service account, add templated user to Sys Admin, use network service for SQL Agent, 
        # Use instant file initialization, turn on SQL Auth with the service account password, accept the license

        # Now moved to individual properties as instant files aren't supported in 2012
        if(-not(Test-Path $sql.registryKey)) {
            Log-Info("Starting SQL Installation with arguments $($sql.argumentList)")
            Start-Process -FilePath $SetupPath -ArgumentList $sql.argumentList -Wait
            Log-Success("SQL Instance $($sql.instanceName) successfully installed")
        } else {
            Log-Info("SQL $($sql.sqlVersion) already installed at instance $($sql.instanceName)")
        }
        $subStepCounter++
    }
    catch {
        Log-Error("SQL Server Installation for instance $($sql.instanceName) has failed.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit 1
    }
    
    # We install 2019 first to allow make sure we have SQLCMD in an expected folder
    # Check if the database exists, if it does, do nothing, otherwise restore the backup
    try {
        Log-InfoHighLight("Step $stepCounter.${subStepCounter}: Starting Database restoration of $($sql.databaseName) into SQL Instance $($sql.instanceName)")
        $subStepCounter++
        # Query to check if the database exists on the SQL Instance per example:
        # https://stackoverflow.com/a/25054312 
        Log-Info("Checking if database $($sql.databaseName) exists on instance")
        $SqlQuery = "SELECT count(*) FROM sys.databases WHERE name = '$($sql.databaseName)'"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
        $SqlConnection.ConnectionString = "Server=.\$($sql.instanceName);Database=master;Integrated Security=False;User Id=sa;Password=$SqlServiceAccountPassword;"
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand 
        $SqlCmd.CommandText = $SqlQuery 
        $SqlCmd.Connection = $SqlConnection
        $SqlConnection.Open() 
        $Rows= [Int32]$SqlCmd.ExecuteScalar()
        $SqlConnection.Close()

        if($Rows -eq 0) {
            Log-Info("Starting restoration of $($sql.databaseName) on instance.")
            Start-Process -FilePath "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE" -ArgumentList $sql.sqlRestoreArguments -Wait
            Log-Success("Database $($sql.databaseName) successfully restored on instance.")
        } else {
            Log-Info("Database $($sql.databaseName) already exists on instance.")
        }
    }
    catch {
        Log-Error("SQL Database $($sql.databaseName) restoration has encountered an error.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit 1
    }

    try {
        Log-InfoHighLight("Step $stepCounter.${subStepCounter}: Enabling TCP/IP Protocol for SQL Instance $($sql.instanceName)")
        $subStepCounter++
        # Enabling TCP/IP protocol for the SQL Server as per https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/enable-or-disable-a-server-network-protocol?view=sql-server-2017#to-enable-a-server-network-protocol-using-powershell
        Log-Info("Importing sqlps module to interact with WMI")
        import-module -name "C:\Program Files (x86)\Microsoft SQL Server\150\Tools\PowerShell\Modules\SQLPS"
        $smo = 'Microsoft.SqlServer.Management.Smo.'  
        $wmi = new-object ($smo + 'Wmi.ManagedComputer')

        # Enable the TCP protocol on the default instance.
        Log-Info("Querying WMI to determine if TCP/IP protocol is enabled")
        $uri = "ManagedComputer[@Name='$ComputerName']/ ServerInstance[@Name='$($sql.instanceName)']/ServerProtocol[@Name='Tcp']"  
        $Tcp = $wmi.GetSmoObject($uri)
        if($Tcp.IsEnabled) {
            Log-Info("TCP/IP is already enabled for SQL Instance $($sql.instanceName)")
        } else {
            Log-Info("Enabling TCP/IP for SQL Instance $($sql.instanceName)")
            $Tcp.IsEnabled = $true  
            $Tcp.Alter()
            Log-Success("TCP/IP has been enabled for SQL Instance $($sql.instanceName)")
        }  
    }
    catch {
        Log-Error("Could not enable TCP/IP protocol for the instance $($sql.instanceName)")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit 1
    }
    $stepCounter++
}

Log-InfoHighLight("Step ${stepCounter}: General Cleanup!")
Disable-IEESC
& dism /online /norestart /Remove-Capability /CapabilityName:Browser.InternetExplorer~~~~0.0.11.0

Unregister-ScheduledTask -TaskName "ReRunSQLInstallProcess" -Confirm:$false