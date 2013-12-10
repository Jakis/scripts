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
#Can be used to generate a random pass.  usage GET-Temppassword –length 19 –sourcedata $alphabet
Function GET-Temppassword() {

Param(

[int]$length=10,

[string[]]$sourcedata

)

 

For ($loop=1; $loop –le $length; $loop++) {

            $TempPassword+=($sourcedata | GET-RANDOM)

            }

return $TempPassword

}
$ascii=$NULL;For ($a=33;$a –le 126;$a++) {$ascii+=,[char][byte]$a }
$alphabet=$NULL;For ($a=65;$a –le 90;$a++) {$alphabet+=,[char][byte]$a }
function update-nagios-config
{
	#Gather the servers found in /etc/hosts.csv and append the ip to $calcservers
	$calcservers = @()
	$a = import-csv C:\etc\hosts.csv
	foreach ($server in $a){
	$calcservers += $server.ip
	}

	#Itereate through this array to copy the NSC config from deploy.
	foreach ($server in $calcservers){
	Copy-item -force 'C:\Configs\nagios\NSC.ini' "\\$($server)\c$\Program Files\NSClient++"
	write-host "Copying NSC.ini from deploy to $($server)."
	write-host "Restarting Nagios Agent."
	Invoke-Command {stop-service nscp} -Computername $server
	Invoke-Command {start-service nscp} -Computername $server
	Invoke-Command {get-service nscp} -Computername $server
	}
} 
