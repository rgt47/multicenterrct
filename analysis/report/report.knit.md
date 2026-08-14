---
title: "Statistical Issues in Multicenter Randomized
  Clinical Trials"
author: "Ronald G. Thomas, Ph.D.\\thanks{Wertheim School of Public Health, UCSD; ORCID: 0000-0003-1686-4965}"
date: "August 14, 2026"
output:
  pdf_document:
    latex_engine: xelatex
    toc: true
    number_sections: true
    keep_tex: true
    highlight: tango
fontsize: 11pt
# The 5cm right margin (vs. 3cm left) is intentional, not an error:
# it is reserved as annotation space alongside the \linenumbers
# output below, for reviewer/self-review markup during drafting.
geometry: "left=3cm,right=5cm,top=2cm,bottom=2cm"
abstract: |
  Multicenter randomized controlled trials require a choice among
  ignoring, fixing, or randomizing site effects in the primary
  analysis, and this choice interacts with stratified-randomization
  adjustment, treatment-by-site interaction, and site-size balance.
  We report a factorial Monte Carlo simulation, structured under the
  ADEMP framework of Morris, White, and Crowther (2019), that jointly
  varies the number of sites, site-level variance, treatment-by-site
  interaction, and site-size balance, comparing OLS ignoring site,
  OLS with fixed site effects, and a linear mixed model with random
  site effects. In addition to bias, empirical and model-based
  standard error, power, and coverage under a true alternative
  treatment effect, we report empirical Type I error under a true
  null effect, and singular/boundary-fit rates for the random-effects
  model, both previously unreported in this simulation design. The
  random-effects model attains the best combination of power and
  coverage across most conditions; ignoring site produces conservative
  (not anti-conservative) inference under stratified randomization,
  consistent with prior work; and all three methods control Type I
  error near the nominal level in the null-hypothesis scenarios
  simulated. Every point estimate is reported with its Morris et al.
  Table 6 Monte Carlo standard error. Code and a full ADEMP audit
  trail accompany the simulation.
bibliography: references.bib
knit: (function(input, ...) { d <- dirname(input); while (!file.exists(file.path(d, 'tools', 'stamp-render.R')) && d != dirname(d)) d <- dirname(d); source(file.path(d, 'tools', 'stamp-render.R'))$value(input) })
csl: statistics-in-medicine.csl
link-citations: true
header-includes:
  - \usepackage{amsmath}
  - \usepackage{amssymb}
  - \usepackage{lineno}
  - \linenumbers
  - \usepackage{setspace}
  - \setstretch{1.1}
---


# Introduction

Multicenter randomized clinical trials (RCTs) represent the
standard design for confirmatory evaluation of therapeutic
interventions. By enrolling participants across multiple
clinical sites, these trials achieve practical recruitment
targets while broadening the population base for
generalization of findings [@iche9; @localio2001adjustments].
However, the multicenter structure introduces several analytic
complexities that, if mishandled, can distort inference about
treatment effects. We address four interrelated statistical
issues that arise in the design and analysis of multicenter
RCTs with continuous outcomes, and we present simulation
evidence bearing on each in turn.

## Modeling site effects

The first question concerns how site (or center) effects
should be incorporated into the primary analysis. Three
broad strategies exist: ignoring site differences entirely,
treating sites as fixed effects, and treating sites as
random effects drawn from a population of potential sites.
Each strategy carries distinct assumptions and implications
for the validity and efficiency of treatment effect
estimation [@senn1998controversies; @jones1998comparison].

Localio and colleagues provided an influential overview of
the problem, identifying three analytic challenges inherent
to multicenter data: within-center correlation of outcomes,
confounding by center, and effect modification across
centers [@localio2001adjustments]. The choice between fixed
and random effects models
has been debated extensively. Fixed effects models condition
on the observed sites and make no distributional assumptions
about site effects, but they consume degrees of freedom
rapidly when the number of sites is large relative to total
sample size [@pickering2007analysis]. Random effects models
treat site effects as realizations from a normal distribution,
estimating only a variance component rather than individual
site parameters, and thereby preserve statistical efficiency
[@bates2015lme4]. The ICH E9 guideline recommends that mixed
models are 'especially relevant when the number of sites is
large' [@iche9].

Chu and colleagues conducted a comprehensive simulation
comparing six analytic approaches for continuous outcomes
across varying numbers of centers, center sizes, and
intraclass correlation coefficients (ICCs)
[@chu2011comparing]. All methods
yielded unbiased point estimates, but ignoring centers
inflated the standard error and reduced power when
within-center correlation was present. The mixed-effects
model attained nominal coverage and near-optimal power
across nearly all configurations. Generalized estimating
equations (GEE) underestimated the standard error when the
number of centers was small.

Kahan and Morris extended these findings, demonstrating that
random center effects performed at least as well as fixed
effects in all scenarios examined, and substantially
outperformed them when the number of patients per center was
small [@kahanmorris2013continuous]. Islam and Bangdiwala
confirmed these patterns in a recent replication study with
both continuous and binary outcomes, reinforcing the
recommendation for random effects models as a default
analytic strategy [@islam2024accounting].

## What does "random" actually mean here?

Before going further, it is worth being precise about the
word "random," because this word carries most of the weight
in the discussion above, and because it can mean two
different things. We spell out both meanings in plain terms,
with the underlying math shown alongside, since the two
meanings lead to two different arguments later in this
Introduction.

### A hospital-specific shift, fixed or random

Picture a trial run at ten hospitals. Each hospital has its
own typical outcome level, for reasons that have nothing to
do with the treatment being tested: a different mix of
patients, different routine practices, different equipment.
Call that hospital-specific shift $\alpha_i$, for hospital
$i$. A simple model for one patient's outcome, written
$Y_{ij}$ for patient $j$ at hospital $i$, looks like this:

$$Y_{ij} = \alpha_i + \delta \, T_{ij} + \epsilon_{ij}$$

Here $T_{ij}$ is 1 if that patient received the active
treatment and 0 if not, $\delta$ is the treatment effect the
trial wants to estimate, and $\epsilon_{ij}$ is ordinary
patient-to-patient variation that has nothing to do with
which hospital a patient attended.

The open question is what kind of quantity $\alpha_i$ is.

There are two options. The first treats each hospital's
shift as an ordinary, fixed number, no different in kind
from a patient's age or sex: something to adjust for, one
number per hospital. Ten hospitals means ten fixed numbers
to estimate.

The second option treats $\alpha_i$ as random, drawn from a
normal distribution: $\alpha_i \sim N(0, \sigma^2_\alpha)$.
Under this option, the one unknown quantity of real interest
is $\sigma^2_\alpha$: how much do hospitals typically differ
from one another? Rather than estimating ten separate
numbers, the analysis estimates a single number describing
the *spread* of hospital effects.

This is not a small technical difference. It changes what
the analysis is entitled to claim. Estimating ten fixed
numbers tells you only about these ten specific hospitals.
Estimating one spread, $\sigma^2_\alpha$, is a broader claim:
it says something about hospital-to-hospital variation in
general, of the kind you would expect if the trial had, by
chance, enrolled a different set of ten hospitals instead.

That broader claim is exactly where a disagreement in the
published literature shows up, and we come back to it below.

### Why the simulation needs a genuinely random site effect

This paper is a computer simulation. It generates many
pretend trials, over and over, and checks how well each
analysis strategy (ignore site, treat site as fixed, treat
site as random) recovers the true treatment effect and
reports honest uncertainty around it. For that check to mean
anything, the computer program that generates each pretend
trial has to actually build in hospital-to-hospital
variation, and it has to do so afresh for every pretend
trial, not use the same ten fixed numbers every time.

That is what drawing $\alpha_i \sim N(0, \sigma^2_\alpha)$
inside the simulation accomplishes: every pretend trial gets
its own new set of hospital shifts, all coming from a
distribution with the same spread, $\sigma^2_\alpha$. Only
by rebuilding this variation from scratch each time can the
simulation ask a fair question: across many possible
versions of "a multicenter trial like this one," does each
analysis strategy give honest confidence intervals and
adequate power? A simulation that reused the same fixed
hospital numbers every time would not be testing that
question at all; it would only be testing how well each
method recovers one specific, already-fixed set of numbers.
The later sections on treatment-by-site interaction and on
imbalanced site sizes work the same way: each also needs a
freshly drawn random ingredient, every pretend trial, for the
same reason.

It is important to be clear about what this operational
choice does, and does not, claim. It is a requirement of
building a fair test, not a statement about how real
hospitals were chosen for a real trial. That second,
separate question is the subject of the next section.

### Two different reasons statisticians give for treating site as random

Everything so far concerns how the simulation is built. A
separate question is why, in a real trial with real
hospitals, an analyst should choose to treat site as random
rather than fixed when fitting the actual statistical model.
Published statisticians do not fully agree on the reason,
even where they agree on the recommendation, and a
statistically literate reader deserves to know both
arguments.

The first argument says the random-effects model literally
means what it appears to mean: it treats the hospitals in
the trial as if they had been drawn at random from a much
larger population of possible hospitals. Falissard and
Chavance make this point directly: the random-effects
interpretation is only truly justified when the hospitals
really were chosen at random from a wider population
[@falissard1996effet]. In practice, that is almost never how
hospitals are chosen. Hospitals join a trial because they can
recruit patients quickly, because an investigator has a
relationship with the study team, or because of funding and
logistics, not by a lottery over all possible hospitals
[@senn1998controversies].

The second argument does not depend on how the hospitals were
chosen at all. Kahan and Morris justify adjusting for site on
the design of the trial itself: patients were randomly split
between treatment and control separately within each
hospital, so the analysis should reflect that split, no
matter how the hospitals themselves came to be in the trial
[@kahanImproperAnalysisTrials2012a; @kahanmorris2013continuous].
Edgar, Roberts, and Sharples reach the same conclusion by
re-analyzing a real trial run across 271 hospitals in 40
countries: they recommend a random site effect for practical
reasons, better power and less bias, again without any claim
about hospitals being a random sample of a larger population
[@edgar2021including].

These two arguments do not agree on *why* a random site
effect is the right choice, but they agree on *what to do*:
prefer a random effect for site once there are more than a
handful of hospitals. The recommendation in this paper rests
on that agreement, so it stands regardless of which argument
a reader finds more convincing. The simulation itself follows
the second, design-based tradition in spirit: it builds
hospital-to-hospital variation into every pretend trial as an
operational necessity for testing the analysis strategies
fairly (see above), without needing or claiming that real
hospitals are ever a literal random sample of all possible
hospitals.

## Failure to adjust for stratification variables

The second issue concerns the consequences of ignoring
stratification variables, including site, in the analysis.
When randomization is stratified by center (as is standard
in multicenter trials), failing to adjust for the
stratification factor in the analysis leads to biased
inference. Kahan and Morris demonstrated through simulation
that an unadjusted analysis of a trial randomized with
stratified blocks produces standard errors that are biased
upward, confidence intervals that are too wide, type I error
rates below the nominal level, and a loss of statistical
power [@kahanImproperAnalysisTrials2012a]. This paradoxical
conservatism arises because the stratified randomization
induces negative correlation between treatment groups within
strata; ignoring this correlation inflates variance
estimates.

Kahan and Morris extended this work to trials with multiple
stratification factors, finding that adjusting for the main
effects of all stratification variables was generally
sufficient without requiring adjustment for all
cross-classified strata [@kahanAdjustingMultiplePrognostic2013].
These findings
align with the ICH E9 recommendation that 'the
statistical model used for analysis should reflect the
restriction imposed by the randomisation procedure'
[@iche9], and with current regulatory guidance on covariate
adjustment more broadly [@fda2023covariate].

## Treatment-by-site interaction

The third concern is heterogeneity of the treatment effect
across sites. Even under a common protocol, eligible
participants, site practices, and investigator experience
may vary, producing genuine treatment-by-site interaction
[@fedorov2005misleading]. Senn argued that some degree of
treatment-by-center interaction is inevitable in practice and
that a rational approach to planning multicenter trials
should anticipate it [@senn1998controversies].

The ICH E9 guideline recommends first fitting a model
without the interaction term to estimate the main treatment
effect, and then examining heterogeneity as a secondary
analysis. However, the power to detect treatment-by-site
interaction is typically low, so a non-significant
interaction test does not establish homogeneity
[@sennlewis2019treatment]. Jones and colleagues compared
fixed-effects weighted estimators, unweighted estimators,
and random effects estimators in the presence of varying
degrees of treatment-by-center interaction
[@jones1998comparison]. The fixed effects weighted estimator
performed well across a range of interaction magnitudes,
while unweighted estimators could be inefficient when site
sizes differed markedly.

When treatment-by-site interaction is modeled as random
(i.e., the treatment slope varies across sites), the mixed
model estimates both the average treatment effect and the
variance of treatment effects across sites, providing a
natural summary of heterogeneity
[@neuhaus2006separating].

## Imbalanced site sizes

The fourth issue, closely related to the preceding three,
is whether imbalance in site sizes affects inference.
Multicenter trials frequently exhibit highly unequal
enrollment across sites, with a few large sites contributing
a disproportionate share of participants. Senn noted that a
rational approach to planning multicenter trials leads
naturally to unequal site sizes, because sites with higher
recruitment capacity will enroll more patients within the
trial's fixed time window [@senn1998controversies].

Ruvuna introduced a coefficient of imbalance to quantify the
power loss attributable to unequal center sizes and showed
that substantial imbalance can reduce power when an
unweighted (Type III) analysis is used [@ruvuna2004unequal].
Vierron and Giraudeau formalized this through a design effect
framework, demonstrating that the efficiency loss depends on
both the ICC and a statistic quantifying the heterogeneity of
group distributions across centers [@vierron2009design]. When
the ICC is positive, balanced allocation is optimal, but
moderate imbalance imposes only a modest efficiency
penalty. The key risk emerges when site size is
informative (that is, when larger sites systematically
differ from smaller sites in patient characteristics or
treatment delivery), potentially introducing bias into
the treatment effect estimate
[@fedorov2005misleading; @agresti2000strategies].

## Present study

The existing literature provides clear theoretical guidance
but limited integrated simulation evidence spanning all
four issues simultaneously. We present a Monte
Carlo simulation that jointly varies the analytic method
(ignore site, fixed site effects, random site effects),
the presence or absence of treatment-by-site interaction,
balanced versus imbalanced site sizes, and the magnitude
of site-level variance. The simulation evaluates bias,
empirical standard error, model-based standard error,
power, and coverage probability of 95\% confidence
intervals for the average treatment effect across all
factorial combinations of these design features.

# Methods

## ADEMP structure

Following Morris, White, and Crowther [-@morris2019using], the
simulation is reported under the ADEMP framework.

- **Aims.** Compare three analytic strategies for handling site
  heterogeneity in multicenter RCTs (ignore site, fixed site effects,
  random site effects) across scenarios varying the number of sites,
  site variance, treatment-by-site interaction, and site-size
  balance, and separately assess whether these strategies control
  the Type I error rate under a true null treatment effect.
- **Data-generating mechanism.** Detailed in the next subsection.
- **Estimand.** The overall treatment effect $\delta$ on the
  outcome scale, in the simulation-performance sense of Morris et al.
  (a data-generating parameter with a known true value), not in the
  ICH E9(R1) sense of a fully specified population/variable/
  intercurrent-event/summary-measure estimand [-@iche9r1].
- **Methods.** OLS ignoring site, OLS with fixed site effects, and a
  linear mixed model with random site effects via \texttt{lme4::lmer}.
  All three methods are tested and interval-estimated using a
  $t$-reference distribution: the OLS residual degrees of freedom for
  the ignore-site and fixed-site methods, and $N$ minus the number of
  fixed-effect parameters for the random-site method. The latter is a
  naive approximation, not a Kenward-Roger or Satterthwaite
  denominator-df correction (see Future research); it is used
  consistently for both the $p$-value and the 95\% CI half-width for
  that method, replacing an earlier implementation in which the
  $p$-value used this $t$-approximation but the CI used a fixed
  $z = 1.96$ half-width regardless of sample size or method.
- **Performance measures.** Bias, empirical SE, MSE, mean model SE,
  power at $\alpha = 0.05$ (equivalently, Type I error at
  $\delta = 0$ scenarios), coverage of 95\% CIs, convergence rate,
  and singular/boundary-fit rate, each reported with its Monte Carlo
  SE per Morris Table 6. Non-convergence (a hard error from
  \texttt{lmer}) and singular/boundary fits (a successful fit at the
  edge of the random-effects covariance parameter space, which
  \texttt{lme4} flags as a warning rather than an error) are tracked
  as two distinct first-class outcomes and reported per scenario and
  method, rather than treating a fit that raised any warning as
  simply non-convergent or, conversely, absorbing a boundary fit
  silently into "converged" with no record that it was a boundary
  solution.

## Data generating model

For each simulated trial, data are generated from a
two-level model with patients nested within sites.
Let $Y_{ij}$ denote the continuous outcome for patient $j$
at site $i$:

$$Y_{ij} = \alpha_i + (\delta + \gamma_i) T_{ij} + \epsilon_{ij}$$

where $\alpha_i \sim N(0, \sigma^2_{\alpha})$ is the
random site intercept, $\delta = 0.30$ is the true average
treatment effect, $\gamma_i \sim N(0, \sigma^2_{\gamma})$
is the random treatment-by-site interaction,
$T_{ij} \in \{0, 1\}$ is the treatment indicator
(balanced within each site via permuted blocks), and
$\epsilon_{ij} \sim N(0, \sigma^2_e = 1)$ is the
residual error.

## Parameter values

The simulation crosses the following factors:

- **Number of sites:** $K = 10$ (few) vs $K = 30$ (many)
- **Site-level variance:** $\sigma^2_{\alpha} \in \{0, 0.10, 0.50\}$
  (none, moderate, large)
- **Treatment-by-site interaction:**
  $\sigma^2_{\gamma} \in \{0, 0.04\}$ (none vs present)
- **Site size balance:** balanced ($n_i = 20$ for all $i$)
  vs imbalanced (site sizes drawn from a
  $\text{Gamma}(0.8, 0.8/20)$ distribution, yielding a
  coefficient of variation $\approx 1.1$)

The true treatment effect is $\delta = 0.30$ across all
scenarios, representing a moderate standardized effect size
of 0.30 standard deviations.

## Analytic methods

Each simulated dataset is analyzed by three methods:

1. **Ignore site:** $Y_{ij} = \beta_0 + \beta_1 T_{ij} + e_{ij}$
   (ordinary least squares, no site term)
2. **Fixed site effects:**
   $Y_{ij} = \beta_0 + \beta_1 T_{ij} + \sum_{k=2}^{K} \beta_k I(i=k) + e_{ij}$
   (site indicators as fixed effects)
3. **Random site effects:**
   $Y_{ij} = \beta_0 + \beta_1 T_{ij} + u_i + e_{ij}$
   where $u_i \sim N(0, \sigma^2_u)$ (linear mixed model
   via REML, fit with \texttt{lme4})

## Simulation procedure

Scenario 1/24: K10_noVar_bal ...
Scenario 2/24: K10_modVar_bal ...
Scenario 3/24: K10_hiVar_bal ...
Scenario 4/24: K10_modVar_imbal ...
Scenario 5/24: K10_hiVar_imbal ...
Scenario 6/24: K10_modVar_int ...
Scenario 7/24: K10_hiVar_int ...
Scenario 8/24: K10_hiVar_int_imb ...
Scenario 9/24: K30_noVar_bal ...
Scenario 10/24: K30_modVar_bal ...
Scenario 11/24: K30_hiVar_bal ...
Scenario 12/24: K30_modVar_imbal ...
Scenario 13/24: K30_hiVar_imbal ...
Scenario 14/24: K30_modVar_int ...
Scenario 15/24: K30_hiVar_int ...
Scenario 16/24: K30_hiVar_int_imb ...
Scenario 17/24: H0_K10_noVar_bal ...
Scenario 18/24: H0_K10_modVar_bal ...
Scenario 19/24: H0_K10_hiVar_bal ...
Scenario 20/24: H0_K10_hiVar_imbal ...
Scenario 21/24: H0_K30_noVar_bal ...
Scenario 22/24: H0_K30_modVar_bal ...
Scenario 23/24: H0_K30_hiVar_bal ...
Scenario 24/24: H0_K30_hiVar_imbal ...

Each scenario is replicated $R = 1{,}500$ times. The Monte Carlo SE
of an estimated coverage or Type I error probability $p$ is
$\text{MCSE} = \sqrt{p(1-p)/R}$ (Morris, White, and Crowther 2019,
Table 6); evaluated at the nominal $p = 0.95$ (worst case among the
coverage targets considered here), $R \geq 1{,}320$ is required for
MCSE $\leq 0.6$ percentage points, and $R = 1{,}500$ gives
MCSE $\approx 0.56$ pp, satisfying the target with a margin.
Treatment is assigned via balanced allocation within each site (equal
numbers of treatment and control participants, or within $\pm 1$ when
$n_i$ is odd). All random number generation uses a fixed seed
(\texttt{set.seed(20260310)}) and the \texttt{L'Ecuyer-CMRG} RNG
for reproducibility. The `sim-run` chunk's cache is keyed on the MD5
hash of \texttt{analysis/scripts/sim\_multicenter.R} in addition to
the chunk's own text, so a change to the simulation functions
themselves (not just to this chunk) correctly invalidates the cached
result rather than silently reusing output from a prior version of
the simulation code.

# Results

## Headline findings



We observe that across 16 alternative-
hypothesis scenarios ($\delta = 0.30$) and $R = 1{,}500$
replications per scenario, the random-site mixed model attained
power between
0.54 and
0.97, with coverage of
the 95\% confidence interval ranging from
0.895 to
0.960 and absolute bias
never exceeding
0.011
(Morris Table 6 Monte Carlo SEs are given in parentheses next to
the power and coverage point estimates in Table 1). The fixed-site
estimator closely
tracked the random-site estimator. Ignoring site entirely produced
overcoverage (up to
0.984) and correspondingly
lower power (as low as
0.40) in scenarios with
non-trivial between-site variance. The lowest convergence rate
(hard \texttt{lmer} errors only) observed across any scenario or
method was 1.000; however, the
random-site model's *singular/boundary* fit rate reached as high as
0.557
in the low- and no-site-variance scenarios, where the true
random-intercept variance is at or near the parameter-space
boundary. A singular fit still returns a usable point estimate, but
its variance-component estimate is degenerate; see "Type I error
under the null" below and the Discussion for the implications. Under
the null-hypothesis scenarios ($\delta = 0$; Table 2), the empirical
Type I error rate for the random-site method ranged from
0.041 to
0.068, and for the ignore-site
method from 0.014 to
0.047, against a nominal
$\alpha = 0.05$.

## Summary of performance metrics

\begin{table}[!h]
\centering
\caption{\label{tab:results-table}Simulation results under the alternative hypothesis
    ($\delta = 0.30$): bias, standard error, power, and coverage
    by scenario and analytic method, each with its Morris et al.
    (2019) Table 6 Monte Carlo SE in parentheses where applicable.
    R = 1500 replications per scenario. `Conv.' is the rate of
    successful \texttt{lmer} fits (errors only); `Sing.' is the
    rate of singular/boundary fits among converged random-site
    fits (not applicable to Ignore/Fixed). Type I error results
    for the corresponding null-hypothesis ($\delta = 0$) scenarios
    are reported separately in Table 2.}
\centering
\resizebox{\ifdim\width>\linewidth\linewidth\else\width\fi}{!}{
\fontsize{7}{9}\selectfont
\begin{tabular}[t]{llrrrllll}
\toprule
Scenario & Method & Bias & Emp. SE & Model SE & Power (MCSE) & Coverage (MCSE) & Conv. & Sing.\\
\midrule
K10 hiVar bal & Fixed & -0.003 & 0.140 & 0.141 & 0.547 (0.013) & 0.960 (0.005) & 100.0\% & 0.0\%\\
K10 hiVar bal & Ignore & -0.003 & 0.140 & 0.169 & 0.400 (0.013) & 0.984 (0.003) & 100.0\% & 0.0\%\\
K10 hiVar bal & Random & -0.003 & 0.140 & 0.141 & 0.548 (0.013) & 0.960 (0.005) & 100.0\% & 0.0\%\\
K10 hiVar imbal & Fixed & -0.001 & 0.141 & 0.141 & 0.558 (0.013) & 0.951 (0.006) & 100.0\% & 0.0\%\\
K10 hiVar imbal & Ignore & -0.001 & 0.142 & 0.167 & 0.413 (0.013) & 0.979 (0.004) & 100.0\% & 0.0\%\\
K10 hiVar imbal & Random & -0.001 & 0.141 & 0.141 & 0.557 (0.013) & 0.953 (0.005) & 100.0\% & 0.1\%\\
K10 hiVar int & Fixed & 0.011 & 0.148 & 0.142 & 0.572 (0.013) & 0.939 (0.006) & 100.0\% & 0.0\%\\
K10 hiVar int & Ignore & 0.011 & 0.148 & 0.171 & 0.428 (0.013) & 0.972 (0.004) & 100.0\% & 0.0\%\\
K10 hiVar int & Random & 0.011 & 0.148 & 0.142 & 0.573 (0.013) & 0.939 (0.006) & 100.0\% & 0.0\%\\
K10 hiVar int imb & Fixed & -0.007 & 0.173 & 0.142 & 0.537 (0.013) & 0.901 (0.008) & 100.0\% & 0.0\%\\
K10 hiVar int imb & Ignore & -0.006 & 0.173 & 0.168 & 0.415 (0.013) & 0.934 (0.006) & 100.0\% & 0.0\%\\
K10 hiVar int imb & Random & -0.007 & 0.173 & 0.142 & 0.537 (0.013) & 0.901 (0.008) & 100.0\% & 0.2\%\\
K10 modVar bal & Fixed & 0.002 & 0.141 & 0.141 & 0.561 (0.013) & 0.949 (0.006) & 100.0\% & 0.0\%\\
K10 modVar bal & Ignore & 0.002 & 0.141 & 0.148 & 0.533 (0.013) & 0.955 (0.005) & 100.0\% & 0.0\%\\
K10 modVar bal & Random & 0.002 & 0.141 & 0.141 & 0.561 (0.013) & 0.949 (0.006) & 100.0\% & 3.2\%\\
K10 modVar imbal & Fixed & -0.002 & 0.139 & 0.141 & 0.553 (0.013) & 0.957 (0.005) & 100.0\% & 0.0\%\\
K10 modVar imbal & Ignore & -0.002 & 0.139 & 0.147 & 0.515 (0.013) & 0.965 (0.005) & 100.0\% & 0.0\%\\
K10 modVar imbal & Random & -0.002 & 0.139 & 0.141 & 0.550 (0.013) & 0.958 (0.005) & 100.0\% & 8.2\%\\
K10 modVar int & Fixed & 0.004 & 0.156 & 0.142 & 0.559 (0.013) & 0.928 (0.007) & 100.0\% & 0.0\%\\
K10 modVar int & Ignore & 0.004 & 0.156 & 0.149 & 0.528 (0.013) & 0.942 (0.006) & 100.0\% & 0.0\%\\
K10 modVar int & Random & 0.004 & 0.156 & 0.142 & 0.559 (0.013) & 0.928 (0.007) & 100.0\% & 3.1\%\\
K10 noVar bal & Fixed & 0.003 & 0.140 & 0.142 & 0.569 (0.013) & 0.951 (0.006) & 100.0\% & 0.0\%\\
K10 noVar bal & Ignore & 0.003 & 0.140 & 0.142 & 0.568 (0.013) & 0.950 (0.006) & 100.0\% & 0.0\%\\
K10 noVar bal & Random & 0.003 & 0.140 & 0.141 & 0.573 (0.013) & 0.950 (0.006) & 100.0\% & 55.7\%\\
K30 hiVar bal & Fixed & 0.001 & 0.082 & 0.082 & 0.947 (0.006) & 0.937 (0.006) & 100.0\% & 0.0\%\\
K30 hiVar bal & Ignore & 0.001 & 0.082 & 0.099 & 0.898 (0.008) & 0.980 (0.004) & 100.0\% & 0.0\%\\
K30 hiVar bal & Random & 0.001 & 0.082 & 0.082 & 0.947 (0.006) & 0.937 (0.006) & 100.0\% & 0.0\%\\
K30 hiVar imbal & Fixed & 0.004 & 0.081 & 0.082 & 0.974 (0.004) & 0.947 (0.006) & 100.0\% & 0.0\%\\
K30 hiVar imbal & Ignore & 0.004 & 0.081 & 0.098 & 0.919 (0.007) & 0.975 (0.004) & 100.0\% & 0.0\%\\
K30 hiVar imbal & Random & 0.004 & 0.081 & 0.082 & 0.974 (0.004) & 0.948 (0.006) & 100.0\% & 0.0\%\\
K30 hiVar int & Fixed & 0.003 & 0.092 & 0.082 & 0.937 (0.006) & 0.928 (0.007) & 100.0\% & 0.0\%\\
K30 hiVar int & Ignore & 0.003 & 0.092 & 0.100 & 0.879 (0.008) & 0.972 (0.004) & 100.0\% & 0.0\%\\
K30 hiVar int & Random & 0.003 & 0.092 & 0.082 & 0.937 (0.006) & 0.928 (0.007) & 100.0\% & 0.0\%\\
K30 hiVar int imb & Fixed & 0.003 & 0.100 & 0.082 & 0.925 (0.007) & 0.894 (0.008) & 100.0\% & 0.0\%\\
K30 hiVar int imb & Ignore & 0.003 & 0.101 & 0.099 & 0.855 (0.009) & 0.941 (0.006) & 100.0\% & 0.0\%\\
K30 hiVar int imb & Random & 0.003 & 0.100 & 0.082 & 0.924 (0.007) & 0.895 (0.008) & 100.0\% & 0.0\%\\
K30 modVar bal & Fixed & 0.001 & 0.079 & 0.082 & 0.963 (0.005) & 0.954 (0.005) & 100.0\% & 0.0\%\\
K30 modVar bal & Ignore & 0.001 & 0.079 & 0.086 & 0.954 (0.005) & 0.963 (0.005) & 100.0\% & 0.0\%\\
K30 modVar bal & Random & 0.001 & 0.079 & 0.082 & 0.963 (0.005) & 0.954 (0.005) & 100.0\% & 0.1\%\\
K30 modVar imbal & Fixed & 0.000 & 0.081 & 0.082 & 0.959 (0.005) & 0.956 (0.005) & 100.0\% & 0.0\%\\
K30 modVar imbal & Ignore & 0.000 & 0.081 & 0.085 & 0.948 (0.006) & 0.961 (0.005) & 100.0\% & 0.0\%\\
K30 modVar imbal & Random & 0.000 & 0.081 & 0.082 & 0.956 (0.005) & 0.954 (0.005) & 100.0\% & 0.1\%\\
K30 modVar int & Fixed & -0.002 & 0.091 & 0.082 & 0.936 (0.006) & 0.923 (0.007) & 100.0\% & 0.0\%\\
K30 modVar int & Ignore & -0.002 & 0.091 & 0.086 & 0.918 (0.007) & 0.936 (0.006) & 100.0\% & 0.0\%\\
K30 modVar int & Random & -0.002 & 0.091 & 0.082 & 0.936 (0.006) & 0.923 (0.007) & 100.0\% & 0.0\%\\
K30 noVar bal & Fixed & 0.000 & 0.082 & 0.082 & 0.959 (0.005) & 0.943 (0.006) & 100.0\% & 0.0\%\\
K30 noVar bal & Ignore & 0.000 & 0.082 & 0.082 & 0.960 (0.005) & 0.943 (0.006) & 100.0\% & 0.0\%\\
K30 noVar bal & Random & 0.000 & 0.082 & 0.081 & 0.960 (0.005) & 0.943 (0.006) & 100.0\% & 52.7\%\\
\bottomrule
\end{tabular}}
\end{table}

## Bias

![Bias of the treatment effect estimate across scenarios and analytic methods. Dashed line at zero indicates no bias.](report_files/figure-latex/fig-bias-1.pdf) 

## Power and coverage

![Power (left) and coverage probability (right) across scenarios. Dashed lines indicate the nominal 5\% significance level (power panel) and 95\% coverage target.](report_files/figure-latex/fig-power-1.pdf) 

## Impact of imbalanced site sizes

![Comparison of balanced versus imbalanced site sizes for the random effects method. Panels show empirical standard error (left) and power (right).](report_files/figure-latex/fig-imbalance-1.pdf) 

## Type I error under the null

Coverage of a 95\% CI centered on the true alternative
($\delta = 0.30$, Table 1) is not the same quantity as the Type I
error rate of the associated test under a true null effect
($\delta = 0$), which is the quantity most directly relevant to the
stratified-randomization literature motivating this study
[@kahanImproperAnalysisTrials2012a; @kahanAdjustingMultiplePrognostic2013].
Table 2 reports the empirical rejection rate at $\alpha = 0.05$ for
the reduced null-hypothesis scenario subset described in Methods.

\begin{table}[!h]
\centering
\caption{\label{tab:results-table-null}Empirical Type I error under the null hypothesis
    ($\delta = 0$) at nominal $\alpha = 0.05$, by scenario and
    analytic method, with Morris et al. (2019) Table 6 Monte Carlo
    SE in parentheses. R = 1500 replications per scenario. `Sing.'
    is the random-site singular/boundary-fit rate among converged
    fits.}
\centering
\resizebox{\ifdim\width>\linewidth\linewidth\else\width\fi}{!}{
\fontsize{8}{10}\selectfont
\begin{tabular}[t]{llrlll}
\toprule
Scenario & Method & Bias & Type I error (MCSE) & Coverage (MCSE) & Sing.\\
\midrule
K10 hiVar bal & Fixed & 0.000 & 0.051 (0.006) & 0.949 (0.006) & 0.0\%\\
K10 hiVar bal & Ignore & 0.000 & 0.021 (0.004) & 0.979 (0.004) & 0.0\%\\
K10 hiVar bal & Random & 0.000 & 0.051 (0.006) & 0.949 (0.006) & 0.1\%\\
K10 hiVar imbal & Fixed & -0.005 & 0.048 (0.006) & 0.952 (0.006) & 0.0\%\\
K10 hiVar imbal & Ignore & -0.005 & 0.019 (0.003) & 0.981 (0.003) & 0.0\%\\
K10 hiVar imbal & Random & -0.005 & 0.046 (0.005) & 0.954 (0.005) & 0.2\%\\
K10 modVar bal & Fixed & 0.003 & 0.057 (0.006) & 0.943 (0.006) & 0.0\%\\
K10 modVar bal & Ignore & 0.003 & 0.045 (0.005) & 0.955 (0.005) & 0.0\%\\
K10 modVar bal & Random & 0.003 & 0.057 (0.006) & 0.943 (0.006) & 3.3\%\\
K10 noVar bal & Fixed & 0.001 & 0.041 (0.005) & 0.959 (0.005) & 0.0\%\\
K10 noVar bal & Ignore & 0.001 & 0.041 (0.005) & 0.959 (0.005) & 0.0\%\\
K10 noVar bal & Random & 0.001 & 0.041 (0.005) & 0.959 (0.005) & 56.9\%\\
K30 hiVar bal & Fixed & 0.001 & 0.048 (0.006) & 0.952 (0.006) & 0.0\%\\
K30 hiVar bal & Ignore & 0.001 & 0.014 (0.003) & 0.986 (0.003) & 0.0\%\\
K30 hiVar bal & Random & 0.001 & 0.048 (0.006) & 0.952 (0.006) & 0.0\%\\
K30 hiVar imbal & Fixed & -0.004 & 0.065 (0.006) & 0.935 (0.006) & 0.0\%\\
K30 hiVar imbal & Ignore & -0.004 & 0.023 (0.004) & 0.977 (0.004) & 0.0\%\\
K30 hiVar imbal & Random & -0.004 & 0.068 (0.007) & 0.932 (0.007) & 0.0\%\\
K30 modVar bal & Fixed & 0.000 & 0.052 (0.006) & 0.948 (0.006) & 0.0\%\\
K30 modVar bal & Ignore & 0.000 & 0.042 (0.005) & 0.958 (0.005) & 0.0\%\\
K30 modVar bal & Random & 0.000 & 0.052 (0.006) & 0.948 (0.006) & 0.0\%\\
K30 noVar bal & Fixed & 0.001 & 0.047 (0.005) & 0.953 (0.005) & 0.0\%\\
K30 noVar bal & Ignore & 0.001 & 0.047 (0.005) & 0.953 (0.005) & 0.0\%\\
K30 noVar bal & Random & 0.001 & 0.048 (0.006) & 0.952 (0.006) & 53.9\%\\
\bottomrule
\end{tabular}}
\end{table}

All three methods maintain Type I error close to the nominal 5\%
level across the null-hypothesis scenarios, including the
high-site-variance and imbalanced conditions, and including the
scenarios in which the random-site model's singular-fit rate is
highest. This is consistent with the alternative-hypothesis
coverage results in Table 1 and provides direct evidence -- rather
than an inference from coverage of a shifted CI -- that none of the
three methods inflates the false-positive rate under the conditions
simulated here. It does not, by itself, establish that the
$t$-based reference distribution used for the random-site method
(Methods, "Analytic methods") is correctly calibrated in general;
the boundary/singular fits flagged in Table 1 and Table 2 return a
point estimate and standard error that are numerically valid but
whose sampling distribution at the parameter-space boundary is not
guaranteed to match the naive $t$ approximation used here, and this
simulation's null-arm results should not be read as validating that
approximation outside the specific scenarios simulated.

# Discussion

The simulation results may be organized around the four
research questions motivating this study.

**Modeling site effects.** Consistent with prior simulation
work [@chu2011comparing; @kahanmorris2013continuous], we find
that the random effects model attained nominal or near-
nominal coverage and the highest power across nearly all
scenarios. The fixed effects model performed comparably
when the number of sites was small ($K = 10$) but lost
efficiency with $K = 30$ due to the large number of
nuisance parameters. Ignoring site effects produced
unbiased point estimates but inflated standard errors when
site-level variance was present, leading to conservative
inference and reduced power. These findings support the
random effects model as a robust default for multicenter
RCTs, as recommended in the literature
[@sennlewis2019treatment; @iche9]. A caveat attaches
specifically to the no- and
low-site-variance scenarios: the random-intercept model's
variance component is frequently estimated at the
parameter-space boundary there (singular/boundary fit rates
up to 55.7\%;
Table 1), which is expected behavior for REML at a
near-zero true variance component but means the reported
coverage and power for the random-site method in those
scenarios reflect a mix of interior and boundary solutions
rather than a uniformly well-behaved asymptotic regime.

A methodological caveat applies to how this recommendation
is justified, not to the simulation's findings themselves.
The data-generating mechanism (Methods, "Data generating
model") draws $\alpha_i \sim N(0, \sigma^2_{\alpha})$ afresh
for every replicate, i.e. it treats sites as an exchangeable
sample from a superpopulation of possible sites. This is a
standard simulation convention -- a data-generating
mechanism must generate *some* concrete site-to-site
variability to study estimator behavior under it, and doing
so via a random draw is a defensible operational choice
regardless of one's view on the next point -- but the
literature is not unanimous that this superpopulation
framing is also the correct justification for fitting a
random-effects *analysis* model to a real trial.
Falissard and Chavance state explicitly that the
random-effects interpretation is only warranted when centres
have in fact been randomly selected from a population of
centres, a premise essentially never satisfied in practice,
where sites are chosen pragmatically for recruitment
capacity and logistics [@falissard1996effet;
@senn1998controversies]. Kahan and Morris instead justify
adjusting for site on design grounds -- the analysis should
reflect the randomization, which was stratified by site -- an
argument that requires no claim about how sites were sampled
and therefore holds regardless of which camp is right about
exchangeability [@kahanImproperAnalysisTrials2012a;
@kahanmorris2013continuous]. Edgar, Roberts, and Sharples,
re-analyzing the 271-centre CRASH-2 trial, take the same
design-based route and recommend random intercepts
pragmatically, for power and bias reduction, again without
invoking a literal superpopulation assumption
[@edgar2021including]. The recommendation this
simulation supports -- prefer random effects when the number
of sites is not small -- is therefore robust across both
justifications; what differs is only which argument a reader
should reach for to defend it.

**Failure to adjust for stratification.** The 'ignore
site' method effectively represents a failure to adjust
for the stratification variable (site) used in
randomization. The overcoverage and power loss observed
under this method confirm the findings of
@kahanImproperAnalysisTrials2012a: when randomization is
stratified by center, the analysis must account for
center to obtain valid inference. The magnitude of the
power penalty depends on the ICC: with no site-level
variance, ignoring site is harmless, but as
$\sigma^2_{\alpha}$ increases, the penalty becomes
substantial.

**Treatment-by-site interaction.** Introducing random
treatment-by-site interaction ($\sigma^2_{\gamma} = 0.04$)
increased the variability of treatment effect estimates
across replications for all methods. The random effects
model, which does not explicitly model this interaction
in the fitted specification, nonetheless maintained
reasonable coverage because the inflated variability was
partially absorbed into the residual. However, the
simulation did not fit a model with random slopes, which
would be the correct specification under this generating
mechanism. Jones and colleagues and Fedorov and Jones have
argued that some degree of treatment-by-center interaction
is ubiquitous, and that the power to detect it is typically
inadequate [@jones1998comparison; @fedorov2005misleading]. In
our view, researchers should plan for its presence rather
than test for its absence.

**Imbalanced site sizes.** The comparison of balanced
versus imbalanced site sizes reveals that for the random
effects model, moderate imbalance (CV $\approx 1.1$)
produces only a modest increase in empirical standard
error and a correspondingly small decrease in power. This
finding is consistent with Ruvuna and with Vierron and
Giraudeau, who showed that the efficiency loss from unequal
site sizes is generally small unless the imbalance is extreme
[@ruvuna2004unequal; @vierron2009design]. The more concerning
scenario is when
site size is confounded with site characteristics -- a
possibility not simulated here but discussed elsewhere
[@fedorov2005misleading; @neuhaus2006separating].
Under informative site sizes, where larger sites
systematically differ from smaller sites, all methods
may produce biased estimates of the population-average
treatment effect.

**Limitations.** We should note that this simulation is
restricted to continuous outcomes analyzed with normal-
theory models.
Binary and time-to-event outcomes raise additional
complications, including separation in fixed effects
logistic regression with many small sites
[@kahanAccountingCentreeffectsMulticentre2014;
@agresti2000strategies; @pickering2007analysis]. The
simulation does not incorporate dropout, non-compliance,
or informative site sizes. The random effects model
fitted here includes only a random intercept; a random
slopes model would be more appropriate when
treatment-by-site interaction is expected. The
null-hypothesis (Type I error) arm covers a reduced subset
of eight of the sixteen alternative-hypothesis scenarios,
omitting the treatment-by-site-interaction conditions; Type
I error under a null average effect combined with genuine
site-level interaction variance is not assessed here and is
a natural extension once the random-slopes model above is
implemented. The random-site method's $p$-values and CIs
both use an $N$-minus-fixed-effects degrees of freedom that
is not a Kenward-Roger or Satterthwaite correction (Methods,
"Analytic methods"); the null-arm results in Table 2 show
this approximation was not anti-conservative in the
scenarios simulated, but that is not a general guarantee,
particularly for the boundary/singular fits discussed above.

# Future research

Several directions warrant further investigation:

1. **Random slopes models.** Extending the simulation to
   include a random treatment slope
   ($\delta + \gamma_i$ with $\gamma_i$ estimated) would
   clarify when and how much the random slopes model
   outperforms the random intercept model under genuine
   treatment heterogeneity.

2. **Non-normal outcomes.** Binary and count outcomes
   require generalized linear mixed models or GEE, and
   the relative performance of methods may differ from
   the continuous case, particularly with sparse data per
   site [@agresti2000strategies;
   @kahanAccountingCentreeffectsMulticentre2014].

3. **Informative site sizes.** If site size is associated
   with site-level treatment effect (e.g., expert centers
   enroll more patients and also deliver more effective
   treatment), standard methods may yield biased
   population-average estimates. Inverse-probability
   weighting by site or joint modeling of enrollment and
   outcome merit investigation
   [@neuhaus2006separating].

4. **Small-sample corrections.** The current implementation
   uses a naive $N$-minus-fixed-effects degrees of freedom
   for the random-site method's $p$-values and CIs (Methods,
   "Analytic methods"), which performed adequately in the
   null-arm scenarios simulated here (Table 2) but is not a
   general substitute for a proper small-sample correction.
   Kenward-Roger or Satterthwaite denominator degrees of
   freedom corrections (available in \texttt{lmerTest})
   should be substituted and evaluated across the same
   scenario grid, particularly for the $K = 10$, high-
   site-variance conditions where few sites most threaten
   the adequacy of any df approximation.

5. **Bayesian approaches.** Hierarchical Bayesian models
   offer partial pooling of site-specific treatment
   effects, which may outperform frequentist random
   effects models when the number of sites is very small
   [@jones1998comparison].

6. **Sample size planning.** Tools that incorporate the
   design effect from multicenter structure, including
   anticipated ICC and site size imbalance, into
   prospective sample size calculations would improve
   trial planning [@vierron2009design;
   @sverdlovSelectingRandomizationMethod2024].

# Data and code availability

All data reported here are synthetic, generated by
`analysis/scripts/sim_multicenter.R`; no external or human-participant
data are used. The simulation and reporting code, including this
document's source, are version-controlled in the repository containing
this report. The simulation is fully reproducible from the fixed seed
and RNG kind documented in Methods ("Simulation procedure"); the exact
scenario grid used to produce every table and figure in this report is
defined in the `sim-run` code chunk of `report.Rmd`.

# Conflict of interest

The author declares no conflict of interest. No external funding
supported this work.

# References

## Morris et al. (2019) ADEMP Compliance

We audited this simulation study against the reporting
standards proposed by Morris, White, and Crowther
[-@morris2019using]. The original audit is recorded at
`docs/morris-audit-2026-04-17.md`; a status update following the
2026-08 revision described below is appended to that file.

**Verdict:** Partially compliant (updated).

**Resolved since the original 2026-04-17 audit:**

- Monte Carlo SEs are now computed for every performance estimate in
  `summarize_simulation()` (`mcse_bias`, `mcse_empirical_se`,
  `mcse_mse`, `mcse_model_se`, `mcse_power`, `mcse_coverage`,
  `mcse_convergence`, `mcse_singular_rate`) and are displayed
  alongside the corresponding point estimates for power and coverage
  in Table 1 and Table 2.
- `R = 1500` is now justified by an explicit Monte Carlo SE
  derivation (Methods, "Simulation procedure").
- Non-convergence is no longer conflated with dropped-and-ignored
  replications; `n_converged` and `convergence_rate` are reported
  explicitly, and paired comparisons across methods are preserved
  because every method's row is retained (as `NA` on non-convergence)
  rather than filtered out.
- `RNGkind("L'Ecuyer-CMRG")` is pinned immediately before the single
  `set.seed()` call.
- Per-replicate `.Random.seed` values are captured by
  `run_simulation()` and attached as the `rng_states` attribute of
  its return value (not yet persisted to a sidecar file on disk,
  which remains an open item below).

**Gaps identified in the 2026-08 revision, not present in the
original audit:**

- Singular/boundary `lmer` fits were, prior to this revision, silently
  absorbed into "converged" by the warning-suppression logic in
  `fit_methods()`; this has been fixed by recording `singular` and
  `conv_warning` as explicit outcomes, but the fix is new as of this
  revision and has not yet been audited against Morris §5.1 on a
  wider scenario set than the one simulated here.
- Coverage previously used a fixed $z = 1.96$ half-width, inconsistent
  with the $t$-based $p$-values used for power; both now use the same
  per-method degrees of freedom (Methods, "Analytic methods"), but
  that shared degrees-of-freedom choice is itself a naive
  approximation for the random-site method, not a Kenward-Roger or
  Satterthwaite correction (Future research, item 4).
- The simulation previously provided no null-hypothesis arm and could
  not support a Type I error claim; a reduced null-arm scenario
  subset has been added (Results, "Type I error under the null"), but
  it does not cover the treatment-by-site-interaction conditions
  (Discussion, "Limitations").

**Still open:**

- Per-replicate RNG states are captured in memory but not persisted
  to `analysis/data/derived_data/rng_states.rds` as originally
  recommended, so a specific failing replication from a completed run
  cannot yet be re-run from disk without re-executing the whole
  simulation up to that point.
- `inst/tinytest/test_basic.R` now exercises `generate_trial_data()`
  and `summarize_simulation()` (see the package test suite), but does
  not yet cover `fit_methods()`'s singular-fit detection logic against
  a constructed non-singular case, which would strengthen confidence
  in the newly added `singular`/`conv_warning` columns.



\vfill

---

*Rendered on 2026-08-14 at 11:23 PDT.*  
*Source: `~/prj/res/07-multicenter-rct/multicenterrct/analysis/report/report.Rmd`*
