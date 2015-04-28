configuration JoinDomain 
{ 
   param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xComputerManagement

    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
   
    Node localhost
    {
        WindowsFeature ADPowershell
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        } 

        xWaitForADDomain WaitForDomain 
        { 
            DomainName = $DomainName 
            DomainUserCredential= $Admincreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[WindowsFeature]ADPowershell" 
        }

        xComputer JoinDomain
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
            DependsOn = "[xWaitForADDomain]WaitForDomain" 
        }
   }
}

configuration Gateway 
{ 
 
    Node localhost
    {
        WindowsFeature RDSGateway
        {
            Ensure = "Present"
            Name = "RDS-Gateway"
        }

        WindowsFeature RDSGatewayTools
        {
            Ensure = "Present"
            Name = "RSAT-RDS-Gateway"
        }

   }
}

Configuration RemoteDesktopSessionCollection
{
    param
    (
        # Connection Broker Node Name
        [String]$connectionBroker,

        # Web Access Node Name
        [String]$webAccessServer,
        
        # RDSH Name
        [String]$sessionHost,
        
        # Collection Name
        [String]$collectionName,

        # Connection Description
        [String]$collectionDescription
    )

    Import-DscResource -Module xRemoteDesktopSessionHost

    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

    if (-not $collectionName) {$collectionName = "Tenant Jump Box"}
    if (-not $collectionDescription) {$collectionDescription = "Remote Desktop instance for accessing an isolated network environment."}


    if (-not $connectionBroker)          {$connectionBroker = $localhost}
    if (-not $connectionWebAccessServer) {$webAccessServer = $localhost}

    Node "localhost"
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        if ($localhost -eq $sessionHost) {
            WindowsFeature RDS-RD-Server
            {
                Ensure = "Present"
                Name = "RDS-RD-Server"
            }
        }

        if ($localhost -eq $sessionHost) {
            WindowsFeature Desktop-Experience
            {
                Ensure = "Present"
                Name = "Desktop-Experience"
            }
        }

        WindowsFeature RSAT-RDS-Tools
        {
            Ensure = "Present"
            Name = "RSAT-RDS-Tools"
            IncludeAllSubFeature = $true
        }

        if ($localhost -eq $connectionBroker) {
            WindowsFeature RDS-Connection-Broker
            {
                Ensure = "Present"
                Name = "RDS-Connection-Broker"
            }
        }

        if ($localhost -eq $webAccessServer) {
            WindowsFeature RDS-Web-Access
            {
                Ensure = "Present"
                Name = "RDS-Web-Access"
            }
        }

        WindowsFeature RDS-Licensing
        {
            Ensure = "Present"
            Name = "RDS-Licensing"
        }

        xRDSessionDeployment Deployment
        {
            SessionHost = $sessionHost
            ConnectionBroker = if ($ConnectionBroker) {$ConnectionBroker} else {$localhost}
            WebAccessServer = if ($WebAccessServer) {$WebAccessServer} else {$localhost}
            DependsOn = "[WindowsFeature]Remote-Desktop-Services", "[WindowsFeature]RDS-RD-Server"
        }

        xRDSessionCollection Collection
        {
            CollectionName = $collectionName
            CollectionDescription = $collectionDescription
            SessionHost = $localhost
            ConnectionBroker = if ($ConnectionBroker) {$ConnectionBroker} else {$localhost}
            DependsOn = "[xRDSessionDeployment]Deployment"
        }

        xRDSessionCollectionConfiguration CollectionConfiguration
        {
            CollectionName = $collectionName
            CollectionDescription = $collectionDescription

            ConnectionBroker = if ($ConnectionBroker) {$ConnectionBroker} else {$localhost}        
            
            TemporaryFoldersDeletedOnExit = $false
            SecurityLayer = "SSL"
            DependsOn = "[xRDSessionCollection]Collection"
        }
    }
}
