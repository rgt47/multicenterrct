# Remediation Log: 2026-08-16 Referee Review

*2026-08-16 16:18 PDT*

This log records remediation of
`docs/pub_review_whitepaper_2026-08-16.md`. It does not edit the
whitepaper itself, per the review series' standing instructions.

## 1. Fixed

- **M1 (major, correctness item 1).** The ADEMP self-audit
  appendix's "Still open" bullet falsely claimed the random-slopes
  model had not been implemented, contradicting the Results, Future
  Research, and abstract sections. Fixed in
  `analysis/report/report.Rmd` (the "Morris et al. (2019) ADEMP
  Compliance" section): moved the implementation fact to "Resolved
  since the original 2026-04-17 audit" (new bullet describing Method
  4, `fit_methods()`, and Table 3), and rewrote "Still open" to state
  only the residual scope that is genuinely still open (null-arm
  coverage and the full $K$/$\sigma^2_\alpha$/balance factorial grid
  not yet extended to the random-slopes method), matching Future
  Research item 1 and the Discussion's Limitations paragraph.
  `[verified]` -- re-read the edited section in place; content is
  now internally consistent with Results/Table 3/abstract, and the
  document re-rendered successfully with `tools/render.sh` (see
  Section 1 below, render check).

- **m1 (minor, acceptance item 2). Figure 2 caption falsely claimed a
  dashed reference line for "the nominal 5% significance level" in
  the power panel.** Confirmed by reading the `fig-power` chunk
  (`analysis/report/report.Rmd`): only the coverage panel (`p2`) has
  a `geom_hline()` call; the power panel (`p1`) has none. Fixed the
  `fig.cap` string to read "Dashed line indicates the 95% coverage
  target (right panel)," removing the false claim rather than
  inventing a power-panel reference line the whitepaper itself notes
  has no obviously correct value. `[verified]` -- confirmed by
  reading the chunk code directly; no `geom_hline()` exists for `p1`
  anywhere in the file.

- **Item 8 (desirable polish, figure/code cross-check).** Audited
  Figures 1 (`fig-bias`) and 3 (`fig-imbalance`) captions against
  their generating ggplot code, the same check that surfaced the
  Figure 2 defect. Figure 1's "dashed line at zero" claim matches a
  `geom_hline(yintercept = 0, ...)` call present in the chunk.
  Figure 3's "empirical standard error (left) and power (right)"
  claim matches `p3` (built from `emp_se`) plotted first and `p4`
  (built from `power`) plotted second in `grid.arrange(p3, p4, ncol =
  2)`. No defects found; no edits needed. `[verified]`.

- **Render check.** Rendered the manuscript via
  `bash tools/render.sh analysis/report/report.Rmd` after the above
  edits. Render completed successfully (`Output created: report.pdf`;
  staged to `share/report-2026-08-16-1617-b98bca6-wip.pdf`) with no
  new errors, confirming the two prose edits did not break the
  document. `[verified]`.

- **Test suite.** Re-ran the existing test suite via
  `pkgload::load_all("."); tinytest::run_test_dir("inst/tinytest")`.
  17/17 tests pass, matching the count the whitepaper's Revision
  History reports for the 2026-08-16 review. No test changes were
  required by this remediation pass (the fixes were prose-only; no
  simulation code was touched). `[verified]`.

## 2. Deferred

- **Item 3 (acceptance, b): extend the null-hypothesis arm to the
  random-slopes method across the six treatment-by-site-interaction
  scenarios, and extend the random-slopes comparison to the full
  $K$/$\sigma^2_\alpha$/balance factorial grid.** Deferred: this
  requires adding new scenario rows to the simulation's scenario
  table and rerunning the full simulation ($R = 1{,}500$ replicates
  per new scenario, 4 methods per replicate), which exceeds the
  few-minutes wall-clock budget for this remediation pass and would
  also require the author to decide the exact new scenario grid
  (which $K$/$\sigma^2_\alpha$/balance combinations to add). This
  item has already been correctly and honestly disclosed as an open
  limitation in three places (Discussion "Limitations," Future
  Research item 1, and now the ADEMP appendix's corrected "Still
  open" bullet), so no false claim exists in the document; only the
  underlying simulation work remains. To complete: extend the
  scenario table in `analysis/scripts/sim_multicenter.R` (or the
  scenario-construction chunk in `report.Rmd`) with `true_trt = 0`
  and full-grid interaction scenarios, then rerun via the `sim-run`
  chunk (`bash tools/render.sh analysis/report/report.Rmd` after the
  scenario table is edited) and update Table 3 and its prose to read
  from the regenerated `.rds`.

- **Item 4 (acceptance, b): commit to the pedagogical/tutorial
  framing** (retitle, rewrite the abstract's opening, move granular
  citation-by-citation literature detail to supplementary material).
  Deferred: this is an editorial identity decision for the paper
  (new title, restructured abstract, material moved out of the main
  text), explicitly recorded across three prior review rounds as
  "an editorial decision left to the author" (Revision History,
  2026-08-14 follow-up entry). Making this change unilaterally risks
  altering the author's intended framing without their sign-off. No
  command needed; requires the author's decision on framing (i),
  (ii), or (iii) per the whitepaper's Section 5, followed by a
  retitle/abstract rewrite/section move once decided.

- **Item 5 (acceptance, b): substitute a Kenward-Roger or
  Satterthwaite denominator-df correction (via `lmerTest`) for the
  naive $N$-minus-fixed-effects approximation, evaluated across the
  full scenario grid.** Deferred: this requires (1) adding an
  `lmerTest`-based refit or `pbkrtest`-based correction to
  `fit_methods()` for both mixed-model methods, (2) rerunning the
  full 24-scenario, $R = 1{,}500$ simulation (Kenward-Roger df
  computation is per-model and materially slower than the current
  naive df, so full-grid runtime was not established and budgeting
  it as "a few minutes" would be a guess), and (3) updating Table 1,
  Table 2, and Table 3 and their prose from the new output. Out of
  budget for this pass. To complete: add `lmerTest::lmer()` (or
  wrap the existing `lme4::lmer()` fits with
  `lmerTest::as_lmerModLmerTest()`) in `fit_methods()` for methods 3
  and 4, extract `summary(m)$coefficients["trt", "df"]` in place of
  `df_naive`/`df_naive4`, then rerun
  `bash tools/render.sh analysis/report/report.Rmd`.

- **Item 6 (desirable polish): resync the Zotero collection**
  referenced by
  `analysis/report/zotero-sync/missing-references-for-zotero-import.bib`
  (16 of 24 bibliography entries absent from the linked Zotero
  collection). Deferred: this is a write operation against the
  user's personal Zotero library (collection `BR8ZFRRB`), not a
  manuscript-source edit, and the whitepaper itself scores it as not
  affecting submission readiness (all 24 entries already resolve
  correctly in `references.bib`). Making changes to an external
  personal library without explicit confirmation was judged out of
  scope for a source-remediation pass. To complete: use the
  `zotero-mcp` tools (e.g. `add_items_to_collection` against
  collection `BR8ZFRRB`) to import the 16 missing entries listed in
  the `.bib` file above.

- **Item 7 (desirable polish): full copyedit pass.** Deferred per
  Budget instructions (do not let (c)-tier items crowd out (a)/(b));
  no specific defect was flagged beyond the items already addressed
  above.

## 3. New issues found while fixing

- None. The source-level inspection performed while fixing M1 and m1
  (reading the full ADEMP appendix section and the three figure
  chunks) did not surface any defect the whitepaper had not already
  flagged.
