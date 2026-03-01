@{
    AllNodes = @(
        @{
            NodeName        = 'localhost'
            Role            = 'DC'
            DomainName      = 'barmbuzz.local'

            ComputerName    = 'BB-DC01'
            TimeZone        = 'GMT Standard Time'

            InstallADDSRole = $true
            InstallRSATADDS = $true
            EnsureW32Time   = $true
        }
    )
}