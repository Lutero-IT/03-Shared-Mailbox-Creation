# Shared Mailbox Creator
An interactive PowerShell-based automation tool designed for system administrators
to streamline the provisioning of Shared Mailbox infrastructure in Active Directory.

The script automates the complete lifecycle setup by creating a fully provisioned user account designated for the Shared Mailbox role, along with its associated access group. Operators can manage group memberships (including individual users and nested security groups) on-the-fly via an interactive console interface, transforming a tedious, multi-step deployment into a single, cohesive workflow.

## Key Features
- **Comprehensive Exception Handling & Security Verification:** 
Integrates a robust validation layer that checks for administrative privileges upon startup. It actively intercepts domain permission deficiencies, network or replication faults, Active Directory object constraint violations, and password complexity policy infractions.
- **Strict Input Validation via Regex:**
Utilizes advanced regular expressions to sanitize and validate user-supplied department names, preventing syntax errors or invalid directory object naming conventions before provisioning begins.
- **Intelligent Resource Linking & Automation:**
Upon successful creation of the Shared Mailbox account and access group, the script automatically queries Active Directory for an existing group matching the department's name. If discovered, it prompts the operator to automatically nest it, significantly reducing manual administrative overhead.
- **End-to-End Post-Deployment Management:**
Features a built-in interactive management menu to handle full lifecycle configuration immediately after creation. Operators can safely audit, add, or remove members—supporting both individual users and group nesting workflows.
- **Interactive TUI with Keyboard Navigation:**
Replaces legacy, error-prone text prompts with an intuitive, arrow-key-driven console menu interface, enhancing operator efficiency and eliminating input typos.

## Prerequisites & Environmental Requirements
Before executing the script, ensure your environment conforms to the following specifications:

- **Operating System:** Windows 10/11 or Windows Server (2016 or higher).
- **PowerShell Version:** PowerShell 5.1 or PowerShell Desktop/Core 7+.
- **Active Directory Module:** The native `ActiveDirectory` remote server administration tools (RSAT) module must be installed to support domain cmdlets.
- **Domain Connectivity:** The script must be executed directly on a Domain Controller or a workstation with an active line-of-sight/remote connection to the target Active Directory domain.

---

## IMPORTANT: Remote Session Requirements (SSH vs. WinRM)
If you are executing this script via a remote session (not directly logged into the server console), **you must connect using the SSH protocol instead of the standard WinRM (`Enter-PSSession`) cmdlet.** 

Standard WinRM sessions lack a **PTY (Pseudo-Terminal)** allocation, which means the PowerShell host cannot process raw keypress events. As a result, WinRM does not support key recognition for the interactive arrow-key menu navigation, causing the interface to fail[cite: 5]. SSH natively allocates a PTY, allowing the `[Console]::ReadKey()` method to capture terminal inputs seamlessly[cite: 5].

#### Step-by-Step: Enabling SSH Server on the Target Host
The OpenSSH Client is installed by default on modern Windows OS versions, but the OpenSSH Server capability must be explicitly enabled on the target server.

Execute the following commands in an elevated PowerShell session on the target server:

1. **Install the OpenSSH Server feature:**
```powershell
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```
2. **Configure and start the SSH service:**
```powershell
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'
```
3. **Verify the inbound Firewall rule is enabled:**
``` powershell
Get-NetFirewallRule -Name *ssh* | Select-Object Name, Enabled, Direction
```

### How to Connect via SSH
To establish a proper remote PTY session from your management workstation, use the standard SSH syntax pointing to either the Server's Full Domain Name (FQDN) or its IP address.

**Command Structure:**
```bash
ssh domain_user@server_fqdn
# OR (if using down-level logon names)
ssh domain\\domain_user@server_ip
```

**Real-World Examples:**
```bash
# Connecting using full domain routing
ssh administrator@OldCampServer.oldcamp.gothic.inc

# Connecting directly via IP with domain qualification
ssh oldcamp\\administrator@192.168.1.10
```

## Installation & Setup
1. Clone or download this repository to your local machine.
2. IMPORTANT: The `Show-ArrowMenu.ps1` and `Manage-ADGroupMembers.ps1` files must reside in the exact same directory as the main `New-SharedMailbox.ps1` script. (Note: If you decide to move this file to a different directory, you must manually update its path in the # IMPORTED FUNCTIONS # section at the top of the main script).

## Usage / How to Run
Open your PowerShell terminal, navigate to the script directory, and execute the script.
You can run it with your custom Active Directory OU path:

```powershell
.\New-SharedMailbox.ps1 -OUPath "OU=Shared Mailboxes,OU=Resources,OU=Camp,DC=oldcamp,DC=gothic,DC=inc"
```

**Note**: The -OUPath parameter is pre-configured with a default value. If you do not provide this parameter, the script will automatically search for groups within that default path.

## Future Roadmap & Exchange Server Integration
The current architecture of this tool focus exclusively on the **Active Directory Identity Layer** (provisioning users, security groups, and managing organizational structures). In a real-world production environment, to make the Shared Mailbox operational within an email system like Exchange Server (On-Premises) or Exchange Online (Microsoft 365), a **Mail-Enabling phase** is required.

Since this project was developed in a dedicated Active Directory lab environment without a live Exchange Server, the following native Exchange management cmdlets would be integrated into the next deployment phase:

### 1. Mail-Enabling the AD Account
To convert the newly created Active Directory user account into an official Shared Mailbox, the `Enable-Mailbox` cmdlet must be executed:
```powershell
# Executed via Exchange Management Shell (EMS)
Enable-Mailbox -Identity "sm_$name" -Shared -Alias "sm_$name"
```

### 2. Delegating Access via the Security Group
To automatically grant permissions to all members of the associated access group
(sg_sm_${name}_access), two distinct types of access rights must be assigned onto the mailbox:

* Full Access Permissions (Allows members to open and view the mailbox contents):
```powershell
Add-MailboxPermission -Identity "sm_$name" -User "sg_sm_${name}_access" -AccessRights FullAccess -InheritanceType All
```

* Send As Permissions (Allows members to send emails out of this mailbox identity):
```powershell
Add-RecipientPermission -Identity "sm_$name" -Trustee "sg_sm_${name}_access" -AccessRights SendAs -Confirm:$false
```