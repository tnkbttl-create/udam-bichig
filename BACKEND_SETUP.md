# Current status: v22

BAZE_API_KEY is stored in Supabase Secrets; an actual BAZE response was shown by the owner. Never put this key in the static app or repository.

security-sharing-v22.sql is applied after the v20 schema. backend-verify-v22.sql passed with all synthetic users rolled back.

See RELEASE-v22.md for current features and remaining SMS/SMTP provider setup. Email confirmation is enabled. E-Mongolia is not used.

## Earlier setup reference

# Udam Bichig v20: remaining backend work

Frontend: GitHub Pages, main branch / root. Supabase project remains hadrcmqgezevqwyrxpqt; no data migration to an unrelated project.

## Current blockers

Supabase connector cannot access this project. Dashboard login requires a user CAPTCHA. Schema and policies are now present. Browser SQL regression checks passed for pending registration, cross-account isolation, unapproved access denial, self approval denial, immutable request participants, target-only acceptance, revocation, and service-only AI quota. All test users and data were rolled back. Auth SMS settings, provider credentials and BAZE secrets still need verification. This is not a guarantee against every possible security issue.

BAZE key in the supplied screenshot is masked. No usable key has been received and no BAZE model call has been made. The lineage-ai-review Edge Function has been deployed. It validates the key against the live model catalog; BAZE_MODEL is optional when a supported standard model is returned. This ChatGPT Work session has not changed its underlying model provider. CLI configuration in the provider's setup prompt applies to a separate Codex CLI harness, not to this running session.

## Before enabling backend features

1. Run backend-audit.sql read-only and inspect the actual schema, policies, triggers, data API privileges and advisors. Preserve existing family_records and approval records. Backup before schema changes.
2. Verify the admin's confirmed Auth UID. Store admin authorization in a server-owned table or app_metadata. An email check in browser code is UI only, never authorization.
3. Enforce user_approvals at the database and Edge Function boundary: unapproved users cannot read/write family_records or send lineage requests. Users cannot approve themselves. Email must be verified; approval default false. Registration trigger creates pending approval once per Auth UID. Only a verified admin can change approval. Existing approval choices remain unchanged.
4. Create lineage_profiles and lineage_requests with UUID foreign keys, unique request pairs, no self requests and RLS. Profiles private by default; discovery is explicit opt-in. Only requester/recipient see a request. Only recipient can accept/reject a pending request; immutable participants, constrained transitions. Accepted sharing can be revoked. Never grant all authenticated users access to all trees.
5. Implement find_lineage_contact(contact) as a verified, approved-user RPC. Exact email or E.164 phone match only, target opt-in and contact verification required. Rate limit to prevent enumeration. Return only user_id and chosen display name, never the directory of phone/email contacts.
6. Implement get_connected_lineage(peer_id) for accepted peers: only a minimal 5-generation ancestor projection; never the peer's notes, phone/email, auth IDs or complete private family_records. Modify frontend showKinshipReport to use this RPC before enabling peer sharing. Existing family_records select must remain owner/admin restricted.
7. Configure email confirmation, redirect URL https://tnkbttl-create.github.io/udam-bichig/ and production SMTP. Configure a paid SMS provider for phone-change OTP. Frontend attaches a phone to the existing email account with updateUser + verifyOtp(type=phone_change); it does not create a separate phone account. SMS is not operational until provider setup and a real OTP test succeed.
8. Install an atomic consume_lineage_ai_budget(subject_id) quota (e.g. 10/hour). Restrict EXECUTE to service_role; its usage table has RLS and no browser grants. Deploy lineage-ai-review.ts. Add BAZE_API_KEY and BAZE_MODEL only to Edge Function Secrets. Verify the key via https://api.baze.co/v1/gateway/models/ and choose an actually returned OpenAI-compatible model. Never put a BAZE key in a file, GitHub, browser JS or chat logs. CORS alone is not authorization.
9. Test with separate admin, approved and unapproved accounts; unauthenticated REST requests; cross-account reads/writes; self approval attempts; malformed participant changes; request acceptance/revocation; quota; SMS and email confirmation. Run security advisors again.

## E-Mongolia feasibility only

Official DAN documentation supports private/public service integrations, using OAuth2 and organizational onboarding (including KХУР requirements). This is not an unrestricted website lookup. No E-Mongolia login, identity lookup or integration is enabled here. Identity verification does not by itself prove a family relationship. See https://developer.sso.gov.mn/docs/intro/ and its organizational connection instructions.

## Validation already done

Pure graph tests: safe duplicate merge rewrites every ID reference; conflicting years and parent/child merging rejected; co-parents never automatically become spouses; repeated ancestors retain every graph edge; cycles detected; all people render without a mandatory ego.
DOM tests: script starts; all-records view; editing scheme; compact tree; review panel; complete add-child form; repeated duplicate submission preserves a single record and parent links.
