# Referee Remediation Log: report.Rmd
*2026-11-17 18:33 PST*

This log records remediation of `referee-report-2026-11-17.md`. The
referee report itself was not edited. The uncommitted voice-revision
edits (`voice-revision-log-2026-11-17.md`) were kept and built on.
Nothing was staged, committed, pushed, or rendered.

## How the changes were checked

A full render was out of budget. The simulation runs inside the
`sim-run` chunk, and no knitr cache exists. Instead, the results were
reproduced by a parallel replay of the saved per-replicate RNG states
in `analysis/data/derived_data/rng_states.rds`.

- `RNGkind("L'Ecuyer-CMRG"); set.seed(20260310)` reproduces stored
  state 1. A sequential data-only pass reproduced all 36,000 stored
  states and their scenario labels exactly. `lmer` and `lmerTest` do
  not consume the RNG stream. **[verified]**
- The modified `fit_methods()` was then run on every replicate
  (45,000 = 30 scenarios x 1,500) with `parallel::mclapply`. Every
  OLS and random-site row that should be unchanged reproduced the
  last rendered `report.tex` exactly. Examples are K10 hiVar bal
  Ignore 0.400/0.984, Fixed 0.547/0.960, and K10 noVar bal Random
  singular rate 0.557. **[verified]**
- Wall time was 45 minutes for the fits, because the machine was
  shared with other agents' simulations (load average about 260 on 8
  cores). No single R process did the whole run, but the replay
  exceeded the 10-minute guideline in wall time. It is recorded here
  for transparency.
- Every Rmd chunk except `sim-run` was then executed against the
  replayed objects, and all 54 inline `r` expressions were evaluated.
  All ran without error. Each qualitative claim in the new prose was
  checked against the values. **[verified]** The `imbal-cv` chunk was
  run separately and gave CV 0.954/1.02 and mean N 201/602.
  **[verified]**
- `tinytest::run_test_dir('inst/tinytest')`: 38 of 38 pass.
  **[verified]**
- The Satterthwaite fallback cannot happen silently. The script
  stops at source time if `lmerTest` is missing, `sim-run` asserts
  `df_fallback_rate == 0`, and a tinytest checks it.
- Minor 1 could not be checked against the Kahan and Morris (2012)
  text, because web search hit the account's spend limit late in the
  session. The new wording follows from the variance formula.

'Verified by replay' below means that the code and inline numbers
were exercised as above. The PDF itself has not been regenerated.

## 1. Fixed

### Major comments (tier a)

- **Major 1 (Figure 3 mislabeled).** Added
  `pair_balance_scenarios()` to `sim_multicenter.R`. It reads balance
  from the scenario table's `balanced` column, pairs `_int` with
  `_int_imb`, and drops unpaired bases. The `fig-imbalance` chunk uses
  it, with a `stopifnot()` that each base has exactly two members.
  New tinytests assert the classification for every label (referee
  suggestion 5). The replay showed that the Discussion's imbalance
  claim was wrong ('modest SE increase, small power decrease'). The
  paragraph was rewritten: without interaction, SE was unchanged and
  power differences went both ways; with interaction, SE rose and
  power fell. **[verified by replay]**
- **Major 2 (fixed vs random contradiction).** The efficiency-loss
  and 'highest power' claims were removed. The Results and
  Discussion now state that the two were indistinguishable (maximum
  power difference 0.003, coverage 0.002, by inline `r`). They
  explain that this follows from within-site balance with 20 per
  site. **[verified by replay]**
- **Major 3 (random-slopes power loss omitted).** Table 3 now has
  Model SE, coverage with K - 1 df, and Type I error from the
  matching null scenario. The Results, Discussion, and abstract
  report both halves of the trade-off: coverage gain +2.5 to +5.8
  points, and power loss 3.5 to 20.4 points (at least 17.3 at
  K = 10). **[verified by replay]**
- **Major 4 (df = N - p).** Both mixed models now use Satterthwaite
  df (`lmerTest::as_lmerModLmerTest`). The naive df is used only as a
  flagged fallback (`df_fallback`, which never triggered in the
  replay). A K - 1 df sensitivity analysis (`power_km1`,
  `coverage_km1`) was added. Six null scenarios with interaction
  were appended to the end of the grid, so the original 24 scenarios
  keep their RNG stream. Findings: the random-intercept df stayed
  about N - K - 1, so its results barely moved. The random-slope df
  are bimodal. Non-singular fits average 7 to 37 df and singular
  fits 55 to 304. Coverage is lower among singular fits, and the
  prose reports this. Random-slope Type I error is 0.032 to 0.055.
  **[verified by replay]**
- **Major 5 (grid avoids the informative regimes).** Claims were
  narrowed, not the grid expanded. 'Present study', the Discussion,
  Limitations, and Future research item 2 now state that the grid
  cannot separate fixed from random. They also say that small
  centers, many sites, and low ICC were not simulated. The grid
  expansion itself is deferred (see below). **[applied; prose only]**
- **Major 6 (estimand mismatch).** The ADEMP Estimand bullet now
  defines the conditional target of the fixed-site estimator, with
  weights n_i1 n_i0 / n_i, and cites Kahan et al. (2023).
  `generate_trial_data()` attaches `cond_target` without consuming
  RNG (a tinytest checks this), and `summarize_simulation()` reports
  `bias_cond` and `coverage_cond`. The replay shows fixed-site
  coverage of its own target of 0.945 to 0.961 in all 12 interaction
  scenarios. The undercoverage against delta is therefore an
  estimand mismatch, and the Results and Discussion say so.
  **[verified by replay]**
- **Major 7 (Type I overstated).** The 'close to nominal' paragraph
  was replaced. Ignore-site is described as conservative, up to 12
  MCSEs below nominal. The K30 hiVar imbal excursion (0.065 and
  0.068, 2.4 to 2.8 MCSEs) is flagged as one shared event. The new
  interaction null cells show fixed and random-intercept rejection
  of 0.069 to 0.110. All numbers are inline `r`. R was not increased
  for the excursion cell. **[verified by replay]**
- **Major 8 (ICH E9 quotations).** I downloaded the E9 PDF from the
  `.bib` URL and confirmed the text. Quote (a) is restated in its
  Section 3.2 context ('explore the heterogeneity', random centre and
  treatment-by-centre effects). The 'not appropriate to include a
  term for centre' sentence was added. The fabricated quote (b) was
  replaced with the verbatim sentences from Sections 2.3.2 and 5.7.
  The Discussion sentence that cited E9 for the random-intercept
  default was rewritten. **[verified against the primary source]**
- **Major 9 (text and code disagree).** (a) 'Permuted blocks' was
  replaced by an accurate description: one random permutation of a
  balanced vector per site. (b) The CV and N statements now come
  from a new `imbal-cv` chunk (0.95/1.02; N 201/602), with the
  four-step generator described. (c) 'All factorial combinations'
  became '16 of the 24 cells', with the omitted cells listed and the
  null arm described. (d) The ADEMP Methods bullet now says that
  ignore and fixed use `lm`. **[verified]**
- **Major 10 (revision history in manuscript).** The 'Morris et al.
  (2019) ADEMP Compliance' section was moved verbatim to
  `docs/morris-audit-2026-04-17.md`, under a new 'Update:
  2026-11-17' section with a status note. Revision wording was
  removed from the ADEMP bullets, the Discussion, Future research,
  and the abstract ('is now fit', 'partially addressed', 'replacing
  an earlier implementation', 'previously unreported in this
  simulation design'). A grep confirms none remain. Data
  availability now points to the audit file. **[applied]**

### Minor comments and references (tier b)

- **Minor 1:** the mechanism was rewritten as positive correlation
  of the arm means through the shared site effect, which the
  unadjusted variance ignores. **[applied; argued from the variance
  formula, not checked against the Kahan-Morris full text]**
- **Minor 2:** the 'design-based tradition in spirit' sentence was
  replaced. It now states that the DGM is a super-population model.
- **Minor 3:** Edgar et al. verified from the PMC full text. CRASH-2
  is a binary-outcome trial. The abstract reports 271 centres in 40
  countries (the Methods give 274 recruiting hospitals) and that
  random intercepts 'may increase power and decrease bias'. The
  prose now quotes this and notes the binary-outcome limitation.
- **Minor 4:** the efficiency claim is now cited to Kahan and Morris
  (2013); Bates et al. is cited only as software.
- **Minor 5:** 'ubiquitous' (Jones; Fedorov and Jones) was removed.
  The Discussion attributes 'inevitable' to Senn and low power to
  Senn and Lewis and to E9 (E9's 'generally has low power' was
  verified).
- **Minor 6:** the singular-fit sentence now separates zero site
  variance (52.7 to 55.7%) from positive variance (at most 8.2%).
- **Minor 7 (partial):** the subsection 'Why the simulation needs a
  genuinely random site effect' was condensed to one paragraph in
  methods register. The first subsection's worked example was kept.
- **Minor 8:** the heading now reads 'What does 'random' mean here?'.
- **Minor 9:** the Conv. column was dropped from Table 1 (rate stated
  in the text), and Sing. shows '--' for OLS rows in Tables 1 and 2.
- **Minor 10 (partial):** x-axis labels went from 5 to 6 pt up to
  7 pt, and Figure 2 is larger. The figures were not refaceted.
- **Minor 11:** the dead `n_sites <= 50` branch was removed. The
  refit-on-warning was replaced by `withCallingHandlers` muffling,
  which fits once with an identical estimate.
- **Minor 12:** the `renv` overstatement was removed. Data
  availability now names the Dockerfile and the BLAS and compiler
  caveat.
- **Minor 13:** `iche9` author changed to 'International Conference
  on Harmonisation' (verified on the PDF cover).
  `sennlewis2019treatment` now carries the note 'JAMA Guide to
  Statistics and Methods', and its DOI was corrected (see New
  issues). Falissard and Chavance: Crossref and web search found no
  DOI, so none was added.
- **Minor 14:** the effect size is now stated relative to sigma_e,
  with the total SD (about 1.22 at sigma_alpha^2 = 0.5).
- **References table:** added and cited `kenward1997small`,
  `luke2017evaluating`, `mcneish2016modeling`, `kahan2023estimands`,
  `bugni2018inference`, `ye2023toward`, and
  `kuznetsova2017lmertest`. Each was confirmed by web search and
  Crossref DOI lookup (Kahan et al. went online in 2022; volume 52
  is dated 2023). Islam and Bangdiwala are now engaged as overlapping
  prior work in 'Present study'.
- **Abstract:** rewritten for accuracy. The self-referential novelty
  claims were removed, and it now states the Satterthwaite df, the
  null-arm and conditional-target findings, the two-sided
  random-slopes trade-off, and the scope limit.

### Suggestions (tier c)

- Suggestion 5 (tinytest for the figure classification): done.
- Suggestion 6 (move the audit to the repository): done.
- Suggestion 4 (interval width): `mean_ci_width` is computed in
  `summarize_simulation()` but not displayed. Table 3 shows Model SE
  instead.

## 2. Deferred

- **Re-render the manuscript.** The full simulation now has 30
  scenarios, 4 methods, and Satterthwaite df. Estimated at 35 to 45
  minutes single-threaded on an idle machine (14 minutes before
  these changes). Command, from the repository root:
  `bash tools/render.sh analysis/report/report.Rmd`.
  The replay shows the render will reproduce the numbers above
  exactly, given the same package versions. This render also rewrites
  `analysis/data/derived_data/rng_states.rds` with 45,000 states.
- **renv.lock.** `lmerTest` (and `purrr`, used by the new `imbal-cv`
  chunk) were added to `DESCRIPTION` Suggests. `lmerTest` is not yet
  in `renv.lock`. Run
  `renv::snapshot()` inside the container (`make r`), then
  `make check-renv`.
- **Major 5 grid expansion** (small centers with simple
  randomization, K of 50 to 100, ICC of 0.01 to 0.05). This needs a
  new allocation mode in `generate_trial_data()` and new scenario
  rows, and it changes the study design. It is the author's decision
  and out of runtime budget. New rows must be appended after row 30
  of `build_scenarios()` to keep the existing RNG streams.
- **Suggestions 1 to 3** (recast around random slopes, small-center
  and many-site scenarios, informative cluster size). These are
  framing and design decisions for the author.
- **Minor 7 and 10 (partial).** A further tone pass on the first
  'random' subsection, and refaceting Figures 1 and 2 by factor.
- **Kenward-Roger df.** Not implemented. It is named as a limitation
  and in Future research item 5.

## 3. New issues found while fixing

- **Wrong DOI.** `sennlewis2019treatment` had DOI
  10.1001/jama.2019.1553, which Crossref resolves to an unrelated
  JAMA poem ('Love Poem Without Wheat'). Corrected to
  10.1001/jama.2019.1480 (verified by Crossref title, volume, and
  page). All other DOIs in `references.bib` resolve to the stated
  titles.
- **Unused dependency.** `sim_multicenter.R` loaded
  `library(broom.mixed)` but never used it. Host R lacks the package,
  so the script could not be sourced outside the container. The call
  was removed.
- **Interaction nulls are anti-conservative.** The new interaction
  null cells show the random-intercept and fixed-site tests rejecting
  at up to 0.110 (K30 hiVar int imb) for delta. This is a substantive
  result that the original grid could not show. It is now reported
  and interpreted as an estimand mismatch.
- **Code comment out of date.** The `sim-run` chunk's old comment
  justified omitting the interaction null rows because 'sigma_trt_site
  has no bearing on size'. That was false (see the previous item).
  The comment was removed along with the old tribble.
