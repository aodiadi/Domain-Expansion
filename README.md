# Domain Expansion

A two-forest hybrid Active Directory and Entra ID estate, built at home on a
single Hyper-V host: first by hand, then as code.

- **Forest A**, `corp.lab.internal`: Windows Server 2025, two sites,
  tiered administration, AD CS, LDAPS, Kerberos hardening and an NTLM
  deprecation carried through from audit to block.
- **Forest B**, `partner.lab.internal`: Windows Server 2022, joined by a
  one-way forest trust with selective authentication.
- **Entra ID**: Connect Sync for forest A, Cloud Sync for forest B,
  Conditional Access, PIM, app registrations, Graph automation and
  Terraform.

Every phase closes with a proof script in `tests/` that returns named
true/false checks, and at least one failure caused on purpose, diagnosed and
fixed. The plan and the reasoning behind it are in [ROADMAP.md](ROADMAP.md).

Every user, password and domain here is fake. No secrets are stored in the
repo; scripts read them from a local SecretManagement vault at run time.
