# Company MacBook setup SOP

Version 0.1, September 2026. Normal order assumes a new or already erased company-owned MacBook. The first deployment adds a personal-data and Activation Lock handoff before step 4 because the machine was previously the owner's.

## Roles and records

The client owns the MacBook, domain, primary Workspace admin, vendor accounts, billing, and recovery methods. TreeShop receives a named operator identity and the least access needed for the purchased package. Record account ownership, admin roles, recovery owner, device serial, and subscription payer in the [access register](06-access-register-template.md). Put passwords and recovery codes in the approved password manager, never in the register or repository.

`devtech@<company-domain>` is the proposed operator mailbox. It can be used as the email address for an Apple Account and for vendor sign-in where supported. A matching email address does **not** make Apple sign-in use Google authentication. True Google-to-Apple federation requires Apple Business setup and domain configuration. Choose that deliberately; a standalone company-controlled Apple Account is simpler for the first installation.

## Setup sequence

1. **Approve ownership and budget.** Record the owner, serial, purchase receipt or transfer, monthly software budget, and who can authorize new subscriptions.
2. **Establish domain and Google Workspace.** Confirm the client controls registrar, DNS, and Workspace billing. Create the named operator user and a separate owner recovery/admin path. Turn on strong sign-in protection and test account recovery. Keep a break-glass admin under client control.
3. **Inventory required vendor access.** Invite the operator to existing accounts where possible. Create new accounts only where a service does not exist. Prefer each vendor's own named-user permissions and “Sign in with Google” when offered; do not assume one SSO method works everywhere.
4. **Prepare the Mac.** For a previously used device, the owner confirms personal backups, signs out of personal services as required, and verifies that the erase will not strand personal data. Use macOS **Erase All Content and Settings** on eligible hardware, with the owner present for Apple Account prompts. Verify the old account no longer blocks activation.
5. **Create the company user.** Give the workstation a company-specific name, sign in with the selected company Apple Account, enable FileVault, set a strong local password, complete system updates, and test the owner's recovery route. Record installed macOS version and device serial.
6. **Configure work tools.** Install the approved password manager, browser, Jobber access, Claude Code, Git, website tools actually in use, and Buckets. Sign into Anthropic's company-provided Max subscription. Add ChatGPT/Codex only if separately purchased and assigned; the relevant OpenAI subscription name is **ChatGPT Pro**, with 5× and 20× usage tiers, or a business workspace. Subscription access is distinct from paid API use.
7. **Install Buckets.** Confirm the Mac meets the app's macOS requirement. Install a versioned release, open it through the documented macOS security flow, and record version/date. Its data lives in `~/Library/Application Support/Buckets/`; company documents live beside the store. Keep an independent export and a backup of the store plus documents.
8. **Connect vendors.** Jobber access should be a named user with the needed role. A future API connection requires a Jobber developer app and the account admin's OAuth approval; the Jobber login alone is not an API connection. Invite the operator to the actual website host, registrar/DNS, Google and Meta properties, Canva, and source repository as needed.
9. **Verify operation.** Send and receive a test email; open Jobber; open the website repo or CMS; price one test job in Buckets; export and restore a test copy; verify backups can be read. Record failures and their owners.
10. **Handoff.** Give the owner the device and access inventory, current subscription list, recovery path, Buckets version, backup location, and open issues. TreeShop retains the machine for remote operation under the client agreement.

## Standard account order

Domain/DNS ownership → Google Workspace owner admin → named operator mailbox → password manager and recovery → Apple Account/device → Jobber and developer access → repository/hosting/website → analytics and marketing → AI subscriptions → Buckets data and backups.

Existing accounts may require invitations and permission changes rather than new signups. Avoid creating duplicate Google Ads, Business Profile, Jobber, or website properties merely to fit the sequence.

## Routine maintenance and exit

Each month, check OS updates, device encryption, backup freshness, account access, subscriptions, and Buckets release status. At exit, export Buckets JSON and copy its Documents folder, hand over website source and documentation, list all vendor accounts, revoke TreeShop roles and tokens, rotate shared secrets if any existed, and verify the client can continue without the TreeShop workstation. The MacBook remains client property.

## Source notes

- Apple: [Erase a Mac](https://support.apple.com/en-md/guide/mac-help/-mchl7676b710/mac) and [Google Workspace federation in Apple Business](https://support.apple.com/en-ca/guide/business/axmaef1a0154/web).
- Jobber: [developer setup](https://developer.getjobber.com/docs/getting_started/) and [OAuth authorization](https://developer.getjobber.com/docs/building_your_app/app_authorization/).
- OpenAI Docs: [current ChatGPT/Codex plan names](https://learn.chatgpt.com/docs/pricing).
