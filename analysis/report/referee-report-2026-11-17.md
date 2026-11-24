# Referee Report: 'Statistical Issues in Multicenter Randomized Clinical Trials'
*2026-11-17 (date from `date +%Y-%m-%d`)*

Manuscript: `analysis/report/report.Rmd` (with
`analysis/scripts/sim_multicenter.R`, `references.bib`, and the most
recent rendered `report.tex`).

Evidence labels used below: **[verified]** means I executed code or
checked a primary source; **[inspected]** means I read the source or
rendered tables and judged them inconsistent; **[suspected]** means a
plausible concern I did not confirm. The numbers I cite come from the
last rendered `report.tex`. That render predates some prose edits in
the current Rmd, and I did not re-run the simulation.

## 1. Summary of the manuscript

The manuscript reports a Monte Carlo study of three analysis
strategies for a continuous outcome in a multicenter RCT: OLS
ignoring site, OLS with fixed site effects, and a random-intercept
linear mixed model. A random-slopes mixed model is added for the
treatment-by-site interaction scenarios. The design crosses the
number of sites (K = 10, 30), the site variance (0, 0.10, 0.50), the
treatment-by-site interaction variance (0, 0.04), and the site-size
balance, in 16 alternative-hypothesis scenarios. It adds 8
null-hypothesis scenarios. Each scenario uses R = 1,500 replications
and is reported under the ADEMP framework with Morris et al. Monte
Carlo SEs. The stated contributions are: (a) an integrated simulation
across four issues (site modeling, stratification adjustment,
interaction, and imbalance); (b) Type I error and singular-fit rates,
'previously unreported in this simulation design'; and (c) a
quantified trade-off for random slopes between higher coverage and
higher singular-fit rates. The headline conclusion is that the
random-intercept model is a sound default, and that ignoring site is
conservative under stratified randomization.

## 2. Overall assessment and recommendation

**Recommendation: major revision. In its present form the manuscript
does not reach the bar for a top-tier statistics journal.**

The simulation is carefully instrumented. MCSEs are reported, the
seed is handled correctly, non-convergence and singular fits are
tracked separately, and paired fitting is used. These are real
strengths. However, the substantive findings largely reproduce Chu et
al. (2011), Kahan and Morris (2012, 2013), and Islam and Bangdiwala
(2024). The contribution described as new is new only relative to
the authors' own earlier version ('this simulation design'). Several
Discussion claims are contradicted by the manuscript's own tables. One
figure is built from mislabeled data (verified). One quotation
attributed to ICH E9 does not appear in E9 (verified), and a second is
quoted out of context. The scenario grid also avoids the regimes in
which the methods are known to differ, namely small centers, many
sites, and low ICC. As a result, the central comparison is
uninformative by construction. A corrected and expanded version would
suit *Trials*, *Contemporary Clinical Trials*, or *Pharmaceutical
Statistics* as a tutorial-style simulation report. It is unlikely to
fit *Statistics in Medicine* without a sharper methodological
contribution.

## 3. Significance and novelty

- **Fixed versus random versus ignore, continuous outcome.** This
  question is covered by Chu et al. (2011, *BMC Med Res Methodol*
  11:21), Kahan and Morris (2013, *Stat Med* 32:1136), Pickering and
  Weatherall (2007, *Stat Med* 26:5445), and Islam and Bangdiwala
  (2024, *Trials* 25:390). The last of these explicitly simulates
  Type I and Type II error for ignore, fixed, and random center
  effects with continuous and binary outcomes. The present results
  (no bias, conservative ignore-site inference, and fixed close to
  random) agree with these papers and add no new regime.
- **Type I error under stratified randomization.** Kahan and Morris
  (2012, *Stat Med* 31:328) reported this result directly. The claim
  that Type I error was 'previously unreported in this simulation
  design' is self-referential. It is not a novelty claim relative to
  the literature.
- **Random slopes under interaction.** This is the most promising
  element. The trade-off between coverage, singular fits, and power
  is worth documenting. However, it is studied in only six scenarios.
  It uses an inappropriate df (Major 4), and it omits a power loss of
  up to 12 points (Major 3).
- **Contemporariness.** The manuscript does not engage with the
  modern covariate-adjustment and covariate-adaptive-randomization
  literature (Bugni, Canay and Shaikh 2018; Ye, Shao, Yi and Zhao
  2023; FDA 2023, which is cited only in passing). It also does not
  engage with the estimand literature for clustered designs, where
  the individual-average and cluster-average estimands differ under
  informative cluster size (Kahan et al. 2023). Nor does it engage
  with small-sample df methods for mixed models (Kenward and Roger
  1997; Luke 2017; McNeish and Stapleton 2016). A current referee
  would expect all three.

## 4. Major comments

**1. Figure 3 (`fig-imbalance`) is built from mislabeled scenarios.
[verified]**
The chunk classifies scenarios with `case_when(grepl('bal$', ...) ~
'Balanced', grepl('imbal$|imb$', ...) ~ 'Imbalanced')`. Because
`'imbal'` ends in `'bal'`, every `_imbal` scenario is labeled
'Balanced'. I ran the expression on the scenario labels.
`K10_modVar_imbal` and `K30_hiVar_imbal` both return 'Balanced', and
`str_remove` maps them to the same `base` as their balanced
counterparts. They are therefore pooled into the 'Balanced' bar. The
only 'Imbalanced' rows are the `_int_imb` scenarios. Their balanced
partners (`_int`) end in neither pattern, so they are dropped as
`NA`. The figure therefore compares nothing it claims to compare. The
Discussion paragraph on imbalanced site sizes cites this comparison.
(Its conclusion happens to be consistent with Table 1, where the
empirical SEs for bal and imbal are 0.140 versus 0.141 at K10 hiVar.)
*Remedy:* order the `case_when` conditions with the imbalance pattern
first, or match `'_bal$'` explicitly. Retain the `_int` scenarios as
'Balanced'. Then re-render and re-check the Discussion. The
2026-08-16 remediation log recorded this figure as audited with 'no
defects'. That audit checked only the caption against the panel
order.

**2. The Discussion contradicts Table 1 on fixed versus random
effects. [inspected]**
The Discussion says the fixed-effects model 'lost efficiency with
K = 30 due to the large number of nuisance parameters'. It also says
the random-effects model had 'the highest power across nearly all
scenarios'. In Table 1, fixed and random are identical or within
0.003 in every K = 30 scenario (for example, power 0.947 versus 0.947
in hiVar bal, and 0.974 versus 0.974 in hiVar imbal). Power differs
from fixed by more than 1 MCSE in no scenario. This is expected.
With 20 patients per site and allocation balanced within site,
treatment is orthogonal to site. The fixed model loses only K - 1
residual df out of about 600, and the GLS and OLS estimators nearly
coincide. *Remedy:* state that fixed and random were
indistinguishable throughout this grid. Explain that this follows
from the design (Major 5), and remove the efficiency-loss claim.

**3. The random-slopes findings omit a substantial power loss.
[inspected]**
Table 3 shows random-slope power of 0.456 versus 0.573 (K10 hiVar
int), 0.417 versus 0.537 (K10 hiVar int imb), and 0.446 versus 0.559
(K10 modVar int). These are losses of about 11 to 12 points, or
roughly 9 MCSEs. The abstract, the Results prose, and the Discussion
describe the trade-off as coverage versus singular-fit rate only. A
coverage gain bought with a wider interval and a loss of power is the
expected behavior of a correctly specified model. However, the
reader needs both halves of the trade-off. *Remedy:* report the
power change alongside the coverage change in the abstract, Results,
and Discussion. Add mean model SE to Table 3.

**4. Inference for both mixed models uses df = N - p, which is not
defensible for a site-level random slope. [inspected]**
For the random-slope model, the treatment effect's precision is
governed by the between-site variance of the slopes. The relevant
reference df is therefore of order K - 1 (9 or 29), not N - 2 (about
198 or 598). The manuscript acknowledges that the df is naive, but it
still reports coverage and power comparisons that depend directly on
it. The random-slope coverage figures are probably optimistic at
K = 10 [suspected]. The random-slope power is not comparable across
methods, because no null arm exists for that method. *Remedy:* refit
with Satterthwaite or Kenward-Roger df (`lmerTest`, `pbkrtest`) for
both mixed models. At minimum, add a K - 1 df sensitivity analysis.
Add null-arm scenarios with sigma_gamma^2 > 0 so that random-slope
power is interpretable.

**5. The scenario grid avoids the regimes in which the methods
differ. [inspected]**
The grid has n_i = 20 per site throughout, within-site balanced
allocation, K in {10, 30}, and ICC in {0, 0.09, 0.33}. Under these
conditions fixed and random must agree closely, so the main
comparison is uninformative by construction. The literature the
Introduction cites locates the differences elsewhere: small centers
with chance within-center imbalance (Pickering and Weatherall 2007;
Kahan and Morris 2013), many sites relative to N, and the low ICC
range (0.01 to 0.05) typical of real multicenter trials. ICC values
of 0.09 and 0.33 are high for this setting. The grid also lacks a
low ICC level between 0 and 0.09. *Remedy:* add small centers (for
example n_i in {2, 4, 6}) with simple rather than blocked allocation
within site. Add K in the 50 to 100 range and an ICC grid in the
0.01 to 0.05 range.

**6. The estimand under treatment-by-site interaction is not the
same across methods. [inspected]**
The ADEMP section defines the estimand as delta, the mean of the
super-population distribution of site-specific effects. Under
sigma_gamma^2 > 0, the fixed-site model targets a conditional,
weighted average over the K sampled sites. This is not delta.
Fixed-site 'undercoverage' in the interaction scenarios (for
example, 0.901 at K10 hiVar int imb) is therefore partly an estimand
mismatch rather than a method failure. With imbalanced sizes, the
individual-weighted and site-weighted averages also differ. The
Introduction's discussion of what 'random' means raises exactly this
question but never connects it to the performance measures. *Remedy:*
define the estimand for each method explicitly, following ICH E9(R1)
and Kahan et al. (2023). Evaluate the fixed-site method against its
own conditional target as well.

**7. The Type I error summary overstates calibration. [inspected]**
The text says all three methods 'maintain Type I error close to the
nominal 5% level'. Table 2 shows ignore-site at 0.014 to 0.023,
which is 5 to 10 MCSEs below nominal. That is markedly conservative,
which is the point of the stratification argument. It also shows
random-site at 0.068 (MCSE 0.007) and fixed-site at 0.065 in K30
hiVar imbal, about 2.5 MCSEs above nominal. With 24 cells some
excursions are expected. However, a correlated excursion for two
methods in the same scenario deserves comment, not summary as 'close
to nominal'. *Remedy:* describe ignore-site as conservative and
flag the K30 hiVar imbal excursion. Consider increasing R for that
cell or reporting a multiplicity-aware summary.

**8. Two ICH E9 quotations are inaccurate. [verified against the
ICH E9 PDF at the `.bib` URL]**
(a) The Introduction says 'the ICH E9 guideline recommends mixed
models as "especially relevant when the number of sites is large"'.
The E9 text (Section 3.2) reads: 'Mixed models may also be used to
explore the heterogeneity of the treatment effect. These models
consider centre and treatment-by-centre effects to be random, and are
especially relevant when the number of sites is large.' E9 refers to
models with random treatment-by-centre effects used to explore
heterogeneity. It does not recommend random-intercept models for the
primary analysis. The same section also states that, when centers
are small, 'it is not appropriate to include a term for centre in
the model'. That point bears directly on the manuscript's
recommendation. (b) The quotation 'the statistical model used for
analysis should reflect the restriction imposed by the randomisation
procedure' does not appear in E9. A text search of the guideline
found no such sentence. E9 instead says 'Factors on which
randomisation has been stratified should be accounted for later in
the analysis' (Section 2.3.2) and 'If one or more factors are used to
stratify the design, it is appropriate to account for those factors
in the analysis' (Section 5.7). *Remedy:* replace (b) with a verbatim
E9 sentence, and restate (a) in its original context.

**9. Text, code, and design descriptions disagree. [inspected;
CV verified by simulation]**
(a) The Methods state that allocation is 'balanced within each site
via permuted blocks'. The code performs a single random permutation
of a balanced 0/1 vector per site, `sample(rep(0:1, length.out =
n))`. This is complete within-site balance, not permuted blocks, and
the distinction matters for Kahan and Morris (2012). (b) Imbalanced
sizes are described as Gamma(0.8, 0.8/20) with 'CV about 1.1'. The
code then floors sizes at 4, rescales, rounds, and floors again. In
5,000 draws I obtained a realized mean CV of 0.95 (K = 10) and 1.02
(K = 30), and a total N that varies (mean about 201 and 602) rather
than being fixed at 200 and 600. (c) 'Present study' says the
simulation covers 'all factorial combinations of these design
features'. It covers 16 of the 24 cells in the stated factors. Per K, the missing cells are noVar imbalanced, noVar
with interaction (balanced and imbalanced), and modVar with
interaction and imbalance. (d) The ADEMP
'Methods' bullet says all four methods are fit 'via lme4::lmer'. The
first two use `lm`. *Remedy:* correct each description to match the
code, or change the code.

**10. Revision history and audit material sit in the manuscript.
[inspected]**
The manuscript contains phrases such as 'replacing an earlier
implementation in which the p-value used this t-approximation but the
CI used a fixed z = 1.96', 'is now fit', 'partially addressed', and
'the 2026-08 revision'. A full ADEMP self-audit with a dated change
log appears as a subsection under '# References'. In bookdown it
precedes the rendered bibliography. The abstract's novelty claims are
also framed relative to the earlier version. These are lab-notebook
content, not manuscript content. *Remedy:* move the audit and change
log to a supplement or the repository. Rewrite the Methods and
Future research in the present tense, describing the study as it now
stands.

## 5. Minor comments

1. *Introduction, stratification paragraph.* The mechanism is stated
   as stratified randomization 'induces negative correlation between
   treatment groups within strata'. With a shared site effect, the
   two arm means are positively correlated. The unadjusted variance
   formula ignores this covariance, which is what overstates
   Var(difference). Please check the direction against Kahan and
   Morris (2012). [suspected]
2. *Introduction, 'Two different reasons'.* The text states that the
   simulation 'follows the second, design-based tradition in spirit'.
   Yet the DGM draws alpha_i ~ N(0, sigma_alpha^2) afresh every
   replicate, which is the super-population model. The design-based
   argument would hold sites fixed and re-randomize treatment only.
   Possibly the authors mean something narrower; this could be
   clarified.
3. *Introduction, Edgar et al.* The paper reanalyzes CRASH-2, a trial
   with a binary outcome (death), using random center and country
   effects. The manuscript gives '271 hospitals in 40 countries' and
   attributes 'better power and less bias' to it. I could not confirm
   either from the abstract (CRASH-2 is usually described as 274
   hospitals). A binary-outcome reanalysis is weak support for a
   continuous-outcome recommendation. [suspected]
4. *Introduction.* The statement that random effects 'estimate only
   a variance component ... and thereby preserve statistical
   efficiency' cites Bates et al. (2015), a software paper. A
   methodological source (for example Brown and Prescott, or
   Kahan and Morris 2013) would be more appropriate.
5. *Treatment-by-site interaction.* The 'inevitable' claim is
   attributed to Senn (1998) in the Introduction, and the
   'ubiquitous' claim to Jones et al. (1998) and Fedorov and Jones
   (2005) in the Discussion. Please reconcile.
6. *Headline findings.* The singular-fit rate is described as
   reaching 0.557 'in the low- and no-site-variance scenarios'. The
   high rates (about 53 to 57%) occur only at sigma_alpha^2 = 0. The
   moderate scenarios show 0.1 to 8.2%.
7. *Introduction tone.* The subsection 'What does "random" actually
   mean here?' is written in a lay-tutorial register ('pretend
   trials', 'computer program', 'Picture a trial run at ten
   hospitals'). This register is not suited to a methods journal. The
   subsection is also long relative to its role.
8. *Heading.* Use single quotes or italics in 'What does "random"
   actually mean here?' for house style.
9. *Table 1.* The 'Conv.' column is 100.0% everywhere and carries no
   information. Consider moving it to the text. 'Sing.' for
   Ignore/Fixed is shown as 0.0% when it is not applicable; use '--'.
10. *Figures 1 and 2.* The x-axis labels are 5 to 6 pt at 45 degrees
    and will be illegible in print. Consider faceting by scenario
    factor instead.
11. *`fit_methods()`.* The `n_sites <= 50` branch for fixed effects
    is dead code in this grid. The warning handler refits the model a
    second time on any warning, which doubles cost for singular fits.
    `lmerControl(check.conv.singular = 'ignore')` would avoid this.
12. *Data availability.* 'Running `renv::restore()` ... recreates
    that environment exactly' overstates what renv controls (BLAS,
    compiler, and OS are outside it). The repository also provides a
    Dockerfile, which is more relevant here.
13. *Bibliography.* `iche9`: in 1998 the issuing body was the
    International Conference on Harmonisation. `falissard1996effet`
    lacks a DOI. `sennlewis2019treatment` is a JAMA Guide to
    Statistics and Methods piece; please label it as such.
14. *Methods.* 'A moderate standardized effect size of 0.30 standard
    deviations' is a standardized effect relative to sigma_e only.
    The total SD is larger when sigma_alpha^2 > 0. Please state which
    SD is meant.

## 6. Missing and questionable references

| Location | Issue | Suggested source |
|---|---|---|
| Intro, ICH E9 'restriction imposed by the randomisation' | Quotation not in E9 [verified] | ICH E9 (1998), Sections 2.3.2 and 5.7, verbatim text quoted in Major 8 |
| Intro, ICH E9 'especially relevant' | Quoted out of context [verified] | ICH E9 (1998), Section 3.2 |
| Methods, df choice; Future research item 4 | No df-method references | Kenward MG, Roger JH. Small sample inference for fixed effects from restricted maximum likelihood. *Biometrics* 1997;53:983-997. Luke SG. Evaluating significance in linear mixed-effects models in R. *Behav Res Methods* 2017;49:1494-1502. |
| Major 5, few clusters | No small-K reference | McNeish D, Stapleton LM. Modeling clustered data with very few clusters. *Multivariate Behav Res* 2016;51:495-518. |
| Major 6, estimands | No clustered-estimand reference | Kahan BC, Li F, Copas AJ, Harhay MO. Estimands in cluster-randomized trials: choosing analyses that answer the right question. *Int J Epidemiol* 2023;52:107-118. |
| Stratification section | Modern covariate-adaptive randomization theory absent | Bugni FA, Canay IA, Shaikh AM. Inference under covariate-adaptive randomization. *J Am Stat Assoc* 2018;113:1784-1796. Ye T, Shao J, Yi Y, Zhao Q. Toward better practice of covariate adjustment in analyzing randomized clinical trials. *J Am Stat Assoc* 2023;118:2370-2382. |
| Intro, Edgar et al. | Binary-outcome reanalysis used for a continuous-outcome claim; hospital count unconfirmed | Edgar K, Roberts I, Sharples L. *Trials* 2021;22:357 (verify counts) |
| Intro, random effects 'preserve efficiency' | Software paper cited for a methodological claim | Kahan BC, Morris TP. *Stat Med* 2013;32:1136-1149 |
| Intro, Islam and Bangdiwala | Correctly characterized (continuous and binary; Type I and II error) [inspected via abstract]; but it overlaps the novelty claim and should be engaged as such | Islam S, Bangdiwala SI. *Trials* 2024;25:390 |

I could not verify Falissard and Chavance (1996) (French, no DOI)
against the claim attached to it.

## 7. Suggestions for strengthening the paper

1. Recast the paper around the random-slope question, which is the
   genuinely open part. Use a full factorial over K, n_i, ICC, and
   sigma_gamma^2, with proper df methods and a null arm. Report the
   coverage, power, and singular-fit trade-off as the main result.
2. Add small-center and many-center scenarios, so that the
   fixed-versus-random comparison has a regime in which it can
   discriminate.
3. Add informative cluster size (site size correlated with gamma_i).
   This is the scenario the Introduction and Discussion flag as most
   concerning, and it requires only one extra line in the DGM.
4. Report interval width alongside coverage, so that coverage gains
   can be weighed against precision.
5. Add a tinytest that asserts the `fig-imbalance` classification
   for every scenario label. This would have caught Major 1.
6. Move the ADEMP audit and change log to a supplement, and keep the
   repository link in Data availability.

## 8. Scope of this review

- **Verified (executed or checked against a primary source):**
  - The `fig-imbalance` regex misclassification, by running the
    `case_when` and `str_remove` expressions in R on the scenario
    labels.
  - The realized CV and total N of the imbalanced site-size
    generator, by 5,000 draws of the code's own algorithm.
  - Both ICH E9 quotations, against the text of the E9 PDF at the
    URL in `references.bib`.
  - The MCSE arithmetic (R >= 1,320 for MCSE <= 0.6 pp at p = 0.95;
    0.56 pp at R = 1,500), which is correct.
- **Inspected:** every prose claim against Tables 1 to 3 in the last
  rendered `report.tex`; `sim_multicenter.R` against the Methods
  text; the bibliography entries.
- **Not checked:** I did not re-run the simulation or re-render the
  report. The table values may differ slightly from a fresh render.
  I did not read the full text of any cited paper. I did not check
  Falissard and Chavance (1996), Ruvuna (2004), Vierron and Giraudeau
  (2009), or Neuhaus and McCulloch (2006) against their attached
  claims.
- **Literature searches run:** (1) Edgar, Roberts and Sharples 2021,
  *Trials*, random centre effects, CRASH; (2) Islam and Bangdiwala
  2024, *Trials*, center-level effects simulation; (3) ICH E9
  treatment-by-centre interaction, mixed models, 'number of centres
  is large' (no primary hit; resolved by fetching the E9 PDF). The
  modern references in Section 6 come from my own knowledge of the
  literature and were not re-located by search in this session.
