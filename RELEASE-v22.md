# Удам бичиг v22

- One tree menu with editable nodes, compact cards, zoom, fit, ego navigation and focused relationship lines. Couples share generation level; parents order descendants.
- Required human old/new identity selection on additions, including linked children/spouse. Name components remain separate; no guessing structured parts from free text. Explicit comparison and reversible duplicate merge. Existing people are never bulk merged.
- Optional birth year/month/day; partial dates remain partial, Gregorian calendar validated.
- Tree owner and shared source are distinct. Cross-account comparison preserves source and requires a choice for each differing field. Parent references are never silently imported from another tree.
- AI responses render readable sections; pseudonyms map to local name buttons. BAZE receives only pseudonymous graph/year, never names, photos or contacts.
- Server sharing requires mutually accepted request, two relationship statements, admin review, and owner-selected person scope. Date sharing is optional. Reattestation relocks sharing. Revocation denies access immediately. Plain mutual assertions are not state or genetic proof.
- Shared records omit photos, notes, contacts and source-specific relation labels. Suggestions go to the record owner; no remote edit privilege.
- RPCs require verified/approved identity, fixed search paths and explicit grants. New private tables have RLS and no browser grants. Audit events record review/scope changes.
- Family snapshots are session-only, previous persistent cache is removed after cloud load; logout clears private panels and undo data. Static CSP pins inline script by hash and limits network destinations.
- E-Mongolia is not used.

Validation: npm test (graph/date/merge and DOM identity/AI regressions); backend-verify-v22.sql (transaction rolled back after synthetic-user tests). No user's family records were changed by these tests.

Remaining provider setup: production SMS needs an SMS provider account/credentials and balance. Email confirmation is enabled; production email delivery may require custom SMTP. No paid provider or subscription was created.
