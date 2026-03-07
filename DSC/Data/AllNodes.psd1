
##
## AllNodes.psd1 - DSC node data and conventions
## Purpose: Static data bag consumed by DSC configurations. This file
## contains node entries and structured settings used by the build
## orchestrator and DSC configurations. Only comment lines (#) are
## added by this change; no executable values were modified.
##
## Comment conventions used in this file:
## - LAB:   Notes relevant for lab/test environments (e.g. plaintext creds allowed)
## - NOTE:  Informational guidance or recommended practice
## - WARN:  Security or operational warnings (pay attention before changing)
## - KEY:   Short description of important keys and their purpose
##
## KEY explanations (quick reference):
## - NodeName: logical name used by DSC to identify the node entry
## - Role: role assigned to the node (e.g. DC, WINClient)
## - DomainName / DomainNetBIOSName / DomainDN: AD domain identifiers
## - ForestMode / DomainMode: AD functional levels for forest/domain
## - InstallADDS / InstallRSAT / InstallGPMC: booleans that drive feature installation
## - InterfaceAlias_*/IPv4Address_*/DnsServers_*: network configuration values
## - PsDscAllowPlainTextPassword / PsDscAllowDomainUser: LAB-only DSC runtime flags
##   WARN: In production, credentials must be injected securely and MOFs encrypted
## - OrganizationalUnits: list of OUs to create (Key, Name, ParentPath, etc.)
## - SecurityGroups: definitions for Global/DomainLocal groups used with AGDLP
## - Delegations: AD permission delegations to grant limited rights to groups
## - ADUsers: user accounts to provision (UserName, OUPath, GroupMembership, etc.)
## - PasswordPolicy: domain password/lockout settings (min length, history, lockout)
## - GroupPolicies / GPOLinks / GPORegistryValues / GPOPermissions: GPO definitions,
##   where GPORegistryValues map a policy to a registry key/value enforced by a GPO
## - DefaultComputerOU / ADComputers: default OU for joins and pre-staged computers
##
## NOTE: Treat this file as data only. The orchestrator (`Run_BuildMain.ps1`)
## injects credentials and performs MOF encryption in non-lab environments.
##
@{
    AllNodes = @(
        @{
            NodeName   = 'localhost'
            Role       = 'DC'

            # Active Directory Settings
            DomainName = 'barmbuzz.corp'
            DomainNetBIOSName = 'BARMBUZZ'
            ForestMode = 'WinThreshold'
            DomainMode = 'WinThreshold'


            # Computer Settings
            ComputerName = 'BB-DC01'
            TimeZone     = 'GMT Standard Time'
            EnsureW32Time = $true
            
            #Install features    
            InstallADDS = $true
            InstallRSAT = $true
            InstallADDSRole = $true
            InstallRSATADDS = $true
            InstallGPMC = $true

            # Network Configuration (Dual NIC setup for DC)
            InterfaceAlias_Internal = 'Ethernet 2'
            IPv4Address_Internal = '192.168.99.10/24'
            DefaultGateway_Internal = $null
            PrefixLength_Internal = 24
            #SubnetMask_Internal = '255.255.255.0'
            DnsServers_Internal = '192.168.99.10'

            # Network Settings External NIC
            InterfaceAlias_NAT = 'Ethernet'
            DisableDnsRegistrationOnNat = $true

            # Security Settings
            PsDscAllowPlainTextPassword = $true  # ALLOWED FOR LABS ONLY
            PsDscAllowDomainUser = $true         # ALLOWED FOR LABS ONLY

            OrgName = 'BarmBuzz'
            OrgPrefix = 'BB'
            
            DomainDN = 'DC=barmbuzz,DC=corp'

            OrganizationalUnits = @(
                # --ROOT-----------------
                @{ Key = 'BarmBuzz';                     Name = 'BarmBuzz';              ParentPath = '';                                                     DependsOnKey = $null;              Protected = $true;           Description = 'BarmBuzz enterprise root - Silicon Bolton HQ' } 

                # -- Tier0 -------------
                @{ Key = 'Tier0';                        Name = 'Tier0';                 ParentPath = 'OU=BarmBuzz';                                          DependsOnKey = 'BarmBuzz';         Protected = $true;           Description = 'Domain control plane - restricted admin tier' }
                @{ Key = 'Tier0_Admins';                 Name = 'Admins';                ParentPath = 'OU=Tier0,OU=BarmBuzz';                                 DependsOnKey = 'Tier0';            Protected = $true;           Description = 'Domain administrator accounts' }
                @{ Key = 'Tier0_Servers';                Name = 'Servers';               ParentPath = 'OU=Tier0,OU=BarmBuzz';                                 DependsOnKey = 'Tier0';            Protected = $true;           Description = 'Domain infrastructure servers (DSc, PKI)' }
                @{ Key = 'Tier0_ServiceAccounts';        Name = 'ServiceAccounts';       ParentPath = 'OU=Tier0,OU=BarmBuzz';                                 DependsOnKey = 'Tier0';            Protected = $true;           Description = 'Service accounts for domain-level operations' }

                #--Sites --Bolton-----------------

                @{ Key = 'Sites';                        Name = 'Sites';                 ParentPath = 'OU=BarmBuzz';                                          DependsOnKey = 'BarmBuzz';         Protected = $true;           Description = 'Geographic site containers' }
                @{ Key = 'Bolton';                       Name = 'Bolton';                ParentPath = 'OU=Sites,OU=BarmBuzz';                                 DependsOnKey = 'Sites';            Protected = $true;           Description = 'Bolton HQ - Silicon Croal Valley campus' }
                @{ Key = 'Bolton_Users';                 Name = 'Users';                 ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz';                       DependsOnKey = 'Bolton';           Protected = $true;           Description = 'Bolton staff - baristas, managers, drivers' }
                @{ Key = 'Bolton_Computers';             Name = 'Computers';             ParentPath = 'OU=Bolton,OU=Sites,OU=BarmBuzz';                       DependsOnKey = 'Bolton';           Protected = $true;           Description = 'Bolton computer accounts' }
                @{ Key = 'Bolton_Workstations';          Name = 'Workstations';          ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz';          DependsOnKey = 'Bolton_Computers'; Protected = $true;           Description = 'Staff workstations - office and depot machines' }
                @{ Key = 'Bolton_POS';                   Name = 'POS';                   ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz';          DependsOnKey = 'Bolton_Computers'; Protected = $true;           Description = 'POS terminals at Barm Unloading Sectors (bus stops)' }
                @{ Key = 'Bolton_Kiosks';                Name = 'Kiosks';                ParentPath = 'OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz';          DependsOnKey = 'Bolton_Computers'; Protected = $true;           Description = 'Self-service ordering Kiosks' } 

                #--Groups-----------------
                @{ Key = 'Groups';                       Name = 'Groups';                ParentPath = 'OU=BarmBuzz';                                          DependsOnKey = 'BarmBuzz';         Protected = $true;           Description = 'Security and distribution group containers' }
                @{ Key = 'Groups_Role';                  Name = 'Role';                  ParentPath = 'OU=Groups,OU=BarmBuzz';                                DependsOnKey = 'Groups';           Protected = $true;           Description = 'Global role groups (AGDLP: the G layer)' }
                @{ Key = 'Groups_Resource';              Name = 'Resource';              ParentPath = 'OU=Groups,OU=BarmBuzz';                                DependsOnKey = 'Groups';           Protected = $true;           Description = 'Domain local resource groups (AGDLP: the DL layer)' }
                
                #--Clients -----------------
                @{ Key = 'Clients';                      Name = 'Clients';               ParentPath = 'OU=BarmBuzz';                                          DependsOnKey = 'BarmBuzz';         Protected = $true;           Description = 'Domain-joined client machines by OS type' }
                @{ Key = 'Clients_Windows';              Name = 'Windows';               ParentPath = 'OU=Clients,OU=BarmBuzz';                               DependsOnKey = 'Clients';          Protected = $true;           Description = 'Windows domain-joined clients' }
                @{ Key = 'Clients_Linux';                Name = 'Linux';                 ParentPath = 'OU=Clients,OU=BarmBuzz';                               DependsOnKey = 'Clients';          Protected = $true;           Description = 'Linux domain-joined clients (realmd/sssd)' }  

            ) 

            SecurityGroups = @( 
                #---Role Groups (Global)----------------
                @{ Key = 'GG_Bolton_Baristas';     GroupName = 'GG_BB_Bolton_Baristas';      GroupScope = 'Global';        Category = 'Security';   OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz';      DependsOnOUKey = 'Groups_Role';     MembersToInclude = $null;                                                   Description = 'Bolton baristas - barm assembly and HVBSDP delivery' } 
                @{ Key = 'GG_Bolton_Managers';     GroupName = 'GG_BB_Bolton_Managers';      GroupScope = 'Global';        Category = 'Security';   OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz';      DependsOnOUKey = 'Groups_Role';     MembersToInclude = $null;                                                   Description = 'Bolton managers - depot and route supervisors' }
                @{ Key = 'GG_Bolton_Helpdesk';     GroupName = 'GG_BB_IT_Helpdesk';          GroupScope = 'Global';        Category = 'Security';   OUPath = 'OU=Role,OU=Groups,OU=BarmBuzz';      DependsOnOUKey = 'Groups_Role';     MembersToInclude = $null;                                                   Description = 'IT helpdesk - delegated workstation and user support' } 

                #--------Resource Groups (Domain Local)----------------
                @{ Key = 'DL_POS_LocalAdmins';     GroupName = 'DL_BB_POS_LocalAdmins';      GroupScope = 'DomainLocal';   Category = 'Security';   OUPath = 'OU=Resource,OU=Groups,OU=BarmBuzz';  DependsOnOUKey = 'Groups_Resource'; MembersToInclude = @('GG_BB_Bolton_Baristas');                              Description = 'Local admin on POS terminals at Barm Unloading Sectors' }
                @{ Key = 'DL_Recipes_Read';        GroupName = 'DL_BB_Recipes_Read';         GroupScope = 'DomainLocal';   Category = 'Security';   OUPath = 'OU=Resource,OU=Groups,OU=BarmBuzz';  DependsOnOUKey = 'Groups_Resource'; MembersToInclude = @('GG_BB_Bolton_Baristas','GG_BB_Bolton_Managers');      Description = 'Read access to recipe repository (carb engineering specs)' }
                @{ Key = 'DL_Recipes_Write';       GroupName = 'DL_BB_Recipes_Write';        GroupScope = 'DomainLocal';   Category = 'Security';   OUPath = 'OU=Resource,OU=Groups,OU=BarmBuzz';  DependsOnOUKey = 'Groups_Resource'; MembersToInclude = @('GG_BB_Bolton_Managers');                              Description = 'Write access to recipe repository (managers only)' } 


            )


            #----DELEGATIONS-----------

            Delegations = @(
                @{
                    Key                    = 'Delegate_Workstation_Join'
                    TargetOUPath           = 'OU=Workstations,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                    IdentityGroupName      = 'GG_BB_IT_Helpdesk'
                    DependsOnOUKey         = 'Bolton_Workstations'
                    DependsOnGroupKey      = 'GG_Bolton_Helpdesk'
                    Rights                 = @('CreateChild','DeleteChild')
                    AccessControlType      = 'Allow'
                    ObjectTypeGuid         = 'bf967a86-0de6-11d0-a285-00aa003049e2'
                    InheritanceType        = 'All'
                    InheritedObjectType    = '00000000-0000-0000-0000-000000000000'
                    Description            = 'Allow IT Helpdesk to join/remove workstations in Bolton'
                }
            )


           ADUsers = @( 
            @{
                Key                     = 'ava_barista'
                UserName                = 'ava_barista'
                GivenName               = 'Ava'
                Surname                 = 'Barista'
                DisplayName             = 'Ava Barista'
                UserPrincipalName       = 'ava_barista@barmbuzz.corp'
                OUPath                  = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnOUKey          = 'Bolton_Users'
                GroupMembership         = @('GG_BB_Bolton_Baristas')
                JobTitle                = 'Senior Barista'
                Department              = 'Barm Assembly'
                Description             = 'Bolton barista - HVBSDP certified'
                ChangePasswordAtLogon   = $true 
            }
            @{
                Key                     ='bob_manager'
                UserName                = 'bob_manager'
                GivenName               = 'Bob'
                Surname                 = 'Manager'
                DisplayName             = 'Bob Manager'
                UserPrincipalName       = 'bob_manager@barmbuzz.corp'
                OUPath                  = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnOUKey          = 'Bolton_Users'
                GroupMembership         = @('GG_BB_Bolton_Managers')
                JobTitle                = 'Depot Manager'
                Department              = 'Operations'
                Description             = 'Bolton depot manager - route supervisor'
                ChangePasswordAtLogon   = $true 
            }
            @{
                Key                     = 'charlie_helpdesk'
                UserName                = 'charlie_helpdesk'
                GivenName               = 'Charlie'
                Surname                 = 'Helpdesk'
                DisplayName             = 'Charlie Helpdesk'
                UserPrincipalName       = 'charlie_helpdesk@barmbuzz.corp'
                OUPath                  = 'OU=Users,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnOUKey          = 'Bolton_Users'
                GroupMembership         = @('GG_BB_IT_Helpdesk')
                JobTitle                = 'IT Helpdesk Analyst'
                Department              = 'IT'
                Description             = 'IT helpdesk - delegated workstation and user support'
                ChangePasswordAtLogon   = $true 


            }
           )


           #----Password Policy---------
           PasswordPolicy = @{
            ComplexityEnabled            = $true
            MinPasswordLength            = 10
            PasswordHistoryCount         = 12
            MaxPasswordAge               = 129600 #90 days 
            MinPasswordAge               = 1440 #1 day
            LockoutThreshold             = 5
            LockoutDuration              = 30 #30 minutes
            LockoutObservationWindow     = 30 #30 minutes
            ReversibleEncryptionEnabled  = $false

           }

           #---Group Policies----
           GroupPolicies = @(
            @{
                Key         = 'GPO_Workstations_Baseline'
                Name        = 'BB_Workstations_Baseline'
                Description = 'BarmBuzz workstation security baseline - LM hash, SMB signing, screensaver'
            }
            @{
                Key         = 'GPO_Servers_Baseline'
                Name        = 'BB_Servers_Baseline'
                Description = 'BarmBuzz server hardening baseline - audit log, SMBv1 disable'
            }
            @{
                Key         = 'GPO_POS_Lockdown'
                Name        = 'BB_POS_Lockdown'
                Description = 'POS terminal lockdown - USB restrictions, logon banner, enforced' 
            }
            @{
                Key         = 'GPO_AllUsers_Banner'
                Name        = 'BB_AllUsers_Banner'
                Description = 'Organisation-wide logon banner - legal notice, acceptable use'
            }

           )

           GPOLinks = @(
            @{
                Key                = 'Link_WksBaseline_Workstations'
                GPOName            = 'BB_Workstations_Baseline'
                TargetOUPath       = 'OU=Workstations,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnGPO       = 'GPO_Workstations_Baseline'
                DependsOnOUKey     = 'Bolton_Workstations'
                Order              = 1
                Enforced           = 'No'
                LinkEnabled        = 'Yes'
            }
            @{
                Key                = 'Link_SrvBaseline_Servers'
                GPOName            = 'BB_Servers_Baseline'
                TargetOUPath       = 'OU=Servers,OU=Tier0,OU=BarmBuzz'
                DependsOnGPO       = 'GPO_Servers_Baseline'
                DependsOnOUKey     = 'Tier0_Servers'
                Order              = 1
                Enforced           = 'No'
                LinkEnabled        = 'Yes'
            }
            @{
                Key                = 'Link_POSLockdown_POS'
                GPOName            = 'BB_POS_Lockdown'
                TargetOUPath       = 'OU=POS,OU=Computers,OU=Bolton,OU=Sites,OU=BarmBuzz'
                DependsOnGPO       = 'GPO_POS_Lockdown'
                DependsOnOUKey     = 'Bolton_POS'
                Order              = 1
                Enforced           = 'Yes' 
                LinkEnabled        = 'Yes'
            }
            @{
                Key                = 'Link_Banner_BarmBuzz'
                GPOName            = 'BB_AllUsers_Banner'
                TargetOUPath       = 'OU=BarmBuzz'
                DependsOnGPO       = 'GPO_AllUsers_Banner'
                DependsOnOUKey     = 'BarmBuzz'
                Order              = 1
                Enforced           = 'No'
                LinkEnabled        = 'Yes'

            }
           )
        #Workstation Baseline
           GPORegistryValues = @(
            @{
                Key          = 'WKs_NoLMHash'
                GPOName      = 'BB_Workstations_Baseline'
                DependsOnGPO = 'GPO_Workstations_Baseline'
                RegistryKey   = 'HKLM\System\CurrentControlSet\Control\Lsa'
                ValueName    = 'NoLMHash'
                ValueType    = 'DWord'
                ValueData    = '1'
                Description  = 'Disable LM hash storage - prevents weak hash creation'
            }
            @{
                Key          = 'WKs_SMBSigning' 
                GPOName      = 'BB_Workstations_Baseline' 
                DependsOnGPO = 'GPO_Workstations_Baseline'
                RegistryKey  = 'HKLM\System\CurrentControlSet\Services\LanManServer\Parameters'
                ValueName    = 'RequireSecuritySignature'
                ValueType    = 'DWord'
                ValueData    = '1'
                Description  = 'Require SMB signing - prevents relay attacks'
            }
            @{
                Key          = 'WKs_NTLMv2Only'
                GPOName      = 'BB_Workstations_Baseline' 
                DependsOnGPO = 'GPO_Workstations_Baseline' 
                RegistryKey  = 'HKLM\System\CurrentControlSet\Control\Lsa'
                ValueName    = 'LmCompatibilityLevel'
                ValueType    = 'DWord'
                ValueData    = '5'
                Description  = 'NTLMv2 only - refuses LM and NTLMv1'  
             }
             @{
                Key          = 'WKs_ScreenSaver'
                GPOName      = 'BB_Workstations_Baseline' 
                DependsOnGPO = 'GPO_Workstations_Baseline' 
                RegistryKey  = 'HKCU\Control Panel\Desktop'
                ValueName    = 'ScreenSaveTimeOut'
                ValueType    = 'String'
                ValueData    = '600'
                Description  = 'Screen saver timrout 10 min - unattended session lock'
             }
             #Server Baseline
             @{
                Key          = 'Srv_AuditLogSize'
                GPOName      = 'BB_Servers_Baseline' 
                DependsOnGPO = 'GPO_Servers_Baseline' 
                RegistryKey  = 'HKLM\System\CurrentControlSet\Services\EventLog\Security'
                ValueName    = 'MaxSize'
                ValueType    = 'DWord'
                ValueData    = '1048576'
                Description  = 'Security event log 1GB - sufficient for DC audit trail'
             }
             @{
                Key          = 'Srv_SMB1Disable'
                GPOName      = 'BB_Servers_Baseline' 
                DependsOnGPO = 'GPO_Servers_Baseline' 
                RegistryKey  = 'HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters'
                ValueName    = 'SMB1'
                ValueType    = 'DWord'
                ValueData    = '0'
                Description  = 'Disable SMBv1 - WannaCry prevention, protocol hygiene' 
             }

             #POS Lockdown
             @{
                Key          = 'POS_NoUSB'
                GPOName      = 'BB_POS_Lockdown' 
                DependsOnGPO = 'GPO_POS_Lockdown' 
                RegistryKey  = 'HKLM\System\CurrentControlSet\Services\USBSTOR'
                ValueName    = 'Start'
                ValueType    = 'DWord'
                ValueData    = '4'
                Description  = 'Disable USB storage - prevents data exfiltration from POS terminals' 
             }
             @{
                Key          = 'POS_LogonBanner'
                GPOName      = 'BB_POS_Lockdown' 
                DependsOnGPO = 'GPO_POS_Lockdown' 
                RegistryKey  = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                ValueName    = 'LegalNoticeText'
                ValueType    = 'String'
                ValueData    = 'BarmBuzz POS Terminal - Authorised use only. All activity is monitored.'
                Description  = 'Logon banner - legal notice for POS terminals' 
             }
             #Organisation-wide Banner
             @{
                Key          = 'Banner_Title'
                GPOName      = 'BB_AllUsers_Banner' 
                DependsOnGPO = 'GPO_AllUsers_Banner' 
                RegistryKey  = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                ValueName    = 'LegalNoticeCaption'
                ValueType    = 'String'
                ValueData    = 'BarmBuzz Corp - Acceptable Use Policy' 
                Description  = 'Logon banner title - organisation-wide legaal notice' 
             }
             @{
                Key          = 'Banner_Text'
                GPOName      = 'BB_AllUsers_Banner' 
                DependsOnGPO = 'GPO_AllUsers_Banner' 
                RegistryKey  = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'
                ValueName    = 'LegalNoticeText'
                ValueType    = 'String'
                ValueData    = 'This system is the property of BarmBuzz Corporation. Unauthorised access is prohibited and will be prosecuted. All activity is logged and monitored.'
                Description  = 'Logon banner body - legal compliance and deterrence' 
             }
            )

            GPOPermissions = @(
                @{
                    Key           = 'Perm_POS_Baristas'
                    GPOName       = 'BB_POS_Lockdown'
                    DependsOnGPO  = 'GPO_POS_Lockdown'
                    TargetName    = 'GG_BB_Bolton_Baristas'
                    TargetType    = 'Group'
                    Permission    = 'GpoApply' 
                }
             )

           #--default computer container 
           DefaultComputerOU = 'OU=Windows,OU=Clients,OU=BarmBuzz'

           #==pre-staged computer accounts---------
           ADComputers = @(
            @{
                Key          = 'BB_WIN11_01'
                ComputerName = 'BB-WIN11-01'
                OUPath       = 'OU=Windows,OU=Clients,OU=BarmBuzz'
                DependsOnOU  = 'Clients_Windows'
                Description  = 'Windows 11 Client - Bolton office workstation'
            }
            @{
                Key          = 'BB_LNX_01'
                ComputerName = 'BB-LNX-01'
                OUPath       = 'OU=Linux,OU=Clients,OU=BarmBuzz'
                DependsOnOU  = 'Clients_Linux'
                Description  = 'Ubuntu 24.04 LTS - BarmBuzz Linux client'
            }
           )

          # Security settings 
            # PsDscAllowPlainTextPassword and PsDscAllowDomainUser are already defined above
            # SECURITY NOTE: Future credential properties will be added by the orchestrator
            # at runtime, not stored here. Example (YOU DON'T ADD THIS YET):
            # DomainCredential = $PSCredentialObject  # Injected by Run_BuildMain.ps1
            
            # CERTIFICATE ENCRYPTION (Production pattern - informational for now):
            # CertificateFile = 'C:\Certs\DscPublicKey.cer'  # Public key for MOF encryption
            # Thumbprint = '1234567890ABCDEF...'            # Certificate thumbprint
            # PsDscAllowPlainTextPassword = $false           # Force encryption (production)
        }

        @{
            NodeName                    = 'BB-WIN11-01'
            Role                        = 'WINClient'

            ## Computer Settings
            ComputerName                = 'BB-WIN11-01'
            TimeZone                    = 'GMT Standard Time'
            
            #Netwok - point DNS at the DC
            InterfaceAlias_Internal     = 'Ethernet'
            DnsServerAddress            = '127.0.0.1' 

            #Domain join setting 
            DomainName                  = 'barmbuzz.corp'
            DomainNetBIOSName           = 'BARMBUZZ'
            DomainDN                    = 'DC=barmbuzz,DC=corp'
            joinOU                      = 'OU=Windows,OU=Clients,OU=BarmBuzz,DC=barmbuzz,DC=corp' 

            PsDscAllowPlainTextPassword = $true
            PsDscAllowDomainUser        = $true 
        }
    )
}