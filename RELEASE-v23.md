# Удам бичиг v23

## Implemented
- A calm green desktop sidebar and mobile bottom navigation with a More sheet. No third-party logos, private data, code or illustrations were copied.
- Readable family-first graph at normal scale, expandable neighboring branches, ancestor-only scope, vertical/horizontal layouts. All-tree mode retains every record and edge; no extreme fit-to-width shrink. Selected-person centering; no faded-away relatives.
- Clan names stay stored but are hidden in ordinary cards, graph and selection results. Old unstructured names get a visible split proposal that requires manual application and normal Save.
- Different given names are never automatic duplicate candidates. Existing-record edits do not run identity matching. Search-first old-record selection limits results; merging uses a single comparison form with field choices and explicit consent.
- Optional male/female/unknown gender, no inference. Optional biography and dated life events, stored within the owner's existing family record JSON. No schema change; existing server scope deliberately excludes these new private details.
- A timeline/history tab, statistics with missing-data counts, and an owner-only print/PDF report via the browser's print dialog.
- Install control is in normal page flow. Update notices are dismissible and never force a reload during editing.

## Reference research
- https://www.urgiinbichig.mn/Software : interactive cards, biography/timeline, statistics and print report ideas.
- https://www.udam.mn/ : ancestor navigation and alternate tree directions, private family history organization.
- https://urgiin-mod.mn/ : public page was a JavaScript shell; detailed capabilities could not be verified. No feature claims or copied data from that site.

## Validation
Graph/merge/date tests and DOM regressions cover name mismatch (Амарсайхан vs Жаргалсайхан), editing without a duplicate popup, gender/biography persistence and AI local-name rendering. Browser QA uses fictional data in a separate local preview and checks family, ancestor and horizontal views plus statistics. No real family records were merged or modified by QA.

## Remaining configuration
SMS provider credentials are still absent. Existing email confirmation and BAZE secret are preserved. E-Mongolia is not used.
