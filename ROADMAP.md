# Domain Expansion: Roadmap v1

*Written 30 Sep 2026. Starting from nothing: no VMs, no repo, no tenant.*

---

## What this is for

A hybrid identity estate built at home, on a gaming PC, to close the gap
between my day job (hybrid AD/Entra administration, PowerShell) and what an
NYC finance **Identity Engineer** role actually asks for. The target is the
AD/Entra engineer spec that market keeps writing: multi-forest AD, DC
lifecycle, tiering, Kerberos and LDAPS, NTLM deprecation, AD disaster
recovery, Entra Connect and Cloud Sync, app registrations, Graph, Terraform.

Movie Knight already shows the governance half (JML, access reviews,
least-privilege service logins, audit, restore drills). **This lab is the
Microsoft half.** Between the two, every line of that spec has something
behind it.

**Target:** phases 1–8 done by February 2027. Phases 9–11 follow.

### How to read this file

Carried from Movie Knight, because it worked there:

- **Phases are sequence, not subject.** A number is a position in the order.
  Numbers are never reused; anything can jump the queue and take the number
  it lands on.
- **Nothing stays unnumbered.** A "maybe later" gets a number at the end.
- **State is quarantined.** Everything that goes stale lives in *Where things
  stand*, dated. Everything else is decisions and reasoning.

---

## Where things stand — 30 Sep 2026

*This section is expected to go stale.*

- Nothing built. Phase 0 is next.
- Host: Ryzen 5 7600X (6c/12t), 32 GB DDR5, RTX 4060 Ti. Also the gaming PC.
- Windows edition: **unknown**, and it decides decision 4. Check first.
- No Azure account, no Entra tenant. Movie Knight's Phase 12 is shelved
  waiting on the same sign-up (decision 7).

---

## Decisions in force

1. **The lab never touches work.** No employer credentials, tenant, scripts,
   screenshots or naming. Nothing written at work is copied here, and nothing
   here is run at work. The portfolio is only worth something if it is
   clearly mine and clearly clean.

2. **Build by hand once, then as code.** Each new thing (a forest, a trust, a
   sync) is done by hand first, with notes, so the clicks and the errors are
   understood. Then it is scripted, and the lab is rebuilt from the script.
   A script I could not have done by hand is a script I cannot explain in an
   interview.

3. **The repo is public from day one.** The opposite of Movie Knight's
   decision 23, for the same reason: here every user, password and domain is
   fake, so nothing real can ever get into the history. Secrets still never
   enter it (decision 5), because a public repo with a committed lab password
   reads as a habit, not a lab.

4. **Hyper-V if Windows is Pro, and Pro is worth buying if it is Home.**
   AutomatedLab (phase 2) needs Hyper-V, and so does every serious Windows lab
   guide. VirtualBox works for phase 1 alone. An upgrade to Pro is a one-time
   cost and cheaper than rebuilding phase 2 around a different tool.

5. **Secrets live outside the repo.** Lab passwords go in a local vault
   (`Microsoft.PowerShell.SecretManagement` + `SecretStore`), are read at run
   time, and are unique to the lab. `.gitignore` covers `*.pfx`, `*.key`,
   `secrets/`, `*.vhdx`, `*.iso` from the first commit. The only thing a
   script may contain is the *name* of a secret.

6. **Isolated network.** An internal Hyper-V switch with a NAT to the outside,
   one subnet per forest. Never an external or bridged switch. Lab DNS must
   never answer for the home network, and a rogue DHCP on the home LAN is
   the kind of mistake that takes the household's internet down.

7. **One Azure account, two Entra tenants.** `lab` is breakable: synced into,
   wiped, rebuilt. Movie Knight's app registration (its shelved Phase 12)
   gets a separate, stable tenant, because a lab reset must never break six
   people's login. Creating the second tenant costs nothing once the account
   exists. *This replaces the "one tenant for both" idea from 30 Sep.*

8. **Gaming wins.** No lab VM starts automatically (`AutomaticStartAction =
   Nothing`). VMs are saved before gaming. If a game's anti-cheat refuses to
   run with Hyper-V on, the hypervisor is toggled with
   `bcdedit /set hypervisorlaunchtype off|auto` and a reboot, and that is
   written down in `docs/host.md` rather than rediscovered.

9. **Trials start the day a phase needs them.** Entra ID P2 and any M365 trial
   are 30 days. Activating one early burns it on setup. Each is started on
   the first day of the phase that uses it, and the end date goes in *Where
   things stand*.

10. **Two forests on two versions.** Forest A on Windows Server 2025, forest B
    on Server 2022. Real estates are mixed, and B's older defaults give
    phase 5 something to find. Both are free 180-day evaluations; the build
    scripts make an expired eval a rebuild, not a loss.

11. **Every phase ends with proof, and proof is a grid.** A
    `tests/Test-PhaseN.ps1` that returns named true/false checks, all true to
    close the phase, the same idea as Movie Knight's migration grids. Plus at
    least one **break it on purpose** exercise: cause the failure, find it
    with the real tools, fix it, and write down what the symptoms looked like.

12. **Each phase's write-up is mine.** `docs/phase-N.md`: what I built, what
    broke, what the fix was, and the interview answer in my own words. Claude
    can build, script and review. It does not write these. They are the
    part an interviewer is actually testing.

---

## RAM budget

32 GB host, about 12 GB kept for Windows and a game that isn't running.

| VM | Role | OS | RAM | On when |
|---|---|---|---|---|
| DC01 | Forest A, first DC, PDC emulator | 2025 Core | 2 GB | phase 1 onward |
| DC02 | Forest A, second DC, second site | 2025 Core | 2 GB | phase 3 onward |
| CL01 | Admin workstation, RSAT | Win 11 Ent eval | 4 GB | phase 1 onward |
| CA01 | Enterprise CA (Tier 0) | 2025 Core | 2 GB | phase 5, then as needed |
| DC03 | Forest B, only DC | 2022 Core | 2 GB | phase 7 onward |
| SRV01 | Entra Connect Sync (needs Desktop Experience) | 2025 | 4 GB | phase 8 onward |

**Peak ≈ 16 GB** with everything on, which is rarely needed. Each phase says
what has to be running. The Cloud Sync agent goes on DC03 to save a VM,
which is a lab shortcut and is written down as one.

---

## Phase 0 — Host, repo, tenant

**What:** Check the Windows edition and decide decision 4. Turn on Hyper-V,
or install VirtualBox. Test the games you actually play with the hypervisor
on. Create the internal switch and NAT. Download the Server 2025, Server
2022 and Windows 11 Enterprise evaluation ISOs. Create the public repo
`domain-expansion` with this file, `.gitignore`, `README.md` and an empty
`tests/`. Set up SecretManagement. Create the Azure account, the `lab`
tenant and the Movie Knight tenant. In each tenant, make two **break-glass**
global admins that are excluded from everything later, with MFA on your own
admin account.

**Proof:** `Test-Phase0.ps1`: hypervisor present, switch internal, NAT
subnet correct, ≥150 GB free on the lab drive, vault unlocks, `.gitignore`
refuses a test `.pfx`. Tenant checks by hand, recorded: two break-glass
accounts per tenant, sign-in works.

**Unblocks:** Movie Knight Phase 12, which can resume against the stable
tenant.

## Phase 1 — The first forest, by hand

**What:** DC01 on Server Core, forest `corp.lab.internal` (`.internal` is
reserved for private use, so it can never collide with a real domain). DNS,
reverse zones, forwarders. CL01 joined, RSAT installed, and everything
managed from CL01, never from the DC's console. A starting OU design with
real structure, not the default `Users` container: `Tier0`, `Tier1`,
`Tier2`, `Staff`, `Groups`, `Service Accounts`, `Disabled`. About fifty fake
users from a CSV.

**Break it:** point CL01's DNS at 8.8.8.8 and watch the domain join and
logon fail. Explain why an AD client must use AD DNS.

**Proof:** `Test-Phase1.ps1`: forest and domain functional levels, DNS SRV
records present, CL01 domain-joined, OU tree matches the design, users
created.

**Interview answers:** "What does a DC actually need DNS for?" "Why Server
Core?"

## Phase 2 — The lab as code

**What:** Rebuild phase 1 from nothing with AutomatedLab for the VMs and my
own scripts for the configuration (OUs, users, groups) in `build/`. Delete
the hand-built lab first, which is the point.

**Proof:** a clean rebuild passes `Test-Phase1.ps1` unchanged. Time it.

**Interview answer:** "How would you stand up a test environment that matches
production?"

## Phase 3 — Replication, sites, DNS

**What:** DC02 in a second AD site (`Site-B`, its own subnet), site links and
costs, AD-integrated DNS replicating. FSMO roles: know where each lives and
move one. Learn `repadmin /replsummary`, `/showrepl`, `dcdiag`, and
`nltest /dsgetdc`.

**Break it:** (a) cut the network between sites and create objects on both
sides, then reconnect and watch convergence. (b) Change DC02's clock
by 10 minutes and watch Kerberos and replication fail. (c) Remove a DC's SRV
records and find it with `dcdiag /test:dns`.

**Proof:** `Test-Phase3.ps1`: zero replication failures, both DCs are GCs,
site coverage correct, time source hierarchy correct (PDC to external, the
rest to domain hierarchy).

**Interview answers:** "Replication is failing. Walk me through it." "What
happens if a DC's clock drifts?"

## Phase 4 — Tiering and Group Policy

**What:** The enterprise access model, in miniature. Separate admin accounts
per tier (`adm0-`, `adm1-`, `adm2-`). Tier 0 admins in **Protected Users**.
GPO "deny log on" rules so a Tier 0 credential can never touch a Tier 1 or
2 machine. **Windows LAPS** for local admin passwords. Kerberos
**authentication policies and silos** for Tier 0. A security baseline GPO
(Microsoft Security Compliance Toolkit) with a documented list of what was
relaxed and why. GPO modelling, `gpresult /h`, and loopback processing on
purpose once.

**Break it:** log on to CL01 with a Tier 0 account and prove it is refused,
and that the refusal is logged. Link a GPO in the wrong place and find it
with RSoP.

**Proof:** `Test-Phase4.ps1`: tier accounts exist and are in the right
groups, Protected Users populated, deny-logon settings applied at each tier,
LAPS password retrievable for CL01 only by the right group, silo enforced.

**Interview answers:** "Explain the tiering model and why it exists." "How
do you stop credential theft moving up a tier?" This is the phase that
answers "privileged access models" in the spec's preferred list.

## Phase 5 — Kerberos, LDAPS and NTLM deprecation

**The flagship phase.** The spec asks for someone who has *planned and
executed* an NTLM deprecation. This is where that story comes from.

**What:**
- **AD CS:** CA01 as an enterprise CA, a DC certificate template,
  auto-enrollment. **LDAPS** working on both DCs, proven with `ldp.exe` on
  636. Then LDAP signing and channel binding required, and find what breaks.
- **Kerberos:** SPNs (`setspn -Q`, duplicates), `klist`, ticket lifetimes,
  the three delegation types and why unconstrained is dangerous, a gMSA for a
  service. Enable Kerberos AES-only for Tier 0 and see what RC4 was hiding.
- **NTLM:** the real project shape. **Audit** (`Network security: Restrict
  NTLM: Audit…` policies, events 8001–8004 on the DCs), **inventory** what is
  still using it (something deliberately set up that way: an app hit by IP
  address, a missing SPN), **remediate** each one, **restrict** with an
  exception list, then **block** in forest A. Write it as a plan with phases
  and a rollback, as if presenting it to a change board.

**Break it:** access a share by IP and watch it fall back to NTLM. Break an
SPN and watch Kerberos fail over.

**Proof:** `Test-Phase5.ps1`: LDAPS answers on both DCs with a valid chain,
LDAP signing required, no duplicate SPNs, gMSA works, NTLM audit events
collected, and in forest A the NTLM block is on with an empty exception list.

**Interview answers:** "Walk me through an NTLM deprecation." "Kerberos works
on one server and not another. Why?" "Why LDAPS, and what's channel
binding?"

## Phase 6 — Backup and disaster recovery

The spec's "backup validation and periodic recovery testing" is Movie
Knight's restore drill, on AD.

**What:** AD Recycle Bin on. System-state backups of both DCs. Practise every
restore type: a deleted OU from the Recycle Bin, a
**non-authoritative** DC restore, an **authoritative** restore of an OU
(`ntdsutil`) and why that needs care, and DSRM. Then the big one: a
**forest recovery** drill following Microsoft's forest recovery guide,
written as a runbook. Seize FSMO roles from a "dead" DC and clean up its
metadata.

**Break it:** delete an OU full of users and a GPO, and bring them back.
Shut DC01 off permanently and recover the domain from DC02.

**Proof:** `Test-Phase6.ps1` after each drill: object counts match before
and after, replication healthy, FSMO holders as expected. The runbook in
`docs/`, with each drill's date and result.

**Interview answers:** "Authoritative vs non-authoritative?" "A DC's dead.
What do you do?" "How do you know your AD backups actually work?"

## Phase 7 — The second forest and the trust

**What:** DC03 on Server 2022, forest `partner.lab.internal`, its own
subnet. Conditional forwarders both ways. A **forest trust**, first two-way,
then made one-way with **selective authentication**. SID filtering and why
it stays on. Grant one partner group access to one resource in forest A,
and nothing else. Run phase 5's NTLM audit against forest B and find what
its older defaults allow.

**Break it:** break a conditional forwarder and watch the trust validation
fail. Try to reach a resource that selective authentication should refuse.

**Proof:** `Test-Phase7.ps1`: trust validates, selective auth on, SID
filtering on, the one allowed access works and a second one is refused.

**Interview answers:** "Multi-forest: when and why?" "What does selective
authentication actually do?"

## Phase 8 — Hybrid identity: Connect Sync and Cloud Sync

**What:** Into the `lab` tenant. **Entra Connect Sync** on SRV01 for forest
A: password hash sync, OU filtering, a UPN plan (lab users land on
`*.onmicrosoft.com` unless you buy a domain, and that decision goes in the
write-up). Then **Entra Cloud Sync** for forest B, agent on DC03: two sync
engines for two forests, which Microsoft supports and banks actually run.
Sync rules, the metaverse, `Start-ADSyncSyncCycle`, staging mode.

**Break it:** duplicate a `proxyAddresses` value across two users and read
the sync error. Soft-match and hard-match an existing cloud user. Delete a
synced user's source object and watch what Entra does. Stop the Cloud Sync
agent and find the alert.

**Proof:** `Test-Phase8.ps1` using Graph: expected users synced from each
forest, `onPremisesSyncEnabled` true, no provisioning errors, last sync
within the hour, and the filtered OU absent.

**Interview answers:** "Connect Sync or Cloud Sync, and when?" "Here's a sync
error. Fix it." "What's staging mode for?"

## Phase 9 — Entra administration: Conditional Access and PIM

**Start the Entra ID P2 trial on day one of this phase** (decision 9).

**What:** Conditional Access built in report-only first, then enforced: MFA
for admins, block legacy auth, require a compliant or joined device for one
app, sign-in risk policy. **Break-glass accounts excluded from every
policy**, and a test proving it. **PIM**: roles eligible, not permanent;
activation with justification and approval; an access review of an admin
group. Also: authentication methods policy, and named locations.

Conditional Access goes into public materials only once it has been built
here, by hand.

**Break it:** write a policy that would lock out every admin, leave it in
report-only, and read the What If tool and the sign-in logs to prove it would
have.

**Proof:** `Test-Phase9.ps1`: every CA policy excludes the break-glass group,
no permanent Global Admin besides break-glass, PIM eligible assignments
present, legacy auth blocked.

**Interview answers:** "How do you roll out Conditional Access without
locking people out?" "Standing access vs PIM?"

## Phase 10 — App registrations and Graph automation

**What:** Register an app with a **certificate** credential (from CA01's
PKI or a self-signed one, with the choice written up) and one with a
secret, and explain why the certificate wins. Delegated vs application
permissions, admin consent, least-privilege Graph scopes. A service
principal inventory. Then the scripts, in Graph PowerShell, as an app with
the smallest permissions that work:
- `Get-ExpiringCredentials.ps1`: every app secret and certificate expiring in
  the next 30/60/90 days.
- `Get-StaleAccounts.ps1`: users and guests with no sign-in for 90 days.
- `Get-PrivilegedRoleReport.ps1`: who holds which directory role, permanent
  or eligible.
Movie Knight's Phase 12 app goes in the *stable* tenant (decision 7) and is
cross-linked here as the real-world example, including the `xms_edov`
finding.

**Proof:** `Test-Phase10.ps1`: scripts run as the app, not as a user; the app
holds only the scopes listed in its README; no app in the tenant has a
secret older than its policy allows.

**Interview answers:** "Secret or certificate?" "What's admin consent and
when is it dangerous?" "How do you find credentials about to expire?"

## Phase 11 — Identity as code: Terraform

Last in the order on purpose: the learning plan is Python, then Git, then
Terraform.

**What:** The `azuread` provider managing groups, the phase 10 app
registrations and the CA policies from phase 9, with state stored outside
the repo. Drift detection: change a policy in the portal and have `plan`
report it.

**Proof:** `terraform plan` clean against the live tenant. A portal change
shows up as drift.

**Interview answer:** "How would you manage Entra config as code?" This is
the spec's preferred Terraform line.

## Phase 12 — Parked

- **Okta developer tenant** federated with the `lab` tenant, for the spec's
  "Okta or another IdP" line.
- **Authentik or Authelia** in front of home-lab services (the older parked
  idea).
- **A Tier 0 attack path review**: run BloodHound Community Edition against
  forest A before and after phase 4, and show the difference. A strong
  interview artifact, but it comes after the rest.

---

## Spec coverage

| Spec line | Phase |
|---|---|
| Multi-forest, multi-domain AD, sites, replication | 1, 3, 7 |
| Microsoft tiering model | 4 |
| DC patching, health, lifecycle | 3, 6 |
| NTLM deprecation, with Security Ops | 5 |
| AD-integrated DNS troubleshooting | 1, 3, 7 |
| Group Policy across domains | 4, 7 |
| AD DR: procedures, backup validation, recovery testing | 6 |
| Entra ID tenant administration, lifecycle controls | 8, 9 (+ Movie Knight JML) |
| Entra Connect Sync and Cloud Sync | 8 |
| App registrations, service principals, consent, certs, secrets | 10 (+ Movie Knight) |
| Graph API and Graph PowerShell automation | 8, 9, 10 |
| Kerberos and LDAPS | 5 |
| OAuth 2.0, OIDC, SAML | 10 (+ Movie Knight OAuth) |
| Documentation | every phase's write-up and runbook |
| *Preferred:* Terraform | 11 |
| *Preferred:* Okta | 12 |
| *Preferred:* privileged access models, security assessments | 4, 12 |

Not covered by a lab and not claimed: "5+ years in a multi-forest
environment". The lab turns that line from a gap into a conversation. It
doesn't turn it into experience, and the résumé shouldn't say it does.

## Certs alongside

- **AZ-104 (fall 2026):** phases 8–10 overlap its identity and governance
  domain.
- **SC-300 (spring 2027):** phases 8–10 *are* most of it. By then the exam
  is revision, not learning.
