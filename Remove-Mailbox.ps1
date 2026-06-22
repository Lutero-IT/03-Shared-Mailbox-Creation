Get-ADObject -SearchBase "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc" -SearchScope 1 -Filter * |
Remove-ADObject -Confirm:$false