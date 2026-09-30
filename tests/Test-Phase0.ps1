#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Phase 0 proof: the host, the network and the repo are ready for a lab.

.DESCRIPTION
    Returns one named true/false check per row. Every row must be true to
    close Phase 0 (decision 11). A check that throws counts as false and
    carries the error in its Detail, so one missing piece (no Hyper-V module
    on Windows Home, say) never hides the rest of the grid.

    Tenant checks (break-glass accounts, sign-in) are done by hand and
    recorded, as the roadmap says. They are not in this script.

.PARAMETER SwitchName
    The internal Hyper-V switch the lab uses.

.PARAMETER NatName
    The WinNAT network in front of that switch.

.PARAMETER NatPrefix
    The subnet the NAT serves, in CIDR form. The host's vEthernet adapter
    on the lab switch holds the first address in it, as the gateway.

.PARAMETER LabPath
    Where the VM disks live. Defaults to Hyper-V's own virtual hard disk
    path, so the free-space check measures the drive the VMs will fill.

.PARAMETER VaultName
    The SecretManagement vault that holds the lab passwords (decision 5).

.PARAMETER MinFreeGB
    Free space the lab drive needs.

.EXAMPLE
    .\tests\Test-Phase0.ps1 | Format-Table -AutoSize
#>
[CmdletBinding()]
param(
    [string]$SwitchName = 'LabSwitch',
    [string]$NatName    = 'LabNat',
    [string]$NatPrefix  = '10.50.0.0/24',
    [string]$LabPath,
    [string]$VaultName  = 'LabVault',
    [int]$MinFreeGB     = 150
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot

# --- helpers ---------------------------------------------------------------

function ConvertTo-IPv4Range {
    # '10.50.0.0/24' -> first and last address as integers.
    param([string]$Address, [int]$PrefixLength)
    $bytes = ([ipaddress]$Address).GetAddressBytes()
    [array]::Reverse($bytes)
    $ip    = [uint64][BitConverter]::ToUInt32($bytes, 0)
    $size  = [uint64]1 -shl (32 - $PrefixLength)
    $first = $ip - ($ip % $size)
    [pscustomobject]@{ First = $first; Last = $first + $size - 1 }
}

function Test-RangeOverlap {
    param($A, $B)
    ($A.First -le $B.Last) -and ($B.First -le $A.Last)
}

function Invoke-Check {
    # $Test returns @($pass, $detail).
    param([string]$Name, [scriptblock]$Test)
    try {
        $pass, $detail = & $Test
        [pscustomobject]@{ Check = $Name; Pass = [bool]$pass; Detail = "$detail" }
    }
    catch {
        [pscustomobject]@{ Check = $Name; Pass = $false; Detail = "Error: $($_.Exception.Message)" }
    }
}

$natAddress, $natLength = $NatPrefix -split '/'
$natRange  = ConvertTo-IPv4Range $natAddress ([int]$natLength)
$gwBytes   = [BitConverter]::GetBytes([uint32]($natRange.First + 1))
[array]::Reverse($gwBytes)
$gatewayIP = ([ipaddress]$gwBytes).IPAddressToString

# --- the grid --------------------------------------------------------------

$results = @(

    # Decision 4. Also proves SVM is on in the BIOS: no SVM, no hypervisor.
    Invoke-Check 'HypervisorPresent' {
        $present = (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
        $present, "HypervisorPresent = $present"
    }

    # Decision 6: internal, never external or private.
    Invoke-Check 'LabSwitchIsInternal' {
        $sw = Get-VMSwitch -Name $SwitchName
        ($sw.SwitchType -eq 'Internal'), "$SwitchName is $($sw.SwitchType)"
    }

    # Decision 6: no bridged switch anywhere on the host, lab or not.
    Invoke-Check 'NoExternalSwitch' {
        $ext = @(Get-VMSwitch | Where-Object SwitchType -eq 'External')
        ($ext.Count -eq 0), ("External switches: " + $(if ($ext) { $ext.Name -join ', ' } else { 'none' }))
    }

    Invoke-Check 'NatSubnetCorrect' {
        $nat = Get-NetNat -Name $NatName
        ($nat.InternalIPInterfaceAddressPrefix -eq $NatPrefix), "$NatName serves $($nat.InternalIPInterfaceAddressPrefix)"
    }

    Invoke-Check 'GatewayOnLabSwitch' {
        $ip = Get-NetIPAddress -InterfaceAlias "vEthernet ($SwitchName)" -AddressFamily IPv4
        $ok = @($ip | Where-Object { $_.IPAddress -eq $gatewayIP -and $_.PrefixLength -eq [int]$natLength }).Count -eq 1
        $ok, "vEthernet ($SwitchName) has $(@($ip | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ', '); expected $gatewayIP/$natLength"
    }

    # Decision 6: the lab subnet must never collide with the home LAN or any
    # other network the host is on (Default Switch included).
    Invoke-Check 'NatSubnetClearOfHostNetworks' {
        $clash = @(Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {
                $_.InterfaceAlias -ne "vEthernet ($SwitchName)" -and
                $_.IPAddress -notlike '127.*' -and
                $_.IPAddress -notlike '169.254.*'
            } |
            Where-Object { Test-RangeOverlap $natRange (ConvertTo-IPv4Range $_.IPAddress $_.PrefixLength) } |
            ForEach-Object { "$($_.InterfaceAlias) $($_.IPAddress)/$($_.PrefixLength)" })
        ($clash.Count -eq 0), ("Overlaps: " + $(if ($clash) { $clash -join '; ' } else { 'none' }))
    }

    Invoke-Check "LabDriveHas${MinFreeGB}GBFree" {
        $path = $LabPath
        if (-not $path) { $path = (Get-VMHost).VirtualHardDiskPath }
        $drive = [System.IO.DriveInfo]::new((Split-Path -Qualifier $path))
        $freeGB = [math]::Round($drive.AvailableFreeSpace / 1GB)
        ($freeGB -ge $MinFreeGB), "$($drive.Name) has $freeGB GB free ($path)"
    }

    # Decision 8: nothing starts with the host.
    Invoke-Check 'NoVmAutoStarts' {
        $auto = @(Get-VM | Where-Object AutomaticStartAction -ne 'Nothing')
        ($auto.Count -eq 0), ("Auto-start VMs: " + $(if ($auto) { $auto.Name -join ', ' } else { 'none' }))
    }

    # Decision 5.
    Invoke-Check 'VaultRegistered' {
        $v = Get-SecretVault -Name $VaultName
        ($v.ModuleName -eq 'Microsoft.PowerShell.SecretStore'), "$VaultName uses $($v.ModuleName)"
    }

    Invoke-Check 'VaultNeedsPassword' {
        $auth = (Get-SecretStoreConfiguration).Authentication
        ($auth -eq 'Password'), "SecretStore authentication = $auth"
    }

    # Prompts for the vault password if the store is locked.
    Invoke-Check 'VaultUnlocks' {
        $ok = Test-SecretVault -Name $VaultName
        $ok, "Test-SecretVault $VaultName = $ok"
    }

    # Decision 5: .gitignore refuses key material, disks and state. The
    # files need not exist; --no-index checks the rules, not the index.
    foreach ($sample in 'test.pfx', 'build/lab.key', 'secrets/lab.txt',
                        'disks/DC01.vhdx', 'iso/server2025.iso', 'terraform/terraform.tfstate') {
        Invoke-Check "GitIgnoreRefuses $sample" {
            $rule = git -C $repoRoot check-ignore --no-index -v -- $sample
            ($LASTEXITCODE -eq 0), $(if ($rule) { "$rule" } else { 'not ignored' })
        }
    }

    # A rule added after a file was committed does not remove the file.
    Invoke-Check 'NoTrackedFileIsIgnored' {
        $tracked = @(git -C $repoRoot ls-files --cached --ignored --exclude-standard)
        if ($LASTEXITCODE -ne 0) { throw "git ls-files exited $LASTEXITCODE" }
        ($tracked.Count -eq 0), ("Tracked but ignored: " + $(if ($tracked) { $tracked -join ', ' } else { 'none' }))
    }
)

$results

$passed = @($results | Where-Object Pass).Count
Write-Host ("`nPhase 0: {0}/{1} checks pass." -f $passed, $results.Count) -ForegroundColor $(if ($passed -eq $results.Count) { 'Green' } else { 'Red' })
