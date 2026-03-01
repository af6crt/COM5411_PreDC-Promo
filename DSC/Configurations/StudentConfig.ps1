<#
STUDENT TASK:
- Define Configuration StudentBaseline
- Use ConfigurationData (AllNodes.psd1)
- DO NOT hardcode passwords here.
#>

Configuration StudentBaseline {

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDSC

    Node $AllNodes.NodeName {

        Computer SetName {
            Name = $Node.ComputerName
        }

        TimeZone SetTimeZone {
            IsSingleInstance = 'Yes'
            TimeZone = $Node.TimeZone
        }

        Service WindowsTime {
            Name = 'W32Time'
            State = 'Running'
            StartupType = 'Automatic'
            DependsOn = '[TimeZone]SetTimeZone'
        }

        WindowsFeature ADDS {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature RSAT {
            Name      = 'RSAT-AD-Tools'
            Ensure    = 'Present'
            DependsOn = '[WindowsFeature]ADDS'
        }
    }
}