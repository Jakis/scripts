$script:toolsPath = 'c:\tools'
function fun_ipmore
{
    Get-WmiObject -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ComputerName . | Select-Object -property [a-z]* -ExcludeProperty IPX*,WINS*
}
function fun_dhcpip
{
    $a = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName . | Select-Object -property [a-z]* -ExcludeProperty IPX*,WINS*
    foreach ($nic in $a)
    {
    if ($nic.IPAddress -like "172*")
        {
            $dhcpindex = $nic.InterfaceIndex
            write-host "Detected the DHCP NIC as index $($dhcpindex)"
            $script:dhcpnic = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -filter InterfaceIndex=$dhcpindex -ComputerName . | Select-Object -property [a-z]* -ExcludeProperty IPX*,WINS*
        } 
    }
}
#Detects the type of the network card
function fun_detectNicType
{
    #Get the network adapters
    $NetworkAdapters = gwmi win32_networkadapter
    
    $targetedAdapters = @()
    $allAdapters = @()
    $nicType = 'None'
    
    #Go through each adapter and pull the SystemDriver Info
    foreach ($Adapter in $NetworkAdapters)
    {
 
        $Binary = New-Object System.Object
        
        $Reg = Get-ItemProperty -path "HKLM:\System\CurrentControlSet\Services\$($Adapter.servicename)"
        $Binary | add-Member -MemberType NoteProperty -Name Adapter -Value $Adapter.Name
        if ($Adapter.Name.Contains("Cisco VIC")) 
        {
            $nicType = "CiscoVIC"
            $targetedAdapters += $Binary
        }
        if ($Adapter.Name.Contains("I350 LOM")) 
        {
            $nicType = "IntelProSet"
            $targetedAdapters += $Binary
        }
                   
        $allAdapters += $Binary
    }
    $Script:nicType = $nicType
    $Script:nicCount = $targetedAdapters.Length
}
function fun_setteam
{
param ($activenic1
      ,$activenic2
      ,$labelnic1
      ,$labelnic2
      ,$Script:nicType)
      write-host "***********"
      write-host "* Establishing Team"
      write-host "***********" 
      write-host "Receiving NIC1 : $activenic1"
      write-host "Receiving NIC2 : $activenic2"
      write-host "Receiving Type : $Script:nicType"
      if ($Script:nicType -eq "IntelProSet")
      {
          Write-Host "NIC detected as IntelProSet"
          Import-Module 'C:\Program Files\Intel\IntelNetCmdlets\IntelNetCmdlets.ps1'
          New-IntelNetTeam -teamname "Team 0" -TeamMemberNames $activenic1, $activenic2 -TeamMode AdaptiveLoadBalancing
          start-sleep -s 3
      }
      if ($Script:nicType -eq "CiscoVIC")
      {
          write-host "NIC detected as CiscoVIC"
          $cmd = "$($Script:toolsPath)\ciscoteam\enictool.exe -p $($Script:toolsPath)\ciscoteam"
          write-host "Trying... $cmd"
          cmd.exe /c $cmd  
          $cmd = "$($Script:toolsPath)\ciscoteam\enictool.exe -c `"$($labelnic1)`" `"$($labelnic2)`" -m 3"
          write-host "Trying... $cmd"
          cmd.exe /c $cmd
          start-sleep -s 3
      }
}
function fun_setip
{
param ($targetindex
      ,$ip
      ,$subnet
      ,$gateway
      ,$primarydns
      ,$secondarydns)
    write-host "***********"
    write-host "* Set Static IP"
    write-host "***********" 
    write-host "Target Index = $targetindex"
    write-host "IP = $ip"
    write-host "Subnet = $subnet"
    write-host "gateway = $gateway"
    write-host "pridns = $primarydns"
    write-host "secdns = $secondarydns"
    <#
    #Use netsh to assign static IP info to the NIC associated with the MAC we targeted earlier:
    $cmd = 'c:\windows\system32\netsh.exe interface ip set address "' + $NICname + '" static' + " $ip $subnet $gateway"
    write-host "Trying the following command... $cmd" 
    cmd.exe /c $cmd
    $cmd = 'c:\windows\system32\netsh.exe interface ip set dnsservers "' + $NICName + '" static' + " $primarydns PRIMARY"
    write-host "Trying the following command... $cmd"
    cmd.exe /c $cmd
    #If the secondary DNS has been handed out by DHCP, attempt to set the Secondary DNS as static:
    if ($secondarydns.length -gt 0)
    {
        $cmd = 'c:\windows\system32\netsh.exe interface ipv4 add dnsserver "' + $NICName + '"' + " $secondarydns index=2"
        write-host "Trying the following command... $cmd" 
        cmd.exe /c $cmd
    }
    #>
    $targetnic = Get-WmiObject win32_networkadapterconfiguration | where{$_.Index -eq $targetindex}
    write-host $targetnic
    $DNSservers = @()
    $targetnic.EnableStatic($ip,$subnet)
    $targetnic.SetGateways($gateway)
    $DNSservers += $primarydns
    $DNSservers += $secondarydns
    $targetnic.SetDNSServerSearchOrder($DNSservers)
    $targetnic.SetDynamicDNSRegistration("TRUE")
    $targetnic.SetWINSServer($DNSservers)
    write-host "DNSservers are $($DNSservers)" 
}
function fun_disableip6
{
    param ($target)
    write-host "***********"
    write-host "* Disable IPV6"
    write-host "***********" 
    write-host "NIC to disable IPv6 for: $($target)"
    #nicCount contains the number of nics of the given type that have been detected.
    #we're assuming that the new name is "Local Area Connection X" where x is one more that the number of detected nics
    $cmd = "c:\tools\nvspbind\nvspbind.exe /d `"$($target)`" ms_tcpip6"
    write-host "Trying to disable ipv6 running command... $($cmd)"
    cmd.exe /c $cmd
}

fun_detectNicType
$ipinfo = fun_ipmore
$nicdetail = @()
foreach ($nic in $ipinfo)
{
    $index = $nic.interfaceindex 
    $nicdetail += Get-WmiObject -class win32_networkAdapter -filter interfaceindex=$index
}
write-host $nicdetail
fun_dhcpip
$ip = $script:dhcpnic.IPAddress[0]
$gateway = $script:dhcpnic.DefaultIPGateway
$subnet = $script:dhcpnic.IPSubnet[0]
$pridns = $script:dhcpnic.DNSServerSearchOrder[0]
$secdns = $script:dhcpnic.DNSServerSearchOrder[1]
$nicname1 = $ipinfo.Description[0]
$nicname2 = $ipinfo.Description[1]
$nic1label = $nicdetail.netconnectionid[0]
$nic2label = $nicdetail.netconnectionid[1]
Write-Host "Identified IP as: $($ip)"
Write-Host "Identified Gateway as: $($gateway)"
write-host "Identified Subnet as: $($subnet)"
write-host "Identified DNS Server (Primary) as: $($pridns)"
write-host "Identified DNS Server (Secondary) as: $($secdns)"
write-host "Identified NIC Type as: $Script:nicType"
write-host "Identified Adapter 1 Name as : $($nicname1)"
write-host "Identified Adapter 1 Lablel as: $($nic1label)"
write-host "Identified Adapter 1 Name as : $($nicname2)"
write-host "Identified Adapter 2 Lablel as: $($nic2label)"
fun_setteam $nicname1 $nicname2 $nic1label $nic2label $Script:nicType

write-host "TEAM INFO:"
$teaminfo = fun_ipmore
$teamindex = $teaminfo.Index
$teamnic = Get-WmiObject -class win32_networkAdapter -filter deviceid=$teamindex
write-host $teamnic
$teamName = "$($teaminfo.Description)"
$teamLabel = "$($teamnic.netconnectionid)"
write-host "Team NIC Name $($teamName)"
write-host "Team NIC Label: $($teamLabel)"
write-host "Team NIC Index: $($teamindex)"
fun_setip $teamindex $ip $subnet $gateway $pridns $secdns
fun_disableip6 $teamLabel
