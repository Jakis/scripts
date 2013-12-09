function fun_ipmore
{
    Get-WmiObject -Class Win32_NetworkAdapterConfiguration -filter IPEnabled=TRUE -ComputerName . | Select-Object -property [a-z]* -ExcludeProperty IPX*,WINS*
}
function fun_build.deploy
{
    Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
    New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
    update-MDTDeploymentShare -path "DS001:" -Verbose
} 
function add-trust-host
{
     $curValue = (get-item wsman:\localhost\Client\TrustedHosts).value
     set-item wsman:\localhost\client\trustedhosts -value "$curValue, $args" -force
     $a = get-item wsman:\localhost\Client\TrustedHosts
     write-host "The Following Hosts are Trusted: "
     write-host $a.value
}
function get-trust-host
{
     $a = get-item wsman:\localhost\Client\TrustedHosts
     write-host "The Following Hosts are Trusted: "
     write-host $a.value
}

#Address a command to all nodes found in /etc/hosts.txt
function command-all-nodes
{
$command = $args
$command = [Scriptblock]::Create($command)
$servers = import-csv C:\etc\hosts.csv
write-host $servers
     foreach ($server in $servers)
     {
          $targetip = $server.ip
          $targetservername = $server.servername
              write-host "------------------------------------ HOST: $($targetservername) ($($targetip)) ------------------------------------"
          write-host "--------------- Trying command $command"
          invoke-command -scriptblock $command -ComputerName $targetip
     }
} 
