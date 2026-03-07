# Design Notes (Student)

COM5411_BarmBuzz

├── README.md                       # This file
├── Run_BuildMain.ps1                # The main script (tutor gave us this)
├── DSC/
│   ├── Configurations/
│   │   └── StudentConfig.ps1        # My DSC code – what to build
│   ├── Data/
│   │   └── AllNodes.psd1             # My data – values for the build
│   └── Outputs/                       # MOF files (proof it compiled)
├── Evidence/                          # Everything that proves it worked
│   ├── Transcripts/                    # PowerShell logs
│   ├── AD/                              # AD object exports
│   ├── GPOBackups/                      # GPO info
│   ├── Network/                          # IP config
│   └── AI_LOG/                          # AI disclosure (had to include this)
├── Documentation/
│   ├── DesignNotes.md                   # My original plan
│   └── README.docx                       # Same thing for Turnitin
└── Scripts/                              # Tutor's helper scripts
    ├── Prereqs/
    └── Helpers


│AD Structure Design
├── OU=BarmBuzz (Enterprise Root)
│   │
│   ├── OU=Tier0 (Domain Control Plane)
│   │   ├── OU=Admins
│   │   ├── OU=Servers
│   │   └── OU=ServiceAccounts
│   │
│   ├── OU=Sites
│   │   └── OU=Bolton (HQ – Silicon Croal Valley)
│   │       ├── OU=Users
│   │       └── OU=Computers
│   │           ├── OU=Workstations
│   │           ├── OU=POS
│   │           └── OU=Kiosks
│   │
│   ├── OU=Groups
│   │   ├── OU=Role (Global Groups – AGDLP G Layer)
│   │   └── OU=Resource (Domain Local Groups – AGDLP DL Layer)
│   │
│   └── OU=Clients (Domain-Joined Endpoints)
│       ├── OU=Windows
│       └── OU=Linux


# Design Notes short explanined 

## OU Structure Rationale
I designed the OU structure to follow a tiered security model and keep things organised. 

**Tier0** is for high-privilege objects only – admins, servers, service accounts. This isolates critical assets so regular users can't access them. Microsoft recommends this for security.

**Sites** with Bolton underneath keeps location-based stuff together. Bolton is the only site right now but company might expand later. Users and Computers split makes GPO targeting cleaner.

**Workstations, POS, Kiosks** are separate because they need different policies. POS machines get locked down, workstations get security baselines, kiosks might need something else later.

**Groups** split into Role and Resource – this sets up AGDLP properly. Role for global groups, Resource for domain local.

**Clients** split Windows/Linux because they need completely different policies. Can't apply Windows settings to Linux machines.

## Group Model Rationale
I used AGDLP because it's Microsoft best practice and makes permission management so much easier.

Accounts go into Global groups based on their job. Global groups go into Domain Local groups. Permissions go on Domain Local groups only.

If someone changes jobs, I just move them to a different Global group. If a resource's access needs change, I update the Domain Local group. No one ever gets direct permissions so auditing is straightforward.

## GPO Linking Choices
Workstations Baseline links to Workstations OU – security settings for staff PCs.

Servers Baseline links to Servers OU – hardening for all servers.

POS Lockdown links to POS OU – restrict USB, add legal banner.

All Users Banner links to root BarmBuzz OU – legal notice for everyone.

Linking to specific OUs means policies only apply where needed. Workstations get different settings than servers. POS terminals get stricter controls.

## Security Controls Applied
ProtectedFromAccidentalDeletion on all OUs – stops someone accidentally deleting whole OUs. Saved me during testing.

Separate Admin OU – can apply stricter policies to admin accounts.

Tier 0 isolation – critical assets separate from everything else.

AGDLP model – no direct permissions ever. Makes auditing easier.

Password policy at domain level – 10 char minimum, 90 day expiry, lockout after 5 tries. Stops weak passwords and brute force.

GPO filtering by security group – policies only apply to intended users/computers.