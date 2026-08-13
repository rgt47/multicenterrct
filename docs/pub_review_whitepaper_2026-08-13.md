# Referee Review: Statistical Issues in Multicenter Randomized Clinical Trials

*Review date: 2026-08-13 11:15 PDT*

This white paper reports a referee-style review of the single research
report in this repository, `analysis/report/report.Rmd` ("Statistical
Issues in Multicenter Randomized Clinical Trials," R. G. Thomas). The
review follows the standards applied by a referee for a statistical
journal (e.g., *Statistics in Medicine*, *Biometrics*, *JCGS*). No prior
`pub_review_whitepaper_*.md` exists in `docs/`, so this is a first review,
not an update.

## 1. Summary of the work under review

The manuscript is a Monte Carlo simulation study addressing four
interrelated questions in the design and analysis of multicenter
randomized controlled trials with continuous outcomes: (1) whether site
effects should be ignored, modeled as fixed effects, or modeled as random
effects; (2) the consequence of failing to adjust for the stratification
variable (site) used at randomization; (3) treatment-by-site interaction;
and (4) the effect of imbalanced site sizes. The simulation crosses
number of sites (K = 10, 30), site-level variance (none, moderate,
large), presence/absence of treatment-by-site interaction, and balanced
versus imbalanced site sizes, for 16 scenarios × 3 analytic methods
(ignore site, fixed site effects, random site effects via `lme4::lmer`),
each replicated R = 1,500 times. Performance is reported as bias,
empirical SE, model-based SE, power, coverage, and convergence rate. The
paper is structured as Introduction (with a substantial literature
review organized around the four questions), Methods (ADEMP-structured),
Results (one summary table, three figures), Discussion, Future Research,
and a self-audit against the Morris, White, and Crowther (2019) ADEMP
reporting standard, which references a separate audit document,
`docs/morris-audit-2026-04-17.md`. The paper has no abstract and is not
divided into a standalone paper with sections for data/code availability
or conflict of interest.

## 2. Major issues

**M1. The compiled PDF does not reflect the current source, so the
numbers a reader sees have not been verified against the current
analysis code.** *Location: `analysis/report/report.Rmd` vs.
`report.tex`/`report.pdf`/`report.log`.* Verified: file modification
times show `report.Rmd` was last edited 2026-08-09 12:47, while
`report.tex`, `report.pdf`, and `report.log` are all dated 2026-07-05
13:44 — over a month stale. Whatever prose or code changed between
those dates (including, per the diff evidence discussed in M2, the
entire "ADEMP Compliance" self-audit subsection) is untested against a
real knit. **Remediation:** re-render through `tools/render.sh` (per
this repository's own rendering convention) before any further review
or submission, and adopt a pre-commit or CI check that fails when the
`.Rmd` is newer than its `.tex`/`.pdf` sibling.

**M2. The report's own "ADEMP Compliance" appendix is stale and
misrepresents the current state of the code.** *Location:
`report.Rmd:680-698`, "Morris et al. (2019) ADEMP Compliance."* The
report states the audit's "key gaps" are unresolved and that "a
remediation plan is recorded in the audit file and will be taken up in
a subsequent revision." Inspected: as currently written,
`analysis/scripts/sim_multicenter.R` already contains `mcse_bias`,
`mcse_empirical_se`, `mcse_mse`, `mcse_model_se`, `mcse_power`,
`mcse_coverage`, and `mcse_convergence` columns in
`summarize_simulation()` (lines 182-222); `run_simulation()` already
captures a per-replicate `.Random.seed` via the `rng_states` list
(lines 140, 152, 178); and `report.Rmd`'s `sim-run` chunk already pins
`RNGkind("L'Ecuyer-CMRG")` before `set.seed()` (lines 319-320). Four of
the five items in the audit's "Remediation plan" (§1, §2, §4, and
partially §5) are therefore already implemented in code, but the
report's narrative claims otherwise, and the audit document itself
(`docs/morris-audit-2026-04-17.md`) has not been re-run or updated to
reflect this. This is a referee-visible contradiction: a reviewer
reading the report's self-audit will believe the study fails Morris
compliance on points it in fact satisfies, while (per M3-M5 below) it
still fails compliance on points neither the report nor the audit
currently flag. **Remediation:** re-run the Morris audit against the
current code and report, and either update or retire the "ADEMP
Compliance" appendix so it reports the actual current state, not a
snapshot from 2026-04-17.

**M3. Convergence is not actually tracked as Morris (2019) §5.1
requires; singular/boundary `lmer` fits are silently absorbed as
"converged."** *Location: `analysis/scripts/sim_multicenter.R:90-98`,
`fit_methods()`.* The random-site model is fit via
`tryCatch(lmer(...), error = function(e) NULL, warning = function(w)
suppressWarnings(lmer(...)))`. This only distinguishes a hard `error`
(rare) from everything else; a `warning` — which is exactly the
condition `lme4` raises for a singular/boundary random-effects fit
(`boundary (singular) fit: see help('isSingular')`) — is caught,
suppressed, and the model is silently refit and treated as a normal,
converged result. Verified by direct execution: for the
`K10_noVar_bal` data-generating scenario (σ²_α = 0, i.e., no true site
variance — a scenario actually present in the paper's own scenario
grid, `report.Rmd:297`), 300 simulated replications produced 0 `lmer`
errors but 159 singular-boundary fits (53%), none of which would be
distinguished from ordinary convergence by `fit_methods()`. The
report's claim that "Non-convergence is treated as a first-class
outcome and its rate is reported per scenario and method"
(`report.Rmd:236-237`) and the ADEMP appendix's claim that the "Seed
set once" / "RNG states stored" gaps are the operative concerns are
therefore both misleading: the `convergence_rate` column that exists
in the code cannot show anything but ≈100% for the boundary-fit
scenarios regardless of how often the variance component estimate is
degenerate, because `isSingular()` is never checked. This directly
undermines the reported "lowest convergence rate observed... was [X]"
headline statistic (`report.Rmd:378-380`), which is very likely an
overstatement of estimation reliability in the σ²_α = 0 and
low-σ²_α scenarios. **Remediation:** add an `lme4::isSingular(m3)`
check inside `fit_methods()`, record it as a distinct outcome (e.g., a
`singular` logical column, separate from `converged`), report the
singular-fit rate per scenario/method alongside `convergence_rate`,
and discuss its implications — a random-intercept model with a
true zero variance component will frequently produce a boundary
estimate, which is expected behavior but must be disclosed, not
absorbed.

**M4. No null-hypothesis (δ = 0) scenario is simulated, so the paper
cannot support any claim about Type I error control.** *Location:
`report.Rmd:257-273` (Parameter values) and throughout Results/
Discussion.* Inspected: `true_trt = 0.3` is fixed across all 16
scenarios (`report.Rmd:297-312`); there is no δ = 0 arm. The paper
reports "power" (rejection rate under the true alternative) and
"coverage" of the 95% CI around δ = 0.3, but never estimates the
empirical Type I error rate (rejection rate when H₀: δ = 0 is true).
Coverage of a CI centered on a nonzero true value is not equivalent to
size control of the test of no treatment effect, which is the
hypothesis of central relevance to the literature this paper engages
(Kahan and Morris 2012's finding of "type I error rates below the
nominal level" for unadjusted analysis under stratified randomization
is a δ = 0 result). Without a null arm, the paper's claims about
"valid inference," "biased inference" from failing to adjust for
stratification, and general applicability of its coverage/power
findings to the Type I error question are not directly demonstrated by
its own simulation; they are asserted by appeal to the cited
literature rather than shown. **Remediation:** add δ = 0 to the
scenario grid (doubling scenario count, or a reduced factorial subset
sufficient to characterize Type I error under the same site-variance/
balance/interaction conditions), and report empirical Type I error
with its Morris Table 6 MCSE alongside power and coverage.

**M5. The Monte Carlo SE-based sample-size justification in the
Methods section is arithmetically wrong.** *Location:
`report.Rmd:327-334`.* The text states: "For coverage MCSE ≤ 0.6 pp at
the nominal 95% level, R ≥ 1,584; R = 1,500 gives MCSE ≈ 0.56 pp."
Verified by direct calculation using the paper's own formula,
MCSE(coverage) = √(p(1−p)/R) with p = 0.95: at R = 1,500, MCSE =
0.563 pp, matching the paper's "≈0.56 pp" claim. But the R required to
first achieve MCSE ≤ 0.60 pp under this formula is R ≥ 1,320, not R ≥
1,584 (at R = 1,584, MCSE = 0.548 pp — a tighter bound than 0.6 pp,
and R = 1,500 already satisfies the stated 0.6 pp criterion by a
margin). The two sentences are therefore internally inconsistent: if
1,584 replications were truly required for the stated precision
target, then R = 1,500 would not meet it, contradicting the paper's
own next clause. This is a small but real numerical/rigor error in a
paragraph whose sole purpose is to formally justify the simulation's
sample size — exactly the kind of arithmetic a referee is expected to
check and exactly the kind of error that undermines confidence in
other unverified numbers in the paper (see the epistemic-status note
in §6). **Remediation:** recompute and correct the derivation, or
state explicitly what different criterion (if any) produces 1,584 as
the threshold.

**M6. Inconsistent inferential basis between the p-values and the
confidence intervals for every method, undocumented in the Methods
section.** *Location: `analysis/scripts/sim_multicenter.R:99-108`
(`random_site` p-value) vs. `summarize_simulation()` coverage formula
(`sim_multicenter.R:212-216`).* Inspected: the two-sided p-value for
the random-site method is computed as `2 * pt(-abs(s3[1]/s3[2]), df =
df_kr)` with `df_kr <- nrow(dat) - length(fixef(m3))` — i.e., total
observations minus the number of *fixed-effect* parameters (2: the
intercept and the treatment indicator). This is neither the naive
residual df of the corresponding fixed-effects model (which would
subtract the site fixed effects too) nor a Kenward-Roger or
Satterthwaite denominator-df approximation for the mixed model; it is
an ad hoc, unusually generous df that will typically overstate the
effective information the mixed model actually carries once the
random-effects covariance structure is accounted for. Meanwhile,
`coverage` for **every** method (ignore, fixed, and random) is computed
using a fixed z-critical value, `est ± 1.96 * se`
(`sim_multicenter.R:213-214`), not a t-quantile with any degrees of
freedom at all. So within the same paper: the reported "power" for the
random-site method rests on a t-test with an unconventional df choice
never named or justified in the Methods section (which says only "a
linear mixed model with random site effects via `lme4::lmer`,"
`report.Rmd:232`), while the reported "coverage" for that same method
uses a different (asymptotic, z-based) reference distribution
entirely. The Future Research section (`report.Rmd:658-663`) correctly
identifies that Kenward-Roger/Satterthwaite corrections are not
implemented and should be evaluated — but this undersells the issue,
since it frames it as an unexplored extension rather than disclosing
that the paper's *current* p-values already rely on an unstated,
non-standard df approximation, and that this approximation is not even
used consistently with the paper's own coverage metric. The variable
name `df_kr` is also misleading, since it suggests a genuine
Kenward-Roger adjustment that is not actually computed anywhere in the
codebase (confirmed by `grep` — `lmerTest`, `Satterthwaite`, and
`Kenward` appear only in the Future Research prose, never in code).
**Remediation:** either (a) use a single, named, justified reference
distribution consistently for both testing and interval construction
across all three methods (e.g., adopt `lmerTest` with
Satterthwaite/Kenward-Roger df now, rather than deferring it to future
work, given that this is precisely the mechanism that could explain
part of the paper's own coverage results), or (b) if the current ad
hoc df is retained, name it accurately (e.g., `df_naive`) and disclose
and justify the choice, and the resulting z/t mismatch between the
power and coverage columns, in the Methods section.

**M7. Table 1's caption and headline text claim Monte Carlo standard
errors are shown for every estimate; they are not.** *Location:
`report.Rmd:340-419` (`headline-07` and `results-table` chunks).* The
headline paragraph states results are reported "with Morris Table 6
Monte Carlo SEs attached to every estimate in Table 1"
(`report.Rmd:371`), and the table caption repeats "MCSE" framing
implicitly by invoking the Morris reporting standard. Inspected: the
`sim_display` object piped into `kable()` selects only `Scenario`,
`Method`, `Bias`, `Emp. SE`, `Model SE`, `Power`, `Coverage`, and
`Conv.` (`report.Rmd:395-401`) — none of the `mcse_*` columns computed
in `summarize_simulation()` are selected or displayed anywhere in the
rendered table. The MCSE values exist in `sim_summary` but never reach
the reader. This is a direct contradiction between prose and table
content that any careful referee (or reader trying to assess Monte
Carlo error, which Morris (2019) treats as mandatory) will catch
immediately. **Remediation:** either add MCSE columns (or
parenthetical MCSE annotations) to the displayed table, or correct the
headline/caption language to state that MCSEs were computed but are
reported in a supplementary table, and provide that table.

## 3. Minor issues

**m1. Hardcoded replication count in the results-table chunk.**
*Location: `report.Rmd:393`.* `n_converged / 1500` hardcodes the
replication count rather than referencing the `n_sim` value set in the
`sim-run` chunk (`report.Rmd:322`) or a `n_total` column already
present in `sim_summary`. If `n_sim` is ever changed, this
line will silently report an incorrect convergence percentage without
any error. Use `n_converged / n_total` (both already columns of
`sim_summary`) instead.

**m2. No unit tests exercise the simulation code.** *Location:
`inst/tinytest/test_basic.R`.* Verified by inspection: the entire test
suite is `expect_true(TRUE)`. None of `generate_trial_data()`,
`fit_methods()`, `run_simulation()`, or `summarize_simulation()` in
`analysis/scripts/sim_multicenter.R` has any test coverage (e.g., that
`generate_trial_data()` produces the expected treatment balance within
site, that `summarize_simulation()`'s MCSE formulas match known closed
forms on a synthetic input, or that `fit_methods()` returns exactly
three rows per replication). Given the correctness problems identified
in M3 and M6, unit tests on this script would likely have caught at
least the singular-fit handling gap.

**m3. Terminological looseness around "estimand."** *Location:
`report.Rmd:229`.* The ADEMP "Estimand" bullet defines it simply as
"the overall treatment effect δ on the outcome scale" — adequate for
Morris et al.'s (2019) simulation-reporting sense of the word, but
notably not aligned with the ICH E9(R1) (2019) estimand framework
(population, variable, intercurrent-event strategy, population-level
summary), which is the current regulatory-standard usage of the term
in the same clinical-trials literature this paper cites elsewhere
(via the 1998 ICH E9). Given the paper explicitly invokes ICH
guidance, a one-sentence disambiguation (or a citation to E9(R1))
would preempt a referee comment.

**m4. Missing key reference: ICH E9(R1) addendum on estimands
(2019).** *Location: bibliography and Introduction/Methods.* Only the
original 1998 ICH E9 is cited (`references.bib:213-220`, key
`iche9`). The 2019 E9(R1) addendum is the current authoritative source
for estimand-related terminology in regulatory clinical trial
statistics and is a natural citation given m3.

**m5. Missing reference on covariate-adjustment guidance.** The
"failure to adjust for stratification variables" discussion
(`report.Rmd:113-138`) would be strengthened by citing regulatory
guidance directly on point (e.g., FDA's 2023 final guidance on
covariate adjustment in randomized trials), which postdates and
reinforces the Kahan and Morris methodological findings already cited.

**m6. Awkward word choice.** *Location: `report.Rmd:75`.* "@localio2001adjustments
broached an influential overview of the problem" — "broached" means to
raise a topic for the first time or tentatively; "provided,"
"published," or "offered" better conveys a completed, influential
review.

**m7. Asymmetric page geometry undocumented.** *Location:
`report.Rmd:14`.* `geometry: "left=3cm,right=5cm,top=2cm,bottom=2cm"`
gives a 5 cm right margin against a 3 cm left margin — presumably
reserved for reviewer annotation given the accompanying `\linenumbers`
package, but this is not stated anywhere, and an unexplained 2:1 margin
asymmetry looks like an error to anyone who opens the PDF without that
context.

**m8. No conflict-of-interest or funding statement**, even a
boilerplate "not applicable," which most target journals require at
submission regardless of a paper's single-author, non-funded status.

## 4. What remains to be done

**(a) Required for correctness**

1. Fix the singular/boundary-fit handling in `fit_methods()` so
   convergence and singularity are tracked as distinct, disclosed
   outcomes (M3), and re-run the full simulation.
2. Add a δ = 0 null-hypothesis arm to the scenario grid and report
   empirical Type I error with MCSE (M4).
3. Resolve the p-value/coverage reference-distribution mismatch (M6):
   pick one justified df/reference distribution per method and apply
   it consistently to both testing and interval construction.
4. Correct the R ≥ 1,584 vs. R = 1,500 arithmetic in the Methods
   sample-size justification (M5).
5. Re-render the report from the current `.Rmd` through
   `tools/render.sh` so the PDF reflects the current source and code
   (M1), and re-run the simulation cache (note: `cache=TRUE` on the
   `sim-run` chunk hashes only the chunk's own text, not the contents
   of `analysis/scripts/sim_multicenter.R` that it `source()`s —
   confirm the cache is invalidated after any change to that script,
   or force `cache = FALSE` / a manual cache key including the script's
   hash, to avoid silently reporting results from a prior version of
   the simulation code).
6. Display the computed MCSE columns in Table 1, or correct the
   headline/caption text that currently claims they are shown (M7).
7. Update or retire the stale "ADEMP Compliance" appendix so it
   reflects the code's actual current state, and re-run the Morris
   audit (M2).

**(b) Required for acceptance at a statistical journal**

8. Add unit tests for `sim_multicenter.R`'s four functions (m2),
   particularly a synthetic-input check of the MCSE formulas and a
   check that treatment balance within site is honored by
   `generate_trial_data()`.
9. Add an abstract, and (if targeting a journal requiring them)
   keywords, a data/code availability statement (the simulation is
   fully synthetic, so this should be straightforward — point to
   `analysis/scripts/sim_multicenter.R` and the seed), and a conflict
   of interest / funding statement (m8).
10. Extend the literature engagement to the 2019 ICH E9(R1) estimand
    framework and current covariate-adjustment regulatory guidance
    (m3, m4, m5) — see §5 for how this bears on framing.
11. Address the paper's own stated limitation that only a
    random-intercept model was fit despite simulating genuine
    treatment-by-site interaction (σ²_γ = 0.04 scenarios); at minimum,
    add the random-slopes model already flagged as "Future research"
    item 1, since the current interaction scenarios are otherwise
    analyzed by a specification the paper itself says is
    misspecified for that data-generating mechanism.
12. Consider whether "coverage" as currently defined (CI around the
    true nonzero δ = 0.3) is the right primary validity metric absent
    item 2 above, or whether it should be reframed explicitly as a
    calibration check distinct from Type I error.

**(c) Desirable polish**

13. Fix the hardcoded `1500` in the results-table chunk (m1).
14. Correct "broached" (m6) and other minor prose issues found during
    a full copyedit pass (not separately itemized here, as this
    review focused on substantive over line-level issues per referee
    convention).
15. Document or remove the asymmetric page margin (m7).
16. Add MCSE reporting to the imbalance and bias figures (currently
    point estimates only), or note in the figure captions that MCSEs
    are available in the corresponding table.

## 5. Recommended framing

**(a) Plausible framings.** Three framings are viable for this
material: (i) a **methodological simulation study** contributing new
evidence on multicenter analytic strategy choice, submitted to a
clinical-trials-methods journal (*Statistics in Medicine*, *Clinical
Trials*, *Trials*); (ii) a **pedagogical/tutorial synthesis** aimed at
applied trialists, positioned as an integrative review with
illustrative simulation, submitted to a more applied outlet (e.g.,
*Contemporary Clinical Trials Communications*, or a tutorial section
of *Statistics in Medicine*); (iii) a **software/tools contribution**
built around the `zzcollab`-scaffolded, ADEMP-audited simulation
harness itself, submitted to *The R Journal* or the JSS "Code
Snippets" track.

**(b) Recommendation: framing (ii), pedagogical/tutorial synthesis,
not framing (i).** The literature already surveyed by this paper
(Chu et al. 2011; Kahan and Morris 2012, 2013; Kahan and Morris 2013;
Kahan 2014; Islam and Bangdiwala 2024) has repeatedly and consistently
established, across a comparable or larger set of simulation
conditions, that: random-effects/mixed models are the preferred
default over ignoring or fixing site; failing to adjust for
stratification produces conservative (not anti-conservative)
inference; and imbalance produces only modest efficiency loss absent
informative site size. The present simulation reproduces these
findings under a new, integrated factorial design, but — as M3, M4,
and M6 show — does not yet do so with fully correct or disclosed
methodology, and its "genuine gap" relative to the cited work is
thin: Islam and Bangdiwala (2024) already describe itself as a
"recent replication study" of Kahan and Morris (2013) covering both
continuous and binary outcomes. A paper claiming *novel methodological
contribution* (framing i) would need either (1) a new analytic method
not previously compared (e.g., random slopes under interaction,
small-sample df corrections, or an informative-site-size mechanism —
all currently relegated to "Future research"), or (2) a materially
larger or more realistic simulation design than has already appeared
in Chu et al. (2011) and Islam and Bangdiwala (2024). Neither is
currently present. What this paper *does* do well, and what is
comparatively scarce in the literature, is integrate all four issues
(site modeling choice, stratification adjustment, interaction,
imbalance) into a single coherent factorial design with an explicit
ADEMP audit trail, aimed at a trialist audience trying to make a
single practical analysis-plan decision rather than at a
methodologist seeking a new estimator. That integration, presented
pedagogically with a corrected and completed simulation (per §4a), is
a genuine and publishable contribution; presented as new methodology,
it is largely confirmatory of Chu (2011) and Islam and Bangdiwala
(2024) and would likely draw exactly that comparison from a referee.

**(c) Implications of the recommended framing.**
*Title:* shift from a general "Statistical Issues in..." title toward
something explicitly integrative/practical, e.g., "A Unified
Simulation-Based Guide to Site-Effect Modeling Choices in Multicenter
RCTs," signaling synthesis rather than new method.
*Abstract/Introduction:* lead with the practical decision a trialist
faces (which of three site-handling strategies to pre-specify in the
statistical analysis plan) rather than positioning the paper against
the theoretical literature as though closing an open question; state
explicitly, citing Islam and Bangdiwala (2024) and Chu et al. (2011),
that the qualitative conclusions replicate prior simulation work, and
that the paper's contribution is the integrated design plus the
audited, reproducible simulation harness.
*Comparators:* no additional analytic methods are strictly required
under this framing, but completing random slopes (item 11) would
substantially strengthen the interaction section, which currently
analyzes a misspecified model for its own generating mechanism —
this is the one place where the tutorial framing still needs a
method the paper does not yet have.
*Target journal:* move toward *Contemporary Clinical Trials
Communications*, *Trials*, or the "Tutorial" article type at
*Statistics in Medicine*, rather than a methods-forward submission to
*Biometrics* or *JCGS*, where the standard for genuine methodological
novelty is higher than this simulation currently clears.
*De-emphasize/move to supplement:* the extensive per-issue literature
review (currently four full subsections in the Introduction) could be
tightened in the main text and the more granular citation-by-citation
detail moved to a supplementary annotated bibliography, freeing space
in the main text for the corrected Methods disclosures required by
M4-M6 and for a fuller worked-example discussion aimed at the
practitioner audience implied by this framing.

## 6. Assessment

**Verdict: major revision**, prior to any consideration of framing.
This assessment is independent of §5's framing recommendation — the
correctness issues in §2 (M1-M7) would need to be resolved under
*any* framing before the paper could be evaluated on its merits. Two
of the seven major issues (M3, M5) are verified by direct code
execution or arithmetic recomputation performed during this review,
not merely inspected; the rest (M1, M2, M4, M6, M7) are verified by
direct inspection of file timestamps, code content, and rendered
table/text content, respectively. None of the major issues rest on
inference alone. The most consequential of these for the paper's
scientific claims is M3 (silently absorbed singular fits), because it
means the paper's own convergence-rate headline statistic — offered as
evidence the random-effects model is reliable — cannot currently
distinguish a clean converged fit from a degenerate boundary
estimate, in exactly the σ²_α = 0 scenarios the paper itself
simulates. M4 (no null arm) is the most consequential for the paper's
framing, since it means the paper cannot currently make a Type I
error claim, which is the central concern in the stratification-
adjustment literature it engages. This review did not run the full
R = 1,500 × 16-scenario × 3-method simulation itself (the cached
result in `analysis/report/cache/` was inspected only for staleness,
not re-executed at scale); the specific numeric values reported in
the Results section (Table 1, and the headline power/coverage/bias
figures) are therefore unverified by this review beyond the targeted
diagnostic runs reported in M3 and M5, and should be treated as
inspected/asserted, not independently confirmed, until the report is
re-rendered per item (a)(5).

## 7. Revision history

- 2026-08-13: Initial review. Seven major issues identified: stale
  compiled PDF relative to current `.Rmd` source (M1); a self-audit
  appendix that misrepresents already-implemented remediations while
  omitting newly identified gaps (M2); silent absorption of singular/
  boundary `lmer` fits as "converged," verified empirically at a 53%
  singular rate in the σ²_α = 0 scenario (M3); absence of any
  null-hypothesis (δ = 0) simulation arm, precluding Type I error
  claims (M4); an arithmetic error in the Monte Carlo SE-based
  sample-size justification, verified by recomputation (M5); an
  undocumented and internally inconsistent choice of reference
  distribution between the paper's p-values (t, ad hoc df) and
  coverage (z, fixed 1.96) across all three methods (M6); and a
  headline claim that Table 1 reports Monte Carlo SEs for every
  estimate, when the displayed table omits all MCSE columns (M7).
  Eight minor issues identified, largely reproducibility and citation
  gaps. Recommended framing: reposition from a methods-novelty
  contribution toward an integrative, pedagogically framed simulation
  study, since the qualitative findings substantially replicate
  Chu et al. (2011) and Islam and Bangdiwala (2024). Overall verdict:
  major revision.
