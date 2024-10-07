<powershell>
$ipConfig = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike '*Loopback*' -and $_.PrefixOrigin -eq 'Dhcp' }
$IP = $ipConfig.IPAddress
$InterfaceIndex = $ipConfig.InterfaceIndex
Write-Host "The current IP address is: $IP"

$gatewayConfig = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object -Property RouteMetric | Select-Object -First 1
$GW = $gatewayConfig.NextHop
Write-Host "The current gateway is: $GW"

$dnsInfo = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike '*Loopback*' }
$DNS1 = $dnsInfo.ServerAddresses[0]
Write-Host "The current primary DNS server is: $DNS1"

$prefixLength = 24 # Replace with your current subnet prefix length

# Set the static IP address
Remove-NetIPAddress -IPAddress $IP -Confirm:$false
New-NetIPAddress -InterfaceIndex $interfaceIndex -IPAddress $IP -PrefixLength $prefixLength -DefaultGateway $GW

# Set the DNS server addresses
Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses ($DNS1)


#1. Install DNS Services
#====================================================
Install-WindowsFeature -Name DNS -IncludeManagementTools
#2. Install Active Directory Domain Services (AD DS)
#====================================================
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
3. Promote to Domain Controller
#====================================================
$DomainAdminUser = "Administrator"
$DomainAdminPassword = ConvertTo-SecureString "Abcd1234@!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($DomainAdminUser, $DomainAdminPassword)
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode `
            "WinThreshold" -DomainName "class.CND46"  -DomainNetbiosName "CND46" -ForestMode "WinThreshold" `
            -InstallDns:$true -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL"  -Force:$true `
            -SafeModeAdministratorPassword $DomainAdminPassword
4. Install RemoteAccess and Routing
#====================================================
Install-WindowsFeature RemoteAccess
Install-WindowsFeature Routing -IncludeManagementTools -IncludeAllSubFeature


Add computer to DNS

Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature
Add computer to DNS
Install-ADDSDomainController -Credential -DomainName "class.CND46"

$Schedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
$Schedule.ResetSchedule()
$Schedule.SetDailySchedule("Twenty","Zero","TwentyTwo","Thirty");



New-ADReplicationSite -Name "Asia" -ReplicationSchedule $schedule

New-ADOrganizationalUnit -Name "Branches" -Server "win2k22dc"
New-ADOrganizationalUnit -Name "Asia" -Path "OU=Branches,DC=class,DC=CND46"
New-ADOrganizationalUnit -Name "North America" -Path "OU=Branches,DC=class,DC=CND46"
New-ADOrganizationalUnit -Name "Europe" -Path "OU=Branches,DC=class,DC=CND46"

New-ADUser US-ADUser01 -Path "OU=North America,OU=Branches,DC=class,DC=CND46" -Surname ADUser01 -GivenName ADUser01 -DisplayName "AD User01" -EmailAddress "ADUser01@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd01" -Force)  -ChangePasswordAtLogon $true -Enabled $true
New-ADUser US-ADUser02 -Path "OU=North America,OU=Branches,DC=class,DC=CND46" -Surname ADUser02 -GivenName ADUser02 -DisplayName "AD User02" -EmailAddress "ADUser02@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd02" -Force)  -ChangePasswordAtLogon $true -Enabled $true
New-ADUser US-ADUser03 -Path "OU=North America,OU=Branches,DC=class,DC=CND46" -Surname ADUser03 -GivenName ADUser03 -DisplayName "AD User03" -EmailAddress "ADUser03@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd02" -Force)  -ChangePasswordAtLogon $true -Enabled $true

New-ADUser EU-ADUser01 -Path "OU=Europe,OU=Branches,DC=class,DC=CND46" -Surname ADUser01 -GivenName ADUser01 -DisplayName "AD User01" -EmailAddress "ADUser01@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd01" -Force)  -ChangePasswordAtLogon $true -Enabled $true
New-ADUser EU-ADUser02 -Path "OU=Europe,OU=Branches,DC=class,DC=CND46" -Surname ADUser02 -GivenName ADUser02 -DisplayName "AD User02" -EmailAddress "ADUser02@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd02" -Force)  -ChangePasswordAtLogon $true -Enabled $true
New-ADUser EU-ADUser03 -Path "OU=Europe,OU=Branches,DC=class,DC=CND46" -Surname ADUser03 -GivenName ADUser03 -DisplayName "AD User03" -EmailAddress "ADUser03@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd02" -Force)  -ChangePasswordAtLogon $true -Enabled $true

New-ADUser Asia-ADUser01 -Path "OU=Asia,OU=Branches,DC=class,DC=CND46" -Surname ADUser01 -GivenName ADUser01 -DisplayName "AD User01" -EmailAddress "ADUser01@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd01" -Force)  -ChangePasswordAtLogon $true -Enabled $true
New-ADUser Asia-ADUser02 -Path "OU=Asia,OU=Branches,DC=class,DC=CND46" -Surname ADUser02 -GivenName ADUser02 -DisplayName "AD User02" -EmailAddress "ADUser02@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd02" -Force)  -ChangePasswordAtLogon $true -Enabled $true
New-ADUser Asia-ADUser03 -Path "OU=Asia,OU=Branches,DC=class,DC=CND46" -Surname ADUser03 -GivenName ADUser03 -DisplayName "AD User03" -EmailAddress "ADUser03@srv.world" -AccountPassword (ConvertTo-SecureString -AsPlainText "P@ssw0rd02" -Force)  -ChangePasswordAtLogon $true -Enabled $true

New-ADComputer -Name "Asia-T1" -SamAccountName "Asia-T1" -Path "OU=Asia,OU=Branches,DC=class,DC=CND46"
New-ADComputer -Name "Asia-T2" -SamAccountName "Asia-T2" -Path "OU=Asia,OU=Branches,DC=class,DC=CND46"
New-ADComputer -Name "EU-T1" -SamAccountName "EU-T1" -Path "OU=Europe,OU=Branches,DC=class,DC=CND46"
New-ADComputer -Name "EU-T2" -SamAccountName "EU-T2" -Path "OU=Europe,OU=Branches,DC=class,DC=CND46"
New-ADComputer -Name "US-T1" -SamAccountName "US-T1" -Path "OU=North America,OU=Branches,DC=class,DC=CND46"
New-ADComputer -Name "US-T2" -SamAccountName "US-T2" -Path "OU=North America,OU=Branches,DC=class,DC=CND46"

New-NetFirewallRule -Name 'ICMPv4' -DisplayName 'ICMPv4' -Description 'Allow ICMPv4' -Profile Any -Direction Inbound -Action Allow -Protocol ICMPv4 -Program Any -LocalAddress Any  -RemoteAddress Any
#Install-WindowsFeature -Name "RSAT-RemoteAccess-Powershell"
Set-NetIPInterface -Forwarding Enabled



New-NetFirewallRule -Name 'COM+ Network Access' -DisplayName 'COM+ Network Access' -Description 'Allow COM+ Network Access' -Profile Any -Direction Any -Action Allow  -Program Any -LocalAddress Any  -RemoteAddress Any

Allow "COM+ Network Access"
Allow "COM+ Remote Administration"
Remote Event Log Management

route print
Get-NetAdapter

New-NetRoute -DestinationPrefix 20.0.0.0/32 -InterfaceAlias "Ethernet 5" -NextHop 20.0.0.5
New-NetRoute -DestinationPrefix 10.0.0.0/32 -InterfaceAlias "Ethernet 4" -NextHop 10.0.0.5



Set-NetIPInterface -Forwarding Enabled
route add 20.0.0.0 mask 255.255.255.0 20.0.0.5
route add 10.0.0.0 mask 255.255.255.0 10.0.0.5
route delete 20.0.0.0 mask 255.255.255.0 20.0.0.5
route delete 10.0.0.0 mask 255.255.255.0 10.0.0.5

route print

get-windowsfeature
get-windowsfeature *ad*

New-NetFirewallRule -Name 'ICMPv4' -DisplayName 'ICMPv4' -Description 'Allow ICMPv4' -Profile Any -Direction Inbound -Action Allow -Protocol ICMPv4 -Program Any -LocalAddress Any  -RemoteAddress Any
Install-WindowsFeature RemoteAccess
Install-WindowsFeature Routing -IncludeManagementTools -IncludeAllSubFeature
Rename-Computer -NewName "win2k22dc"
Add-DnsServerPrimaryZone -NetworkID “10.0.0.0/24” -ReplicationScope “domain”
Add-DnsServerPrimaryZone -NetworkID “20.0.0.0/24” -ReplicationScope “domain”
#Remove-DnsServerZone -Name  0.0.10.in-addr.arpa
Add-DnsServerResourceRecordPtr -Name "4" -ZoneName "0.0.10.in-addr.arpa" -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName "win2k22dc.class.CND46"
Add-DnsServerResourceRecordPtr -Name "4" -ZoneName "0.0.20.in-addr.arpa" -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName "win2k22dc1.class.CND46"
#Install-WindowsFeature -Name "RSAT-RemoteAccess-Powershell"
Set-NetIPInterface -Forwarding Enabled

start-service "Routing and Remote Access"
route print

RasRoutingProtocols role services
Restart-Computer



shutdown /r
</powershell>