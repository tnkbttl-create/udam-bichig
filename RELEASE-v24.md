# v24 — Family junctions and genealogy guide

- Explicit two-parent families share one central connector and sibling bus, vertical and horizontal. Single-parent records are not expanded by inference.
- Collapsible child branches and simplified mobile toolbar, five-column mobile navigation.
- New Guide: benefits, first steps, kinship vocabulary, source checking and privacy. Available offline with app shell.
- Gemini guide client sends only one allowlisted topic code, never family records. New lineage-guide Edge Function requires confirmed email and administrator approval, consumes the existing service-only quota and selects a verified Gemini catalog entry. No GPT fallback and no frontend secrets.

Validation: npm test (core and DOM integration). Server deployment and real Gemini response must be verified independently; the source file alone does not activate Gemini.

Deployment: install lineage-guide.ts as lineage-guide in project hadrcmqgezevqwyrxpqt. Reuse server BAZE_API_KEY and existing quota RPC. Optional BAZE_GEMINI_MODEL must be an exact Gemini model identifier returned by the BAZE catalog. Do not use an API key in GitHub Pages.
