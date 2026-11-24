# Deferred-Item Pass: 07-multicenter-rct
*2026-11-23 12:45 PST*

This pass reviews the Deferred section of
`docs/pub_review_remediation_2026-08-16.md` (which answers
`docs/pub_review_whitepaper_2026-08-16.md`) against the current
files. It does not edit the whitepapers or earlier logs.

Context that changes most classifications: there are no commits
touching the manuscript content since 2026-08-16 other than two
auto-backups (`9e49a36`, `f131b8e`) and housekeeping (`b35a6bb`,
`72a96a5`). A later, separate referee round on 2026-11-17 made
large uncommitted edits to `analysis/report/report.Rmd`,
`analysis/scripts/sim_multicenter.R`, `inst/tinytest/test_basic.R`,
`analysis/report/references.bib`, `DESCRIPTION`, and
`docs/morris-audit-2026-04-17.md`, recorded in
`analysis/report/referee-remediation-log-2026-11-17.md`. Items
marked RESOLVED-SINCE below were resolved by that uncommitted work,
not by a commit. The 2026-11-17 numbers were verified by an RNG
replay; the PDF (`analysis/report/report.pdf`, dated 2026-08-30)
has not been regenerated and still shows the old 24-scenario,
naive-df results.

## 1. Inventory

| Source log | Item | Class |
|---|---|---|
| remediation 2026-08-16 | 3a. Null arm for random slopes in the six interaction scenarios | RESOLVED-SINCE |
| remediation 2026-08-16 | 3b. Random slopes over the full $K$/$\sigma^2_\alpha$/balance grid | AUTHOR-DECISION |
| remediation 2026-08-16 | 4. Commit to pedagogical/tutorial framing (retitle, abstract, move literature detail) | AUTHOR-DECISION |
| remediation 2026-08-16 | 5. Kenward-Roger or Satterthwaite df in place of naive df | RESOLVED-SINCE |
| remediation 2026-08-16 | 3a/5 follow-on. Re-render so the PDF reflects the new grid and df | LONG-RUN |
| remediation 2026-08-16 | 6. Resync Zotero collection `BR8ZFRRB` | AUTHOR-DECISION |
| remediation 2026-08-16 | 7. Full copyedit pass | DO-NOW |

Details:

- **3a.** `build_scenarios()` in `analysis/scripts/sim_multicenter.R`
  now appends six `H0_*_int*` rows (true_trt = 0,
  sigma_trt_site = 0.2) after row 24, and `fit_methods()` fits the
  random-slopes model on every replicate. Table 3 reports Type I
  error from the matching null scenario
  (`sim_summary_slope_null` in the `sim-run` chunk). Inspected in
  the current files.
- **5.** `summarize_mixed()` uses `lmerTest::as_lmerModLmerTest()`
  Satterthwaite df, with a flagged naive-df fallback, a `stopifnot()`
  in `sim-run` that the fallback rate is zero, and a $K - 1$ df
  sensitivity analysis. The whitepaper item accepted either
  Kenward-Roger or Satterthwaite; Kenward-Roger remains unevaluated
  and is disclosed in Limitations and Future research item 5.
  Inspected; the test suite (below) exercises the df path.
- **3b.** The random-slopes comparison still covers only six
  interaction cells (no noVar interaction cell, no modVar
  imbalanced interaction cell). The manuscript discloses this in
  Limitations and Future research item 1, so no false claim exists.
- **4.** Partly addressed since: the abstract now calls the study
  'a tutorial-style replication' whose findings 'agree with earlier
  simulation studies', and the 'Present study' section was narrowed.
  The title ('Statistical Issues in Multicenter Randomized Clinical
  Trials') and the long literature-review sections are unchanged.

## 2. Done now

- **Item 7, mechanical copyedit of `analysis/report/report.Rmd`.**
  The 2026-11-17 voice revision already rewrote the prose
  (`analysis/report/voice-revision-log-2026-11-17.md`), so this pass
  was limited to checks that pass can miss. Scanned for em dashes,
  British spellings, and the word list in the user's standards:
  none in author prose. The four hits ('centre' at lines 124, 125,
  130; 'randomisation' at 303) are inside verbatim ICH E9
  quotations and were kept as published. Rewrapped three prose
  lines that exceeded 78 characters (the hospital-selection
  sentence in 'Why the simulation redraws the site effects', the
  random-slopes df sentence in Results, and the Ruvuna/Vierron
  sentence in Discussion). Whitespace-only change. The remaining
  over-length lines are YAML, chunk headers, a display equation,
  and kable code, and were left alone. `[verified]`:
  `knitr::purl()` on the edited file succeeds (structural check
  only). `tinytest::run_test_dir('inst/tinytest')` passed 38 of
  38 in this pass; it was run before the rewrap, which does not
  touch any file the tests load.
- **Item 6, partial: refresh the Zotero import file.**
  `analysis/report/zotero-sync/missing-references-for-zotero-import.bib`
  still carried two values that `references.bib` corrected on
  2026-11-17: the `sennlewis2019treatment` DOI
  `10.1001/jama.2019.1553` (which Crossref resolves to an unrelated
  JAMA poem, per the 2026-11-17 log) and the `iche9` corporate
  author. Both now match `references.bib`
  (`10.1001/jama.2019.1480`; 'International Conference on
  Harmonisation'). Importing the old file would have written the
  wrong DOI into the Zotero library. `[applied, unverified]`: the
  corrected DOI was taken from `references.bib`; I did not resolve
  it against Crossref in this pass (no external services).
- **Timed trial for the render estimate.** Ran the current
  simulation code single-threaded on three scenarios (one K = 10,
  two K = 30) with 20 replicates each: 4.0 s, or 0.067 s per
  replicate. Extrapolated to 30 scenarios x 1,500 replicates this
  gives about 50 minutes under the current machine load (the
  sample is weighted toward K = 30, so the true figure is likely
  somewhat lower). `[verified]` timing; the extrapolation is an
  estimate.

## 3. Long runs

- **Re-render the manuscript.** From the inner repository root:

  ```
  bash tools/render.sh analysis/report/report.Rmd
  ```

  Estimated 40 to 50 minutes single-threaded (timed trial above;
  the 2026-11-17 log estimated 35 to 45 minutes on an idle
  machine). There is no knitr cache for `sim-run` (the cache
  directory is untracked and absent), so the full simulation will
  run. The render also rewrites
  `analysis/data/derived_data/rng_states.rds` with 45,000 states.
  Afterwards, check that Table 1 to Table 3 and the inline numbers
  match the values the 2026-11-17 log reports from its replay (for
  example, K10 hiVar bal Ignore power/coverage 0.400/0.984, fixed
  coverage of its conditional target 0.945 to 0.961, random-slopes
  Type I error 0.032 to 0.055). No manuscript text needs editing if
  they match, because all numbers are inline `r`. Run this on the
  host, not via `make docker-render`, until the renv.lock issue
  below is fixed.

## 4. Author decisions

- **3b. Extend random slopes to the full grid.** Options: (i) keep
  six interaction cells and the current disclosure; (ii) append the
  missing cells (noVar interaction at K = 10/30, modVar imbalanced
  interaction, with null counterparts) after row 30 of
  `build_scenarios()` so earlier RNG streams are unchanged; (iii)
  fold this into the larger regime expansion (small centers, many
  sites, low ICC) from the 2026-11-17 Major 5. Evidence: the
  current grid makes fixed and random intercepts indistinguishable
  by construction, so (ii) alone adds little. Recommendation: (i)
  for this submission, (iii) if the author wants the paper to carry
  new findings.
- **4. Framing.** Options: (i) keep the general title with the new
  'tutorial-style replication' abstract; (ii) retitle to signal a
  tutorial/replication (for example, naming site effects and
  simulation) and move the citation-by-citation literature sections
  to a supplement; (iii) recast around the random-slopes and
  estimand-mismatch findings. Evidence: the abstract already states
  replication framing, so the remaining mismatch is the title and
  the length of the Introduction. Recommendation: (ii), a small
  editorial change that aligns the title with the abstract.
- **6. Zotero resync.** Writing to the personal Zotero collection
  `BR8ZFRRB` is an external write and outside this pass. The import
  file lists 16 entries from August and is now missing the seven
  entries added on 2026-11-17 (`kuznetsova2017lmertest`,
  `kenward1997small`, `luke2017evaluating`, `mcneish2016modeling`,
  `kahan2023estimands`, `bugni2018inference`, `ye2023toward`).
  Recommendation: regenerate the import list from `references.bib`
  against the collection's current contents, then import with the
  Zotero tools.

## 5. New issues found

- **`lmerTest` is not in `renv.lock`, so a container render will
  fail.** `sim_multicenter.R` stops at source time without
  `lmerTest`. The Dockerfile installs project packages only through
  `renv::restore()`, and `renv.lock` has no `lmerTest` entry
  (inspected; `purrr` is present). So `make docker-render` would
  stop in the `sim-run` chunk. The Data and code availability
  section also states that package versions are recorded in
  `renv.lock`, which is not yet true for `lmerTest`. The 2026-11-17
  log deferred the snapshot; the consequence for the containerized
  build was not stated there. Fix inside the container: `make r`,
  then `renv::install('lmerTest'); renv::snapshot()`, then
  `make check-renv`. Host has `lmerTest` 3.2.1, `lme4` 2.0.1, R
  4.6.2; the lockfile pins R 4.6.0.
- **The work this pass builds on is uncommitted.** All 2026-11-17
  remediation (scenario grid, Satterthwaite df, tests, references)
  exists only in the working tree. Nothing was committed here, per
  instructions.
- **The rendered PDF is stale.** `analysis/report/report.pdf` and
  `report.tex` (2026-08-30) predate the 2026-11-17 changes and show
  naive-df results and the old Discussion claims (for example, the
  imbalance and fixed-versus-random statements the 2026-11-17 round
  corrected). Do not circulate it until the re-render above.
