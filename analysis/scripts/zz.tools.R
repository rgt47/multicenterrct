# Function to wrap long lines in an R file
wrap_long_lines <- function(file_path, output_file_path, width = 80){
  # Read the R file into a string
  r_code <- readLines(file_path)

  # Wrap the long lines
  wrapped_code <- strwrap(r_code, width = width)

  # Write the wrapped code to a new file
  writeLines(wrapped_code, output_file_path)

  # Print a success message
  print(paste("Wrapped long lines in", file_path, "and saved as", output_file_path))
}



prs <- function(ff) {
  g <- NULL
  y <- ff[[2]]
  form <- ff[[3]]
  if (length(form) > 2) {
    x <- form[[2]]
    gf <- form[[3]]
    if (length(gf) > 2) {
      g <- gf[[2]]
    } else {
      g <- gf
    }
  } else {
    x <- form
  }
  return(list(y = y, x = x, g = g))
}


zz.sum.min <- function(x, digits = 2) {
  x <- x[!is.na(x)]
  N <- length(x)
  Mean <- round(mean(x), digits)
  SD <- round(var(x)^.5, digits)
  Min <- round(min(x), digits)
  Max <- round(max(x), digits)
  return(c(N = N, Mean = Mean, SD = SD, min = Min, max = Max))
}


zz.sum.max <- function(x, extra = F) {
  if (!is.numeric(x)) {
    cat("Error: Numeric arrays required.")
    return(1)
  }
  x <- x[!is.na(x)]
  N <- length(x)
  options(digits = 4)
  if (!N) {
    return(c(0))
  }
  Mean <- mean(x)
  V <- var(x)
  SD <- V^.5
  SE <- V^.5 / (N^.5)
  Min <- min(x)
  Median <- quantile(x, probs = c(.5), names = F)
  Max <- max(x)
  errmin2 <- Mean - 1.96 * SE
  errmax2 <- Mean + 1.96 * SE
  errmin1 <- Mean - SE
  errmax1 <- Mean + SE
  if (extra) {
    return(c(N = round(N), Mean = Mean, SE = SE, ERRMN1 = errmin1, ERRMX1 = errmax1, ERRMN2 = errmin2, ERRMX2 = errmax2, SD = SD, min = Min, max = Max))
  } else {
    return(c(N = round(N), Mean = Mean, Median = Median, SE = SE, SD = SD, min = Min, max = Max))
  }
}

zz.get.vars <- function(formula, dat0, id) {
  fr <- all.vars(formula[[3]])
  fl <- all.vars(formula[[2]])
  dat1 <- dat0[fl]
  cls <- lapply(dat1, class)

  dat2 <- dat1[cls %in% c("numeric", "integer")]
  dat3 <- dat1[!cls %in% c("numeric", "integer")]
  lhs.num <- names(dat2)
  lhs.fac <- names(dat3)
  rhs.fac <- fr
  return(list(lhs.num = lhs.num, lhs.fac = lhs.fac, rhs.fac = rhs.fac))
}

library(palmerpenguins)
zz.table1.bak <- function(data, form, digits = 2) {
  contin <- function(y) {
    s1 <- lapply(y, zz.sum.min) %>%
      do.call("rbind", .) %>%
      as.data.frame()
    grp <- paste0(s1$Mean, "$\\pm$", s1$SD, " ({\\scriptsize ", s1$min, "-", s1$max, "})")
  }
  categ <- function(x, y) {
    tab0 <- prop.table(addmargins(table(x, datgrp), 2), 2)
    row.names(tab0) <- paste(y, row.names(tab0))
    return(tab0)
  }
  zzz <- zz.get.vars(form, data)
  num <- zzz$lhs.num
  fac <- zzz$lhs.fac
  grp <- zzz$rhs.fac
  datnum <- data[num]
  datfac <- data[fac]
  datgrp <- unlist(data[grp])
  contsum <- bb <- NULL
  if (length(num)) {
    groupsum <- datnum %>%
      split(., datgrp) %>%
      lapply(., contin) %>%
      do.call("cbind", .)
    contsum <- datnum %>%
      contin() %>%
      cbind(groupsum, all = .)
  }
  if (length(fac)) {
    aa <- map2(datfac, names(datfac), categ)
    bb <- do.call("rbind", aa)
    # names(bb) = c("mld","mod","all")
    bb %<>% as.data.frame %>% dplyr::rename(all = Sum)
    bb[] <- lapply(bb, function(x) as.character(round(x, digits)))
  }
  allsum <- rbind(contsum, bb)
  nnn1 <- c(table(datgrp), all = nrow(data))
  nnn2 <- paste("(N={\\scriptsize ", nnn1, "})", sep = "")
  cols <- c(names(table(datgrp)), "all")
  colnames(allsum) <- paste(cols, nnn2)
  rownames(allsum) <- c(num, row.names(bb))
  return(allsum)
}

vv <-
  function(x, nr0 = 3) {
    dm <- dim(x)
    nr1 <- min(nr0, nrow(x))
    hdx <- head(x, nr1)
    desc <- c(class = class(x), mode = mode(x))
    stru <- capture.output(str(x))
    list(dim = dm, describe = desc, struct = stru, rows = hdx)
  }


ss <- subset
hd <- head
tb <- table
len <- length
cnt <- function(x) {
  length(unique(x))
}
dvr <- function(x) {
  dput(names(x))
}
avr <- function(x) {
  dput(unique(x))
}

dfr <- as.data.frame
sel <- dplyr::select
ren <- dplyr::rename
fil <- dplyr::filter
mut <- dplyr::mutate
summ <- dplyr::summarize

zz.read.data <- function(x)
                         #  function to read the csv file names from the local ./data
# directory and name them with the file name minus the .csv extension
{
  xx <- gsub(".csv", "", x) %>% gsub("data/", "", .)
  yy <- suppressMessages(read_csv(x, na = c("", "NA", "-1", "-4"))) %>%
    rename_all(tolower) %>%
    rename_all(funs(sub("pt", "", .)))
  assign(xx, yy, pos = ".GlobalEnv")
}

zz.fig4 <- function(data, form, error = bar, type = ci, facet = NULL,
                    title = "Outcome", xlab = "Time", ylab = "Outcome",
                    size = 3, pd = .1, limits) {
  type <- enquo(type)
  type <- quo_name(type)
  error <- enquo(error)
  error <- quo_name(error)
  ff <- prs(form)
  gc <- as.character(ff$g)
  form <- paste0(ff$y, "~", ff$x)
  if (length(gc)) form <- paste0(form, "+", gc)
  if (!is.null(facet)) {
    fc <- prs(facet)
    fcy <- fc[[1]]
    fcx <- fc[[2]]
    if (!fcy == ".") form <- paste0(form, "+", fcy)
    if (!fcx == ".") form <- paste0(form, "+", fcx)
    formfacet <- as.formula(paste0(fcy, "~", fcx))
  }
  form <- as.formula(form)
  yy <- paste0(ff$y, ".Mean")
  xx <- as.character(ff$x)
  if (type == "ci") {
    bd <- paste0(ff$y, ".ERRMN2")
    bu <- paste0(ff$y, ".ERRMX2")
  } else if (type == "se") {
    bd <- paste0(ff$y, ".ERRMN1")
    bu <- paste0(ff$y, ".ERRMX1")
  } else {
    bd <- bu <- yy
  }
  NN <- paste0(ff$y, ".N")
  pd <- position_dodge(pd)
  ss <- summaryBy(form, data = as.data.frame(data), FUN = zz.sum.max, extra = T)
  ss$gcc <- 1
  g <- ggplot(data = ss, aes_string(x = xx, y = yy, group = "gcc"))
  if (length(gc) == 1) {
    g <- ggplot(data = ss, aes_string(
      x = xx, y = yy, group = gc, fill = gc,
      shape = gc, color = gc, ymax = max(yy)
    ))
  }
  g <- g + geom_line(position = pd)
  g <- g + geom_point(size = size, position = pd, color = "black")
  if (error == "bar") {
    g <- g + geom_errorbar(aes_string(ymin = bd, ymax = bu),
      width = 0.2,
      color = "black", alpha = .3, position = pd
    )
  }
  if (error == "bnd") g <- g + geom_ribbon(aes_string(ymin = bd, ymax = bu), alpha = 0.3)
  g <- g + geom_text(aes_string(label = NN), hjust = 1.75, size = size, show.legend = F)
  g <- g + labs(title = title) + xlab(xlab) + ylab(ylab)
  g <- g + theme_pander()
  g <- g + scale_shape_manual(values = c(0, 1, 2))
  g <- g + theme(
    panel.grid.major = element_line(colour = "grey"),
    panel.grid.minor = element_line(colour = "grey")
  ) +
    if (!is.null(facet)) g <- g + facet_grid(formfacet)
  g <- g + scale_y_continuous(limits = limits)
  g
}


#' Table one summaries
#'
#' Summarizes baseline trial results by treatment
#' @param data dataframe
#' @param form formula y ~ x1 + x2
#' @param ... extra parameters passed through to speciality functions
#' @return a dataframe
#' @examples
#' table1(dat2, form = arm ~ sex + age, annot = FALSE)

#' @export
table1 <- function(form, data, ...) {
  UseMethod("table1")
}

row_name <- function(x, nm, ...) {
  UseMethod("row_name")
}

row_name.character <- function(x, nm, missing = FALSE, ...) {
  if (missing) {
    categs <- unique(as.character(x))
    categs[is.na(categs)] <- "missing"
  } else {
    categs <- unique(na.omit(as.character(x)))
  }
  nms <- cbind(variables = c(nm, categs), code = c(1, rep(2, length(categs))))
  return(as.data.frame(nms))
}
row_name.factor <- row_name.character

row_name.logical <- row_name.character

row_name.numeric <- function(x, nm, ...) {
  return(as.data.frame(cbind(variables = nm, code = 3)))
}

row_summary <- function(x, yy, ...) {
  UseMethod("row_summary")
}

row_summary.character <- function(x, yy, totals = FALSE, missing = FALSE, ...) {
  df <- data.frame(x = x, y = yy)
  if (missing) {
    t1 <- df |> tabyl(x, y, show_na = TRUE, show_missing_levels = FALSE)
  } else {
    t1 <- df |>
      na.omit() |>
      tabyl(x, y, show_missing_levels = FALSE)
  }
  if (totals) {
    t1 <- t1 |> adorn_totals("col")
  }
  t1 <- t1 |>
    adorn_percentages("col") |>
    adorn_pct_formatting(digits = 0) |>
    adorn_ns(position = "front") |>
    select(-x)
  names(t1) <- gsub("_", "", names(t1))
  return(rbind("", t1))
}

row_summary.factor <- row_summary.character
row_summary.logical <- row_summary.character

row_summary.numeric <- function(x, yy, totals = FALSE, missing = FALSE, ...) {
  if (missing) {
    zz <- as.character(yy)
    zz[is.na(zz)] <- "NA"
    yy <- factor(zz)
  }
  sp <- split(x, yy)
  # add x to sp as a "k+1" element listing if totals=T
  if (totals) sp[["Total"]] <- x
  mm <- sp |>
    map_vec(mean, na.rm = TRUE) |>
    round(2)
  ss <- sp |>
    map_vec(sd, na.rm = TRUE) |>
    round(2) |>
    paste0("(", x = _, ")")
  out <- paste(mm, ss)
  names(out) <- names(sp)
  return(out)
}

row_pv <- function(x, yy, ...) {
  UseMethod("row_pv")
}

row_pv.character <- function(x, yy, missing = FALSE, ...) {
  if (missing) {
    categs <- unique(as.character(x))
  } else {
    categs <- unique(na.omit(as.character(x)))
  }
  tab <- data.frame(x = x, y = yy) |>
    na.omit() |>
    tabyl(x, y, show_missing_levels = FALSE)
  if (!(nrow(tab) >= 2 & ncol(tab) >= 3)) {
    pv <- NA
  } else {
    pv <- janitor::fisher.test(tab, simulate.p.value = TRUE)$p.value |>
      round(4)
  }
  return(c(pv, rep("", length(categs))))
}

row_pv.factor <- row_pv.character
row_pv.logical <- row_pv.character
row_pv.factor <- row_pv.character
row_pv.logical <- row_pv.character

row_pv.numeric <- function(x, yy, ...) {
  categs <- unique(na.omit(yy))
  if (!(length(categs) > 1)) {
    return(NA)
  }
  df <- data.frame(x = x, y = yy)
  pv <- tidy(anova(lm(x ~ y, data = df)))$p.value[1] |>
    round(4)
  return(pv)
}

block <- function(indep, dep, grp, ...) {
  dd <- split(indep, grp)
  yy <- split(dep, grp)
  # print('inside block')
  tab3 <- map2(dd, yy, function(x, y) {
    build(indep = x, dep = y, ...)
  })
  tab4 <- bind_rows(tab3)
  new <- data.frame(matrix(NA, nrow = length(tab3), ncol = ncol(tab4)))
  names(new) <- names(tab4)
  new$variables <- names(tab3)
  new$code <- 4
  rr <- cumsum(c(1, rep(nrow(tab3[[1]]) + 1, length(tab3) - 1)))
  tab5 <- insertRows(tab4, rr, new, rcurr = F)
}



stripes <- function(tab5, digits = 3, theme = theme_bw, ...) {
  tab5 <- dplyr::mutate(tab5, variables = ifelse(code == 2,
    gsub("^", "\\\\quad ", variables), variables
  ))
  # tab6$vars = gsub("_","\_",tab6$vars)
  strp <- map(sort(unique(tab5$code)), function(x) {
    which(tab5$code == x)
  })
  myfcn <- function(x, i, theme = theme) {
    x <- x |> row_spec(strp[[i]],
      color = theme$foreground[i],
      background = theme$background[i]
    )
  }
  tab5 <- tab5 |>
    dplyr::select(-code)
  kk <- kbl(tab5, "latex",
    booktabs = T, linesep = "",
    escape = F, digits = digits
  )
  tab5plusstripes <- reduce(1:length(strp),
    ~ myfcn(.x, .y, theme = theme),
    .init = kk
  )
  return(tab5plusstripes)
}



build <- function(indep, dep, size = TRUE, ...) {
  # args <- list(...)
  # for (i in 1:length(args)) {
  #   assign(x = names(args)[i], value = args[[i]])
  # }
  left <- indep |>
    imap(row_name, ...) |>
    bind_rows()
  right <- indep |>
    map(row_pv, yy = dep[[1]], ...) |>
    unlist() |>
    enframe(name = NULL) |>
    setNames("p.value")
  mid <- indep |>
    map(row_summary, yy = dep[[1]], ...) |>
    bind_rows()
  if (size) {
    names(mid) <- paste0(names(mid), " (N = ", table(dep), ")")
  }
  tab <- bind_cols(left, mid, right)
  return(tab)
}
#' @export
#' @describeIn table1 interprets formula and yields publication tables
table1.formula <- function(form, data, pvalue = TRUE, totals = FALSE,
                           fname = "table1", layout = "console", ...) {
  # args <- list(...)
  # for (i in 1:length(args)) {
  #   assign(x = names(args)[i], value = args[[i]])
  # }
  # 1

  # need to figure out what to do when only when indep var and no group.
  # form[[c(3,1)]]
  formtest <- as.character(form)
  grptest <- str_detect(formtest, "\\|") |> any()
  vars <- all.vars(form)
  y_var <- deparse(form[[2]])
  g_bar <- 0
  if (grptest) g_bar <- deparse(form[[c(3, 1)]])
  g_var <- NULL
  if (g_bar == "|") {
    x_vars <- all.vars(form[[c(3, 2)]])
    g_var <- all.vars(form[[c(3, 3)]])
    group <- data[g_var]
  } else {
    x_vars <- all.vars(form)[-1]
  }
  if (!is.null(g_var)) {
    tab5 <- block(indep = data[x_vars], dep = data[y_var], grp = data[g_var], ...)
  } else {
    tab5 <- build(indep = data[x_vars], dep = data[y_var], ...)
  }
  if (!pvalue) {
    tab5 <- tab5 |>
      dplyr::select(-p.value)
  }
  if (!totals) {
    tab5 <- tab5 |>
      dplyr::select(-contains("Total"))
  }
  if (is.null(y_var)) {
    tab5 <- tab5 |>
      dplyr::select(variables, code, contains("Total"), p.value)
  }
  if (layout == "console") {
    return(tab5[-2])
  } else if (layout == "latex") {
    tablatex <- stripes(tab5, ...)
    write(tablatex, paste0("./tables/", fname, ".tex"))
    system(paste0("sh ~/shr/figurize.sh ./tables/", fname, ".tex"))
  } else if (layout == "html") {
    kk <- kbl(tab5[-2], "html",
      escape = F, digits = digits
    )
    tabhtml <- reduce(1:length(stripes),
      ~ myfcn(.x, .y, theme = theme),
      .init = kk
    )
  }
}
# end of table1
options(knitr.kable.NA = "")
p1 <- sample_n(palmerpenguins::   penguins, 100) |>
  dplyr::select(
    species, flipper_length_mm, sex,
    body_mass_g, bill_length_mm, island
  ) |>
  dplyr::mutate(flp = flipper_length_mm > 197)
p1[100, "island"] <- NA

theme_npg <- list(
  foreground = c("black", "black", "black", "black"),
  background = c(
    "#f0efd4",
    "#e8e6bc",
    "#f0efd4",
    "#f0efd4"
  )
)
theme_nejm <- list(
  foreground = c("black", "black", "black", "black"),
  background = c("#fff7e9", "white", "#fff7e9", "white")
)

theme_green <- list(
  foreground = c("black", "black", "black", "black"),
  background = c("#99cfa8", "#d4f0dc", "#94ebad", "yellow")
)
theme_simple <- list(
  foreground = c("black", "black", "black", "black"),
  background = c("cyan", "blue", "green", "yellow")
)
theme_bw <- list(
  foreground = c("black", "black", "black", "black"),
  background = c("white", "white", "white", "white")
)
# tab0 <- table1(sex ~ island,
#   data = p1,
#   theme = theme_green, layout = "console", fname = "ptab0", digits = 3, pvalue = FALSE
# )
# tab1 <- table1(sex ~ island + flp + body_mass_g + bill_length_mm,
#   data = p1,
#   theme = theme_green, layout = "latex", fname = "ptab1", digits = 3
# )
# tab1b <- table1(sex ~ island + flp + body_mass_g + bill_length_mm,
#   data = p1,
#   theme = theme_npg, layout = "latex", fname = "ptab1b", digits = 3
# )
# tab2 <- table1(sex ~ flp + body_mass_g + bill_length_mm | island,
#   data = p1,
#   theme = theme_npg, layout = "console", fname = "ptab2", digits = 3
# )
# tab3 <- table1(sex ~ flp + body_mass_g + bill_length_mm | island,
#   data = p1,
#   theme = theme_npg, layout = "latex", fname = "ptab3", digits = 3
# )
# tab4 <- table1(sex ~ flp + body_mass_g + bill_length_mm + island,
#   data = p1,
#   theme = theme_green, layout = "latex", fname = "ptab4", digits = 3, size=FALSE
# )
# tab4 <- table1(sex ~ flp + body_mass_g + bill_length_mm | island,
#  data = p1,
#  theme = theme_green, layout = "latex", fname = "ptab4b", digits = 3, size=FALSE
# )
zz.t2f <- function(
    df, tabname, size = 10, width = "1in", rownames = F,
    scolor = "gray!6", strps = NULL, pack = NULL, digits = 3) {
  kable({{ df }}, "latex",
    booktabs = T, escape = FALSE,
    row.names = rownames, digits = digits
  ) %>%
    kable_styling(
      latex_options = "striped", stripe_color = scolor,
      stripe_index = strps, font_size = size
    ) %>%
    column_spec(1, width = width) %>%
    {
      if (!is.null(pack)) {
        pack_rows(index = pack, latex_gap_space = ".15in")
      } else {
        .
      }
    } %>%
    write(paste0("./tables/", tabname, ".tex"))
  system(paste0("sh ~/shr/figurize.sh ./tables/", tabname, ".tex"))
}

# zz.t2f <- function(df, tabname, size = 10, width = "1in", rownames = F,
#                    scolor = "gray!6", strps = NULL, pack = NULL, digits = 3) {
#   kable({{ df }}, "latex",
#     booktabs = T, escape = FALSE,
#     row.names = rownames, digits = digits
#   ) %>%
#     kable_styling(
#       latex_options = "striped", stripe_color = scolor,
#       stripe_index = strps, font_size = size
#     ) %>%
#     pack_rows(index = pack, latex_gap_space = ".15in") %>%
#     write(paste0("./tables/", tabname, ".tex"))
#   system(paste0("sh ~/shr/figurize.sh ./tables/", tabname, ".tex"))
# }




fig1 <- function(
    df, form, facet_form = NULL, xlab = "visit", ylab = "measure",
    ylab2 = "measure change", title = "measure", title2 = "measure change",
    subtitle = "", subtitle2 = "", caption = "", caption2 = "",
    ytype = "obs", etype = "bar") {
  ff <- as.character(form)
  LH <- ff[2]
  RH <- ff[3]
  p <- strsplit(RH, " \\| ")[[1]]
  y <- LH
  x <- p[1]
  grp <- p[2]
  fff <- as.character(facet_form)
  LH <- fff[2]
  RH <- fff[3]
  facet_x <- LH
  facet_y <- RH
  varlist <- na.omit(c(grp, x, facet_x, facet_y))
  stats <- dplyr::mutate(
    dplyr::summarize(dplyr::mutate(df %>%
      group_by(rid), cng = .data[[y]] - .data[[y]][.data[[x]] ==
      "bl"]) %>% group_by(across(all_of(varlist))), mn = mean(.data[[y]],
      na.rm = T
    ), cng_mn = mean(cng, na.rm = T), N = n(), sd = sd(.data[[y]],
      na.rm = T
    ), cng_sd = sd(cng, na.rm = T), .groups = "drop") %>%
      dplyr::filter(!is.na(mn)),
    se = (sd) / (N^0.5), cng_se = (cng_sd) / (N^0.5),
    bl = mn - se, bu = mn + se, bl_cng = cng_mn - cng_se,
    bu_cng = cng_mn + cng_se
  ) %>% arrange(.data[[x]])
  pd <- position_dodge(0.15)
  fig.obs <- stats %>% ggplot(aes(
    x = .data[[x]], y = mn, group = .data[[grp]],
    color = .data[[grp]], fill = .data[[grp]]
  )) +
    geom_line(aes(linetype = .data[[grp]]),
      position = pd
    ) +
    {
      if (etype == "bar") {
        geom_errorbar(aes(ymin = bl, ymax = bu),
          width = 0.2,
          color = "black", alpha = 0.3, position = pd
        )
      } else if (etype == "band") {
        geom_ribbon(aes(ymin = bl, ymax = bu), alpha = 0.2)
      }
    } +
    geom_text(aes(label = N), hjust = 1.75, size = 3, show.legend = F) +
    scale_linetype_manual(values = c("solid", "dashed", "dotted")) +
    scale_color_manual(values = c("#0ff1ce", "#ff3f3f", "blue")) +
    labs(title = title, subtitle = subtitle, caption = caption) +
    ylab(ylab) +
    xlab(xlab) +
    theme_bw() +
    theme(legend.title = element_blank()) +
    theme(legend.position = "bottom") +
    {
      if (!is.na(facet_y)) {
        facet_grid(vars(.data[[facet_y]]), vars(.data[[facet_x]]),
          labeller = labeller(.rows = label_both, .cols = label_both)
        )
      }
    }
  fig.cng <- stats %>% ggplot(aes(
    x = .data[[x]], y = cng_mn,
    group = .data[[grp]], color = .data[[grp]]
  )) +
    geom_line(aes(linetype = .data[[grp]]),
      position = pd
    ) +
    geom_errorbar(aes(ymin = bl_cng, ymax = bu_cng),
      width = 0.2, color = "black", alpha = 0.3, position = pd
    ) +
    geom_text(aes(label = N), hjust = 1.75, size = 3, show.legend = F) +
    scale_linetype_manual(values = c("solid", "dashed", "dotted")) +
    scale_color_manual(values = c("#0ff1ce", "#ff3f3f", "blue")) +
    labs(title = title2, subtitle = subtitle2, caption = caption2) +
    ylab(ylab2) +
    xlab(xlab) +
    theme_bw() +
    theme(legend.title = element_blank()) +
    theme(legend.position = "bottom")
  ifelse(ytype == "obs", return(fig.obs), ifelse(ytype == "cng",
    return(fig.cng), return(fig.obs + fig.cng)
  ))
}

# version 11/26/24  developed in ~/sbx/t2f/R
t2f <- function(df, tabname, size = 10, width = "1in", rownames = FALSE,
                scolor = "gray!6", strps = NULL, pack = 0L, digits = 3,
                sub_dir = NULL) {
colnames(df) <- gsub("_", "\\\\_", colnames(df))
df[] <- lapply(df, function(x) gsub("%", "\\\\%", x))
        main_dir <- getwd()
        if (!is.null(sub_dir)) {
                if (!file.exists(sub_dir)) {
                        dir.create(file.path(main_dir, sub_dir))
                }
        }
        t1 <- kableExtra::kable({{ df }}, "latex",
                booktabs = TRUE, escape = FALSE,
                row.names = rownames, digits = digits
        ) |>
                kableExtra::kable_styling(
                        latex_options = "striped", stripe_color = scolor,
                        stripe_index = strps, font_size = size
                ) |>
                # pack = c(` ` = 3, `Group 1` = 2, `Group 2` = 1))
                # pack_rows(index = pack, latex_gap_space = ".15in") |>
                as.character()
        bname <- paste0("./", sub_dir, "/", tabname)
        prelude <- "\\documentclass[10pt]{article}
\\usepackage{amsmath,amssymb,booktabs,longtable,float,colortbl,xcolor,geometry}
\\begin{document}
\\thispagestyle{empty} "
        enddoc <- "\\end{document}"
        write(c(prelude, t1, enddoc), paste0(bname, ".tex"))
        xtx <- paste0(
                "xelatex --halt-on-error -jobname=", bname, "0 ",
                bname, " 1>sdout.tmp"
        )
        crp <- paste0(
                "pdfcrop -margins 10 ", bname, "0.pdf ",
                bname, ".pdf  1>sdout2.tmp"
        )
        rmf <- paste0("rm ", bname, "0.aux ", bname, "0.log ", bname, "0.pdf")
        sout <- system(xtx, intern = TRUE)
        sout2 <- system(crp, intern = TRUE)
        sout3 <- system(rmf, intern = TRUE)
        browser()
        return(sout)
}
