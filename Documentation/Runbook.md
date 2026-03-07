# Runbook (Student)

Keep a dated log of:
- what you changed
- what you ran (commands)
- where the evidence is stored (paths)




# Runbook – BarmBuzz Project Log

| Date | What I Changed | What I Ran | Evidence Location |
|------|----------------|------------|-------------------|
| **Week 1** | Set up development environment, created GitHub repo, installed VSCode and Git | `winget install Microsoft.PowerShell`<br>`git clone https://github.com/af6crt/COM5411_PreDC-Promo.git` | `Evidence/Transcripts/week1_setup.txt` |
| **Week 2** | Created baseline DSC config – StudentConfig.ps1 and AllNodes.psd1 with basic settings (computer name, timezone, ADDS install) | `.\Run_BuildMain.ps1` | `Evidence/Transcripts/build_week2.txt`<br>`DSC/Outputs/localhost.mof` |
| **Week 3** | Added full OU structure (20+ OUs), security groups (AGDLP), users (Ava, Bob, Charlie), password policy | `.\Run_BuildMain.ps1` | `Evidence/AD/ous.txt`<br>`Evidence/AD/groups.txt`<br>`Evidence/AD/users.txt` |
| **Week 3** | Fixed GroupPolicyDsc module error – uninstalled old version 1.0.3, installed correct version 6.2.0 | `Uninstall-Module GroupPolicyDsc -AllVersions`<br>`Install-Module GroupPolicyDsc -RequiredVersion 6.2.0` | `Evidence/Transcripts/module_fix.txt` |
| **Week 4** | Added 4 GPOs with registry settings (workstation baseline, server baseline, POS lockdown, all users banner) | `.\Run_BuildMain.ps1` | `Evidence/GPOBackups/gpos.txt`<br>`Evidence/GPOBackups/gplinks.txt` |
| **Week 4** | Created Pester tests for domain, OUs, users, groups | `Invoke-Pester -Path .\Tests\Pester\` | `Tests/Pester/Domain.Tests.ps1`<br>`Evidence/Pester/test-results.xml` |
| **Week 4** | Added comments to StudentConfig.ps1 and AllNodes.psd1 to explain code | Edited files in VSCode | `DSC/Configurations/StudentConfig.ps1`<br>`DSC/Data/AllNodes.psd1` |
| **Week 5** | Tested on fresh server – installed PowerShell 7, DSC, Git, VSCode, all required modules with correct versions | `winget install Microsoft.PowerShell`<br>`Save-PSResource -Name ActiveDirectoryDsc -Version 6.6.0`<br>`Save-PSResource -Name GroupPolicyDsc -Version 6.2.0` | `Evidence/Transcripts/fresh_server.txt` |
| **Week 5** | Final validation – verified domain, OUs, users, groups, GPOs all exist | `Get-ADDomain`<br>`Get-ADOrganizationalUnit -Filter *`<br>`Get-ADUser -Filter *`<br>`Get-GPO -All` | `Evidence/AD/domain.txt`<br>`Evidence/AD/ous.txt`<br>`Evidence/AD/users.txt`<br>`Evidence/GPOBackups/gpos.txt` |

---

## Summary
- **Fixed module versions:** Upgraded GroupPolicyDsc from 1.0.3 to 6.2.0
- **Added comments:** Explained code in StudentConfig.ps1 and AllNodes.psd1
- **Correct installations:** Used specific versions (ActiveDirectoryDsc 6.6.0, GroupPolicyDsc 6.2.0)
- **Evidence saved in:** `Evidence/` folder

---

