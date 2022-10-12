param ($ComputerName, $UserAccountName, $SqlServiceAccountName, $SqlServiceAccountPassword)

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

# Modified from https://morgantechspace.com/2017/10/check-if-user-is-member-of-local-group-powershell.html
function IsUserInGroup($user, $group) {
    $groupObj =[ADSI]"WinNT://./$group,group" 
    $membersObj = @($groupObj.psbase.Invoke("Members")) 

    $members = ($membersObj | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)})

    If ($members -contains $user) {
        return $true
    } Else {
        return $false
    }
}

#region - These routines writes the output string to the console and also to the log file.
# Taken directly from teh AzureMigrateInstaller script
function Log-Info([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor White
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

function Log-InfoHighLight([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Cyan
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

function Log-Input([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor White -BackgroundColor DarkGray -NoNewline
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
    Write-Host " " -NoNewline
}

function Log-Success([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Green
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}

function Log-Warning([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Yellow
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII"  }
}

function Log-Error([string] $OutputText)
{
    Write-Host $OutputText -ForegroundColor Red
    $OutputText = [string][DateTime]::Now + " " + $OutputText
    $OutputText | %{ Out-File -filepath $InstallerLog -inputobject $_ -append -encoding "ASCII" }
}
#endregion

$sqlInstalls = @(
    @{
        isoUrl="https://sqlmigrationtraining.blob.core.windows.net/iso/en_sql_server_2019_developer_x64_dvd.iso",
        extractPath="C:\SQL2019Install\",
        downloadPath="C:\ISOs\en_sql_server_2019_developer_x64_dvd.iso",
        instanceName="SQL2019",
        backupUrl="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak",
        backupPath="C:\Backups\AdventureWorks2019.bak",
        databaseName="AdventureWorks2019",
        registryKey="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQL2019",
        sqlVersion="2019"
    }
    @{
        isoUrl="https://sqlmigrationtraining.blob.core.windows.net/iso/en_sql_server_2012_developer_edition_with_service_pack_4_x64_dvd.iso",
        extractPath="C:\SQL2012Install\",
        downloadPath="C:\ISOs\en_sql_server_2012_developer_edition_with_service_pack_4_x64_dvd.iso",
        instanceName="SQL2012",
        backupUrl="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2012.bak",
        backupPath="C:\Backups\AdventureWorks2012.bak",
        databaseName="AdventureWorks2012",
        registryKey="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.SQL2012",
        sqlVersion="2012 SP4"
    }
    @{
        isoUrl="https://sqlmigrationtraining.blob.core.windows.net/iso/enu_sql_server_2016_developer_edition_with_service_pack_3_x64_dvd.iso",
        extractPath="C:\SQL2016Install\",
        downloadPath="C:\ISOs\enu_sql_server_2016_developer_edition_with_service_pack_3_x64_dvd.iso",
        instanceName="SQL2016",
        backupUrl="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2016.bak",
        backupPath="C:\Backups\AdventureWorks2016.bak",
        databaseName="AdventureWorks2016",
        registryKey="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.SQL2016",
        sqlVersion="2016 SP3"
    }
)

$scriptPath = $MyInvocation.MyCommand.Path

$action=New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Unrestricted -File `"$scriptPath`" -ComputerName `"$ComputerName`" -UserAccountName `"$UserAccountName`" -SqlServiceAccountName `"$SqlServiceAccountName`" -SqlServiceAccountPassword `"$SqlServiceAccountPassword`""
$trigger=New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "ReRunSQLInstallProcess" -Description "Re-Run the SQL Installation custom script to handle reboots and errors"

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
        Start-Process -FilePath $ssmsLocalPath -ArgumentList "/install /passive /norestart"
        Log-Success("SSMS and Azure Data Studio successfully installed!")
    } else {
        Log-Info("SSMS Is already installed, continuing script")
    }
} catch {
    Log-Error("SSMS installation has encountered an error.")
    Log-Error($_)
    Log-Error("Terminating Script!")
    Exit
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
        Exit
    }
}
else {
    Log-Info("Local SQL Server Service account $SqlServiceAccountName already exists.")
}

try {
    Log-Info("Step 2.3: Checking if the account $SqlServiceAccountName is part of the Administrators local group")
    if(IsUserInGroup($SqlServiceAccountName, "Administrators")) {
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
    Exit
}

Log-Success("Local SQL Service account $SqlServiceAccountName exists and has valid permissions.")

$stepCounter = 3

foreach($sql in $sqlInstalls){
    $subStepCounter = 1
    Log-InfoHighLight("Step $stepCounter: Beginning creation of SQL Instance $($sql.instanceName) running SQL Version $($sql.sqlVersion).")
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
        Exit
    }

    try {
        Log-InfoHighlight("Step $stepCounter.$subStepCounter: Mounting the iso image $($sql.downloadPath) and extracting the data to $($sql.extractPath)")
        $subStepCounter++
        Log-Info("Mounting the iso image $($sql.downloadPath)")
        $isoMount = Mount-DiskImage $sql.downloadPath
        $isoDriveLetter = $(Get-Volume -DiskImage $isoMount).DriveLetter

        Log-Info("Moving the installer bits to $($sql.extractPath)")
        MakeDirectoryIfNotExists($sql.extractPath)
        Copy-Item -Path "$isoDriveLetter:\" -Destination $sql.extractPath -Recurse -Force

        Log-Info("Dismounting the iso image $($sql.downloadPath)")
        DisMount-DiskImage $sql.downloadPath
        Log-Success("Installer bits successfully extracted to $($sql.extractPath)")
    }
    catch {
        Log-Error("Mounting or extracting the ISO disk image $($sql.downloadPath) has failed.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit
    }

    try {
        Log-InfoHighLight("Step $stepCounter.$subStepCounter: Beginning SQL install of $($sql.sqlVersion)")
        # Path we copied the setup bits to for SQL
        $SetupPath = $sql.extractPath + "setup.exe"
        # Silent install options, Set instance name, use created sql service account, add templated user to Sys Admin, use network service for SQL Agent, 
        # Use instant file initialization, turn on SQL Auth with the service account password, accept the license
        $ArgumentList = "/qs /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=$($sql.instanceName) /SQLSVCACCOUNT=`"$ComputerName\$SqlServiceAccountName`" /SQLSVCPASSWORD=`"$SqlServiceAccountPassword`" /SQLSYSADMINACCOUNTS=`"$ComputerName\$UserAccountName`" /AGTSVCACCOUNT=`"NT AUTHORITY\Network Service`" /SQLSVCINSTANTFILEINIT=`"True`" /SECURITYMODE=SQL /SAPWD=`"$SqlServiceAccountPassword`" /IACCEPTSQLSERVERLICENSETERMS"
        if(-not(Test-Path $sql.registryKey)) {
            Log-Info("Starting SQL Installation with arguments $ArgumentList")
            Start-Process -FilePath $SetupPath -ArgumentList $ArgumentList
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
        Exit
    }
    
    # We install 2019 first to allow make sure we have SQLCMD in an expected folder
    # Check if the database exists, if it does, do nothing, otherwise restore the backup
    try {
        Log-InfoHighLight("Step $stepCounter.$subStepCounter: Starting Database restoration of $($sql.databaseName) into SQL Instance $($sql.instanceName)")
        $subStepCounter++
        # Query to check if the database exists on the SQL Instance per example:
        # https://stackoverflow.com/a/25054312 
        Log-Info("Checking if database $($sql.databaseName) exists on instance")
        $SqlQuery = "SELECT count(*) FROM sys.databases WHERE name = '$($sql.databaseName)'"
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection 
        $SqlConnection.ConnectionString = "Server = .\$($sql.instanceName); Database = master;Integrated Security=False;User Id=sa;Password=$SqlServiceAccountPassword;"
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand $SqlCmd.CommandText = $SqlQuery $SqlCmd.Connection = $SqlConnection
        $SqlConnection.Open() 
        $Rows= [Int32]$SqlCmd.ExecuteScalar()
        $SqlConnection.Close()

        if($Rows -eq 0) {
            Log-Info("Starting restoration of $($sql.databaseName) on instance.")
            $SqlCmdArguments = "-S $ComputerName\$($sql.instanceName) -U sa -P $SqlServiceAccountPassword -Q `"RESTORE DATABASE [$($sql.databaseName)] FROM DISK='$($sql.backupPath)'`""
            Start-Process -FilePath "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE" -ArgumentList $SqlCmdArguments
            Log-Success("Database $($sql.databaseName) successfully restored on instance.")
        } else {
            Log-Info("Database $($sql.databaseName) already exists on instance.")
        }
    }
    catch {
        Log-Error("SQL Database $($sql.databaseName) restoration has encountered an error.")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit
    }

    try {
        Log-InfoHighLight("Step $stepCounter.$subStepCounter: Enabling TCP/IP Protocol for SQL Instance $($sql.instanceName)")
        $subStepCounter++
        # Enabling TCP/IP protocol for the SQL Server as per https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/enable-or-disable-a-server-network-protocol?view=sql-server-2017#to-enable-a-server-network-protocol-using-powershell
        Log-Info("Importing sqlps module to interact with WMI")
        Import-Module "sqlps"
        $smo = 'Microsoft.SqlServer.Management.Smo.'  
        $wmi = new-object ($smo + 'Wmi.ManagedComputer')

        # Enable the TCP protocol on the default instance.
        Log-Info("Querying WMI to determine if TCP/IP protocol is enabled")
        $uri = "ManagedComputer[@Name='$ComputerName']/ ServerInstance[@Name='$($sql.instanceName)']/ServerProtocol[@Name='Tcp']"  
        $Tcp = $wmi.GetSmoObject($uri)
        if($Tcp.IsEnabled) {
            Log-Info("TCP/IP is already enabled for SQL Instance $($sql.instanceName)")
        } else {
            $Tcp.IsEnabled = $true  
            $Tcp.Alter()
        }  
    }
    catch {
        Log-Error("Could not enable TCP/IP protocol for the instance $($sql.instanceName)")
        Log-Error($_)
        Log-Error("Terminating Script!")
        Exit
    }
}

Unregister-ScheduledTask -TaskName "ReRunSQLInstallProcess" -Confirm:$false
