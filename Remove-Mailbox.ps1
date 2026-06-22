param(
    [string]$OUPath = "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
)

Get-ADObject -SearchBase $OUPath -SearchScope 1 -Filter * | Remove-ADObject -Confirm:$false