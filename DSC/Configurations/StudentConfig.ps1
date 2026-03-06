


Configuration StudentBaseline {

    param(

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $DomainAdminCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $DsrmCredential,

        [Parameter(Mandatory = $true)]
        [PSCredential]
        $UserCredential
    ) 

    #####  IMPORT DSC RESOURCES 
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName ActiveDirectoryDSC
    Import-DscResource -ModuleName NetworkingDSC
    Import-DscResource -ModuleName GroupPolicyDsc
    Import-DscResource -ModuleName GPRegistryPolicyDsc


    Node $AllNodes.Where{ $_.Role -eq 'DC' }.NodeName 
    {

        
        #####  Use the Computer resource from ComputerManagementDsc to set the computer name based on the ComputerName property in AllNodes.psd1. This demonstrates how to use configuration data to drive your DSC configuration, and it aligns with the expected state defined in your test harness.

        Computer SetName {
            Name = $Node.ComputerName
        }
        #####  Set The Timezone
        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone         = $Node.TimeZone
        } 

        Service WindowsTime {

            Name        = 'W32Time'
            State       = 'Running'
            StartupType = 'Automatic'
            DependsOn   = '[TimeZone]SetTimeZone'
        }

        #####  Network Settings - Internal NIC

        #IPAddress InternalIP 
        #{
        #    InterfaceAlias = $Node.InterfaceAlias_Internal
        #    AddressFamily = 'IPv4'
        #    IPAddress = $Node.IPv4Address_Internal
        #    PrefixLength = $Node.PrefixLength_Internal
        #    SubnetMask = $Node.SubnetMask_Internal
        #}

        IPAddress InternalIP { 
            InterfaceAlias = $Node.InterfaceAlias_Internal 
            IPAddress      = $Node.IPv4Address_Internal
            AddressFamily  = 'IPv4' 
            #PrefixLength = $Node.PrefixLength_Internal
        } 

        NetIPInterface InternalPrefix { 
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4' 
            #NlMtu = 1500 
            Dhcp           = 'Disabled'
            DependsOn      = '[IPAddress]InternalIP' 
        }

        if ($Node.DefaultGateway_Internal) {
            DefaultGatewayAddress InternalGW {
                InterfaceAlias = $Node.InterfaceAlias_Internal
                AddressFamily  = 'IPv4'
                Address        = $Node.DefaultGateway_Internal
                DependsOn      = '[NetIPInterface]InternalPrefix'
            }
        }


        DnsServerAddress InternalDNS {
            #InterfaceAlias: Same NIC as our static IP
            InterfaceAlias = $Node.InterfaceAlias_Internal
            AddressFamily  = 'IPv4'
            Address        = $Node.DnsServers_Internal
            DependsOn      = '[IPAddress]InternalIP'
        }
        
        DnsConnectionSuffix EnableInternalRegistration {
            InterfaceAlias                 = $Node.InterfaceAlias_Internal
            ConnectionSpecificSuffix       = $Node.DomainName
            RegisterThisConnectionsAddress = $true 
            UseSuffixWhenRegistering       = $true
            DependsOn                      = '[DnsServerAddress]InternalDNS'
        }

        NetAdapterBinding DisableIPv6 {
            InterfaceAlias = $Node.InterfaceAlias_Internal
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
        }

        ####  Network Settings - External NIC

        DnsServerAddress NATDNS {
            InterfaceAlias = $Node.InterfaceAlias_NAT
            AddressFamily  = 'IPv4'
            #Address        =  @()   # empty = no DNS servers
        }

        DnsConnectionSuffix DisableNatRegistration {
            InterfaceAlias                 = $Node.InterfaceAlias_NAT
            ConnectionSpecificSuffix       = 'local'
            RegisterThisConnectionsAddress = $false
            UseSuffixWhenRegistering       = $false
            DependsOn                      = '[DnsServerAddress]NATDNS'
        }

        NetAdapterBinding DisableIPv6NAT {
            InterfaceAlias = $Node.InterfaceAlias_NAT
            ComponentId    = 'ms_tcpip6'
            State          = 'Disabled'
        }

        ####  Install AD DS and RSAT tools

        WindowsFeature ADDS {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature RSAT-ADDS {
            Name      = 'RSAT-AD-Tools'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }

        #### Promote to Domain Controller and Create the new Forest and Domain

        ADDomain CreateForest {
            DomainName                    = $Node.DomainName
            DomainNetBIOSName             = $Node.DomainNetBIOSName
            Credential                    = $DomainAdminCredential
            SafeModeAdministratorPassword = $DsrmCredential
            ForestMode                    = $Node.ForestMode
            DomainMode                    = $Node.DomainMode
            DependsOn                     = @(
                '[WindowsFeature]ADDS'
                '[WindowsFeature]RSAT-ADDS'
                '[DnsConnectionSuffix]EnableInternalRegistration'
            )
        }


        $DomainQualifiedCred = New-Object PSCredential(
            "$($Node.DomainNetBIOSName)\Administrator",
            $DomainAdminCredential.Password
        )

        WaitForADDomain WaitForBarmBuzz {
            DomainName  = $Node.DomainName
            Credential  = $DomainQualifiedCred
            WaitTimeout = 300
            DependsOn   = '[ADDomain]CreateForest'
        }

        foreach ($ou in $Node.OrganizationalUnits) {

            $ouPath = if ($ou.ParentPath) { "$($ou.ParentPath), $($Node.DomainDN)" } else { $Node.DomainDN } 

            $oudep = if ($ou.DependsOnKey) { "[ADOrganizationalUnit]OU_$($ou.DependsOnKey)" } else { "[WaitForADDomain]WaitForBarmBuzz" } 


            ADOrganizationalUnit "OU_$($ou.Key)" {

                Name                            = $ou.Name
                Path                            = $ouPath
                Description                     = $ou.Description
                ProtectedFromAccidentalDeletion = $ou.Protected 
                Ensure                          = 'Present' 
                Credential                      = $DomainAdminCredential
                DependsOn                       = $oudep
            }

        } #End of OU Loop


        foreach ($grp in $Node.SecurityGroups) {

            $grpPath = "$($grp.OUPath),$($Node.DomainDN)" 
            $deps = @("[ADOrganizationalUnit]OU_$($grp.DependsOnOUKey)")

            if ($grp.MembersToInclude) {
                foreach ($memberName in $grp.MembersToInclude) {
                    $memberGrp = $Node.SecurityGroups | Where-Object { $_.GroupName -eq $memberName }
                    if ($memberGrp) { $deps += "[ADGroup]Group_$($memberGrp.Key)" }
                }


                ADGroup "Group_$($grp.Key)" {
                    GroupName        = $grp.GroupName
                    GroupScope       = $grp.GroupScope
                    Category         = $grp.Category
                    Path             = $grpPath
                    Description      = $grp.Description
                    MembersToInclude = $grp.MembersToInclude
                    Ensure           = 'Present'
                    Credential       = $DomainAdminCredential
                    DependsOn        = $deps
                }

            } 

            else {
                ADGroup "Group_$($grp.Key)" {
                    GroupName   = $grp.GroupName
                    GroupScope  = $grp.GroupScope
                    Category    = $grp.Category
                    Description = $grp.Description
                    Path        = $grpPath
                    Ensure      = 'Present'
                    Credential  = $DomainAdminCredential
                    DependsOn   = $deps
                }

            } #End of Group Loop

        }



        #### POST-PROMOTION-DELEGATION

        foreach ($deleg in $Node.Delegations) {

            $delegPath = "$($deleg.TargetOUPath),$($Node.DomainDN)"
            $delegIdentity = "$($Node.DomainNetBIOSName)\$($deleg.IdentityGroupName)"

            ADObjectPermissionEntry $deleg.Key {

                Ensure                             = 'Present'
                Path                               = $delegPath
                IdentityReference                  = $delegIdentity
                ActiveDirectoryRights              = $deleg.Rights
                AccessControlType                  = $deleg.AccessControlType
                ObjectType                         = $deleg.ObjectTypeGuid
                ActiveDirectorySecurityInheritance = $deleg.InheritanceType
                InheritedObjectType                = $deleg.InheritedObjectType
                DependsOn                          = "[ADGroup]Group_$($deleg.DependsOnGroupKey)", "[ADOrganizationalUnit]OU_$($deleg.DependsOnOUKey)" 
            }

        }

        #### POST-PROMOTION-AD USERS

        foreach ($user in $Node.ADUsers) {
            $userPath = "$($user.OUPath),$($Node.DomainDN)"

            ADUser "User_$($user.Key)" {

                DomainName            = $Node.DomainName
                UserName              = $user.UserName
                GivenName             = $user.GivenName
                Surname               = $user.Surname
                DisplayName           = $user.DisplayName
                UserPrincipalName     = $user.UserPrincipalName
                Path                  = $userPath
                JobTitle              = $user.JobTitle
                Department            = $user.Department
                Description           = $user.Description
                Password              = $UserCredential
                PasswordNeverResets = $false
                ChangePasswordAtLogon = $user.ChangePasswordAtLogon
                Enabled               = $true
                Ensure                = 'Present'
                Credential            = $DomainAdminCredential
                DependsOn             = "[ADOrganizationalUnit]OU_$($user.DependsOnOUKey)"
            }
        }

        #### POST=PROMOTION-GROUP MEMBERSHIP

        foreach ($user in $Node.ADUsers) {
            if ($user.GroupMembership) {

                foreach ($groupName in $user.GroupMembership) {
                    $grpEntry = $Node.SecurityGroups | 
                    Where-Object { $_.GroupName -eq $groupName }

                    if ($grpEntry) {
                        $currentUserName = $user.UserName
                        $currentGroupName = $groupName

                        Script "AddUserToGroup_$($user.key)_$($grpEntry.Key)" {
                            GetScript  = { return @{ Result = 'N/A' } }

                            TestScript = {
                                $members = Get-ADGroupMember -Identity $using:currentGroupName -ErrorAction SilentlyContinue
                                $members.SamAccountName -Contains $using:currentUserName
                            }

                            SetScript  = {
                                Add-ADGroupMember -Identity $using:currentGroupName -Members $using:currentUserName
                            }

                            DependsOn  = @(
                                "[ADUser]User_$($user.Key)"
                                "[ADGroup]Group_$($grpEntry.Key)"
                            )

                        }

                    }    

                }

            }

        }


        #### POST-PROMOTION PASSWORD POLICY

        ADDomainDefaultPasswordPolicy SetPasswordPolicy {
            DomainName                  = $Node.DomainName
            ComplexityEnabled           = $Node.PasswordPolicy.ComplexityEnabled
            MinPasswordLength           = $Node.PasswordPolicy.MinPasswordLength
            PasswordHistoryCount        = $Node.PasswordPolicy.PasswordHistoryCount
            MaxPasswordAge              = $Node.PasswordPolicy.MaxPasswordAge
            MinPasswordAge              = $Node.PasswordPolicy.MinPasswordAge
            LockoutThreshold            = $Node.PasswordPolicy.LockoutThreshold
            LockoutDuration             = $Node.PasswordPolicy.LockoutDuration
            LockoutObservationWindow    = $Node.PasswordPolicy.LockoutObservationWindow
            ReversibleEncryptionEnabled = $Node.PasswordPolicy.ReversibleEncryptionEnabled
            Credential                  = $DomainAdminCredential
            DependsOn                   = '[WaitForADDomain]WaitForBarmBuzz'
        }


        #### POST-PROMOTION-GROUP-POLICY

        WindowsFeature GPMC {
            Name      = 'GPMC'
            Ensure    = 'Present'
            DependsOn = '[WaitForADDomain]WaitForBarmBuzz'
        }


        # 1. Create GPO Objects
        foreach ($gpo in $Node.GroupPolicies) {
            GroupPolicy "GPO_$($gpo.key)" {
                Name      = $gpo.Name
                Ensure    = 'Present'
                DependsOn = '[WindowsFeature]GPMC'
            }
        }


        # 2. Link GPOs to OUs
        foreach ($link in $Node.GPOLinks) {

            $linkTarget = "$($link.TargetOUPath),$($Node.DomainDN)"

            GPLink "GPLink_$($link.Key)" {
                GPOName   = $link.GPOName
                Path      = $linkTarget
                Order         =$link.Order
                Enforced  = $link.Enforced
                Enabled   = $link.LinkEnabled
                Ensure    = 'Present'
                DependsOn = @(
                    "[GroupPolicy]GPO_$($link.DependsOnGPO)"
                    "[ADOrganizationalUnit]OU_$($link.DependsOnOUKey)"
                )
            }
        }


        # 3. Set GPO registry values
        foreach ($regval in $Node.GPORegistryValues) {

            GPRegistryValue "GPOReg_$($regval.Key)" {
                Name      = $regval.GPOName
                Key       = $regval.RegistryKey
                ValueName = $regval.ValueName
                Value     = $regval.ValueData
                ValueType = $regval.ValueType
                Ensure    = 'Present'
                DependsOn = "[GroupPolicy]GPO_$($regval.DependsOnGPO)"
            }
        }

        # 4. GPO Security filtering
        foreach ($perm in $Node.GPOPermissions) {
            GPPermission "GPOPerm_$($perm.Key)" {
                GPOName         = $perm.GPOName
                TargetName      = $perm.TargetName
                TargetType      = $perm.TargetType
                PermissionLevel = $perm.Permission
                Ensure          = 'Present'
                DependsOn       = "[GroupPolicy]GPO_$($perm.DependsOnGPO)"
            }
        }
    } 
}    

