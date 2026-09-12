# ============================================================
# Oncology SDTM to ADaM with {admiral}
#
# File: 05_safety_analysis.R
#
# Purpose:
#   Perform descriptive safety analyses using the
#   Analysis Datasets ADSL and ADAE.
#
# Main analyses:
#   1. Analysis population
#   2. TEAE incidence
#   3. Grade >=3 TEAE incidence
#   4. Serious TEAE incidence
#   5. Treatment-related TEAE incidence
#   6. TEAE frequency by preferred term
#   7. AE severity distribution
#   8. AE duration
#   9. Patient-level AE burden
#
# Important:
#   This is a synthetic educational dataset.
#   The analysis demonstrates a reproducible
#   statistical-programming workflow and should
#   not be interpreted as clinical evidence.
# ============================================================


# ------------------------------------------------------------
# 1. Load required packages
# ------------------------------------------------------------

# {tidyverse} provides the main tools for:
#   - data manipulation
#   - filtering
#   - grouping
#   - summarising
#   - joining
#   - plotting
library(tidyverse)

# {here} creates reproducible project-relative paths.
library(here)


# ============================================================
# 2. Import the ADaM datasets
# ============================================================


# ------------------------------------------------------------
# 2.1 Import ADSL
# ------------------------------------------------------------

# ADSL contains one record per subject.
#
# We use ADSL to determine:
#   - treatment assignment
#   - treatment population
#   - safety population
#   - treatment denominators

adsl <- read_csv(
  here("data", "adam", "adsl.csv"),
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 2.2 Import ADAE
# ------------------------------------------------------------

# ADAE contains one record per adverse-event occurrence.
#
# We use ADAE to analyse:
#   - treatment-emergent adverse events
#   - severity
#   - toxicity grade
#   - serious events
#   - treatment-related events
#   - preferred terms
#   - event duration

adae <- read_csv(
  here("data", "adam", "adae.csv"),
  show_col_types = FALSE
)


# ============================================================
# 3. Basic dataset checks
# ============================================================


# ------------------------------------------------------------
# 3.1 Check dimensions
# ------------------------------------------------------------

# ADSL should contain one record per subject.
dim(adsl)

# ADAE contains one record per adverse-event occurrence.
dim(adae)


# ------------------------------------------------------------
# 3.2 Check the number of unique subjects
# ------------------------------------------------------------

# n_distinct() counts unique subject identifiers.

n_distinct(adsl$USUBJID)

n_distinct(adae$USUBJID)


# ------------------------------------------------------------
# 3.3 Confirm that every ADAE subject exists in ADSL
# ------------------------------------------------------------

# setdiff() identifies values present in the first
# vector but absent from the second vector.

adae_subjects_not_in_adsl <- setdiff(
  unique(adae$USUBJID),
  unique(adsl$USUBJID)
)

adae_subjects_not_in_adsl


# This should return:
#
# character(0)
#
# meaning every ADAE subject is represented in ADSL.


# ============================================================
# 4. Check the safety population
# ============================================================


# ------------------------------------------------------------
# 4.1 Safety population by actual treatment
# ------------------------------------------------------------

# SAFFL = "Y" identifies subjects included in the
# safety population.

adsl %>%
  filter(SAFFL == "Y") %>%
  count(TRT01A, name = "N")


# Expected result:
#
# Treatment 1    39
# Treatment 2    40
# Treatment 3    41


# ------------------------------------------------------------
# 4.2 Check safety population flags
# ------------------------------------------------------------

adsl %>%
  count(SAFFL)


# ============================================================
# Step 2: Analysis Population
# ============================================================


# ------------------------------------------------------------
# 2.1 Create treatment population summary
# ------------------------------------------------------------

# The denominator for safety analyses is the number of
# subjects in the safety population for each actual treatment.
#
# SAFFL = "Y" identifies the safety population.
#
# TRT01A = Actual Treatment.

population_summary <- adsl %>%
  filter(SAFFL == "Y") %>%
  count(
    TRT01A,
    name = "N"
  )


# Display the result in the R console.
population_summary


# ------------------------------------------------------------
# 2.2 Save the population table
# ------------------------------------------------------------

# write_csv() saves the table as a CSV file.
#
# This means the analysis result is reproducible and can
# later be imported into another report, Excel, or R Markdown.

write_csv(
  population_summary,
  here(
    "output",
    "tables",
    "01_population_summary.csv"
  )
)

# ------------------------------------------------------------
# 2.3 QC population denominators
# ------------------------------------------------------------

# The synthetic study contains 120 subjects.
#
# We expect:
#   Treatment 1 = 39
#   Treatment 2 = 40
#   Treatment 3 = 41
#
# Total = 120.

stopifnot(
  sum(population_summary$N) == 120
)

stopifnot(
  all(
    population_summary$N ==
      c(39, 40, 41)
  )
)

cat("Population analysis QC PASSED\n")


# ============================================================
# Step 3: Treatment-Emergent Adverse Event (TEAE) Incidence
# ============================================================


# ------------------------------------------------------------
# 3.1 Identify patients with at least one TEAE
# ------------------------------------------------------------

# We start with ADAE and keep only treatment-emergent
# adverse-event records.
#
# TRTEMFL = "Y" means the adverse event is treatment-emergent.
#
# distinct() is important here:
#
# A patient may have several TEAE records, but for an
# incidence analysis the patient should be counted only once.

teae_patients <- adae %>%
  filter(TRTEMFL == "Y") %>%
  distinct(
    USUBJID,
    TRT01A
  )


# Inspect the patient-level dataset.

teae_patients

# ------------------------------------------------------------
# 3.2 Count patients with at least one TEAE
# ------------------------------------------------------------

teae_counts <- teae_patients %>%
  count(
    TRT01A,
    name = "TEAE"
  )

teae_counts

# ------------------------------------------------------------
# 3.3 Add safety-population denominators
# ------------------------------------------------------------

teae_summary <- population_summary %>%
  left_join(
    teae_counts,
    by = "TRT01A"
  ) %>%
  mutate(
    TEAE = replace_na(TEAE, 0),
    TEAE_PCT = 100 * TEAE / N
  )

teae_summary

# ------------------------------------------------------------
# 3.4 Create formatted TEAE table
# ------------------------------------------------------------

teae_table <- teae_summary %>%
  mutate(
    TEAE_n_pct = sprintf(
      "%d (%.1f%%)",
      TEAE,
      TEAE_PCT
    )
  ) %>%
  select(
    TRT01A,
    N,
    TEAE,
    TEAE_PCT,
    TEAE_n_pct
  )

teae_table

# ------------------------------------------------------------
# 3.5 Save TEAE summary
# ------------------------------------------------------------

write_csv(
  teae_table,
  here(
    "output",
    "tables",
    "02_teae_summary.csv"
  )
)

# ------------------------------------------------------------
# 3.6 QC TEAE incidence
# ------------------------------------------------------------

stopifnot(
  all(teae_summary$TEAE == c(30, 31, 34))
)

stopifnot(
  all(
    round(teae_summary$TEAE_PCT, 1) ==
      c(76.9, 77.5, 82.9)
  )
)

stopifnot(
  all(teae_summary$TEAE <= teae_summary$N)
)

cat("TEAE incidence QC PASSED\n")

# ============================================================
# Step 4: Figure 1 — TEAE Incidence
# ============================================================

# ------------------------------------------------------------
# 4.1 Create TEAE incidence plot
# ------------------------------------------------------------

teae_plot <- ggplot(
  teae_summary,
  aes(
    x = TRT01A,
    y = TEAE_PCT
  )
) +
  geom_col(
    width = 0.65
  ) +
  geom_text(
    aes(
      label = sprintf(
        "%.1f%%",
        TEAE_PCT
      )
    ),
    vjust = -0.4,
    size = 4
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    expand = expansion(
      mult = c(0, 0.08)
    )
  ) +
  labs(
    title = "Treatment-Emergent Adverse Event Incidence",
    x = "Treatment",
    y = "Patients with ≥1 TEAE (%)"
  ) +
  theme_minimal(
    base_size = 13
  )

teae_plot


ggsave(
  filename = here(
    "output",
    "figures",
    "01_teae_incidence.png"
  ),
  plot = teae_plot,
  width = 8,
  height = 6,
  dpi = 300
)

cat("Figure 1 saved: output/figures/01_teae_incidence.png\n")

stopifnot(
  file.exists(
    here(
      "output",
      "figures",
      "01_teae_incidence.png"
    )
  )
)

cat("Figure 1 QC PASSED\n")



# ============================================================

# ------------------------------------------------------------
# 5.1 Create patient-level safety flags
# ------------------------------------------------------------

patient_safety <- adae %>%
  group_by(
    TRT01A,
    USUBJID
  ) %>%
  summarise(
    
    TEAE = any(
      TRTEMFL == "Y"
    ),
    
    GRADE3PLUS = any(
      TRTEMFL == "Y" &
        AETOXGR >= 3
    ),
    
    SERIOUS = any(
      TRTEMFL == "Y" &
        AESER == "Y"
    ),
    
    RELATED = any(
      TRTEMFL == "Y" &
        AEREL == "RELATED"
    ),
    
    .groups = "drop"
  )

patient_safety

nrow(patient_safety)

n_distinct(patient_safety$USUBJID)

# ------------------------------------------------------------
# 5.2 Count patients with each safety event
# ------------------------------------------------------------

safety_counts <- patient_safety %>%
  group_by(TRT01A) %>%
  summarise(
    TEAE = sum(TEAE),
    GRADE3PLUS = sum(GRADE3PLUS),
    SERIOUS = sum(SERIOUS),
    RELATED = sum(RELATED),
    .groups = "drop"
  )

safety_counts


# ------------------------------------------------------------
# 5.3 Add safety population denominators
# ------------------------------------------------------------

safety_incidence <- population_summary %>%
  left_join(
    safety_counts,
    by = "TRT01A"
  ) %>%
  mutate(
    TEAE_PCT = 100 * TEAE / N,
    GRADE3PLUS_PCT = 100 * GRADE3PLUS / N,
    SERIOUS_PCT = 100 * SERIOUS / N,
    RELATED_PCT = 100 * RELATED / N
  )

safety_incidence

# ------------------------------------------------------------
# 5.4 Create formatted safety incidence table
# ------------------------------------------------------------

safety_table <- safety_incidence %>%
  mutate(
    TEAE_n_pct = sprintf(
      "%d (%.1f%%)",
      TEAE,
      TEAE_PCT
    ),
    
    GRADE3PLUS_n_pct = sprintf(
      "%d (%.1f%%)",
      GRADE3PLUS,
      GRADE3PLUS_PCT
    ),
    
    SERIOUS_n_pct = sprintf(
      "%d (%.1f%%)",
      SERIOUS,
      SERIOUS_PCT
    ),
    
    RELATED_n_pct = sprintf(
      "%d (%.1f%%)",
      RELATED,
      RELATED_PCT
    )
  ) %>%
  select(
    TRT01A,
    N,
    TEAE_n_pct,
    GRADE3PLUS_n_pct,
    SERIOUS_n_pct,
    RELATED_n_pct
  )

safety_table

write_csv(
  safety_table,
  here(
    "output",
    "tables",
    "03_key_safety_incidence.csv"
  )
)

cat(
  "Saved: output/tables/03_key_safety_incidence.csv\n"
)

# ------------------------------------------------------------
# 5.6 Safety incidence QC
# ------------------------------------------------------------

stopifnot(
  all(
    safety_incidence$TEAE ==
      c(30, 31, 34)
  )
)

stopifnot(
  all(
    safety_incidence$GRADE3PLUS ==
      c(15, 12, 21)
  )
)

stopifnot(
  all(
    safety_incidence$SERIOUS ==
      c(15, 12, 21)
  )
)

stopifnot(
  all(
    safety_incidence$RELATED ==
      c(20, 26, 23)
  )
)

stopifnot(
  all(
    safety_incidence$TEAE <= safety_incidence$N
  )
)

stopifnot(
  all(
    safety_incidence$GRADE3PLUS <= safety_incidence$TEAE
  )
)

stopifnot(
  all(
    safety_incidence$SERIOUS <= safety_incidence$TEAE
  )
)

stopifnot(
  all(
    safety_incidence$RELATED <= safety_incidence$TEAE
  )
)

cat("Key safety incidence QC PASSED\n")

# ------------------------------------------------------------
# 5.7 Prepare data for Figure 2
# ------------------------------------------------------------

safety_plot_data <- safety_incidence %>%
  select(
    TRT01A,
    TEAE_PCT,
    GRADE3PLUS_PCT,
    SERIOUS_PCT,
    RELATED_PCT
  ) %>%
  pivot_longer(
    cols = -TRT01A,
    names_to = "Endpoint",
    values_to = "Percentage"
  ) %>%
  mutate(
    Endpoint = recode(
      Endpoint,
      TEAE_PCT = "Any TEAE",
      GRADE3PLUS_PCT = "Grade ≥3 TEAE",
      SERIOUS_PCT = "Serious TEAE",
      RELATED_PCT = "Related TEAE"
    )
  )

safety_plot_data


# ------------------------------------------------------------
# 5.8 Create Figure 2
# ------------------------------------------------------------

safety_plot <- ggplot(
  safety_plot_data,
  aes(
    x = TRT01A,
    y = Percentage,
    fill = Endpoint
  )
) +
  geom_col(
    position = position_dodge(
      width = 0.8
    ),
    width = 0.7
  ) +
  geom_text(
    aes(
      label = sprintf(
        "%.1f%%",
        Percentage
      )
    ),
    position = position_dodge(
      width = 0.8
    ),
    vjust = -0.3,
    size = 3
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20),
    expand = expansion(
      mult = c(0, 0.08)
    )
  ) +
  labs(
    title = "Key Safety Event Incidence by Treatment",
    x = "Treatment",
    y = "Patients with Event (%)",
    fill = "Safety Endpoint"
  ) +
  theme_minimal(
    base_size = 13
  )

safety_plot


ggsave(
  filename = here(
    "output",
    "figures",
    "02_safety_event_incidence.png"
  ),
  plot = safety_plot,
  width = 10,
  height = 6,
  dpi = 300
)

cat(
  "Figure 2 saved: output/figures/02_safety_event_incidence.png\n"
)

stopifnot(
  file.exists(
    here(
      "output",
      "figures",
      "02_safety_event_incidence.png"
    )
  )
)

cat("Figure 2 QC PASSED\n")



# ============================================================
# Step 6: TEAE Frequency by Preferred Term
# ============================================================

# ------------------------------------------------------------
# 6.1 Examine TEAE preferred terms
# ------------------------------------------------------------

teae_terms <- adae %>%
  filter(
    TRTEMFL == "Y"
  ) %>%
  count(
    AEDECOD,
    name = "EVENTS"
  ) %>%
  arrange(
    desc(EVENTS)
  )

teae_terms

# ------------------------------------------------------------
# 6.2 Patient incidence by preferred term
# ------------------------------------------------------------

teae_term_patients <- adae %>%
  filter(
    TRTEMFL == "Y"
  ) %>%
  distinct(
    USUBJID,
    TRT01A,
    AEDECOD
  ) %>%
  count(
    AEDECOD,
    name = "PATIENTS"
  ) %>%
  arrange(
    desc(PATIENTS)
  )

teae_term_patients


# ------------------------------------------------------------
# 6.3 Combine event frequency and patient incidence
# ------------------------------------------------------------

teae_term_summary <- teae_terms %>%
  left_join(
    teae_term_patients,
    by = "AEDECOD"
  ) %>%
  arrange(
    desc(PATIENTS),
    desc(EVENTS)
  )

teae_term_summary

# ------------------------------------------------------------
# 6.4 Patient incidence by treatment and preferred term
# ------------------------------------------------------------

teae_term_by_treatment <- adae %>%
  filter(
    TRTEMFL == "Y"
  ) %>%
  distinct(
    USUBJID,
    TRT01A,
    AEDECOD
  ) %>%
  count(
    AEDECOD,
    TRT01A,
    name = "PATIENTS"
  )

teae_term_by_treatment

# ------------------------------------------------------------
# 6.5 Identify top 10 TEAE preferred terms
# ------------------------------------------------------------

top10_teae <- teae_term_summary %>%
  slice_max(
    order_by = PATIENTS,
    n = 10,
    with_ties = FALSE
  )

top10_teae

# ------------------------------------------------------------
# 6.6 Create Top 10 treatment-specific table
# ------------------------------------------------------------

top10_teae_table <- teae_term_by_treatment %>%
  filter(
    AEDECOD %in% top10_teae$AEDECOD
  ) %>%
  select(
    AEDECOD,
    TRT01A,
    PATIENTS
  ) %>%
  pivot_wider(
    names_from = TRT01A,
    values_from = PATIENTS,
    values_fill = 0
  ) %>%
  left_join(
    top10_teae %>%
      select(
        AEDECOD,
        EVENTS,
        PATIENTS
      ),
    by = "AEDECOD"
  ) %>%
  arrange(
    desc(PATIENTS)
  )

top10_teae_table

# ------------------------------------------------------------
# 6.7 Save Top 10 TEAE table
# ------------------------------------------------------------

write_csv(
  top10_teae_table,
  here(
    "output",
    "tables",
    "04_teae_by_preferred_term.csv"
  )
)

cat(
  "Saved: output/tables/04_teae_by_preferred_term.csv\n"
)

# ------------------------------------------------------------
# 6.8 Prepare data for Figure 3
# ------------------------------------------------------------

teae_term_plot_data <- top10_teae %>%
  mutate(
    AEDECOD = fct_reorder(
      AEDECOD,
      PATIENTS
    )
  )

# ------------------------------------------------------------
# 6.9 Create Figure 3
# ------------------------------------------------------------

teae_term_plot <- ggplot(
  teae_term_plot_data,
  aes(
    x = AEDECOD,
    y = PATIENTS
  )
) +
  geom_col(
    width = 0.7
  ) +
  geom_text(
    aes(
      label = PATIENTS
    ),
    hjust = -0.2,
    size = 3.5
  ) +
  coord_flip() +
  scale_y_continuous(
    expand = expansion(
      mult = c(0, 0.12)
    )
  ) +
  labs(
    title = "Top 10 Treatment-Emergent Adverse Events",
    subtitle = "Ranked by number of affected patients",
    x = "Preferred Term",
    y = "Patients"
  ) +
  theme_minimal(
    base_size = 13
  )

teae_term_plot

# ------------------------------------------------------------
# 6.10 Save Figure 3
# ------------------------------------------------------------

ggsave(
  filename = here(
    "output",
    "figures",
    "03_top_teae_preferred_terms.png"
  ),
  plot = teae_term_plot,
  width = 9,
  height = 7,
  dpi = 300
)

cat(
  "Figure 3 saved: output/figures/03_top_teae_preferred_terms.png\n"
)

# ------------------------------------------------------------
# 6.11 TEAE preferred-term QC
# ------------------------------------------------------------

stopifnot(
  nrow(teae_term_summary) > 0
)

stopifnot(
  all(
    teae_term_summary$PATIENTS <=
      teae_term_summary$EVENTS
  )
)

stopifnot(
  nrow(top10_teae) <= 10
)

stopifnot(
  file.exists(
    here(
      "output",
      "tables",
      "04_teae_by_preferred_term.csv"
    )
  )
)

stopifnot(
  file.exists(
    here(
      "output",
      "figures",
      "03_top_teae_preferred_terms.png"
    )
  )
)

cat("TEAE preferred-term QC PASSED\n")

# ============================================================
# Step 7: AE Severity and Toxicity Grade
# ============================================================

# ------------------------------------------------------------
# 7.1 TEAE event records by severity
# ------------------------------------------------------------

teae_severity <- adae %>%
  filter(
    TRTEMFL == "Y"
  ) %>%
  count(
    TRT01A,
    AESEV,
    name = "EVENTS"
  ) %>%
  arrange(
    TRT01A,
    AESEV
  )

teae_severity
# ------------------------------------------------------------
# 7.2 Severity distribution
# ------------------------------------------------------------

teae_severity_summary <- teae_severity %>%
  group_by(TRT01A) %>%
  mutate(
    TOTAL_EVENTS = sum(EVENTS),
    PERCENT = 100 * EVENTS / TOTAL_EVENTS
  ) %>%
  ungroup()

teae_severity_summary
# ------------------------------------------------------------
# 7.3 Formatted severity table
# ------------------------------------------------------------

severity_table <- teae_severity_summary %>%
  mutate(
    EVENTS_n_pct = sprintf(
      "%d (%.1f%%)",
      EVENTS,
      PERCENT
    )
  ) %>%
  select(
    TRT01A,
    AESEV,
    EVENTS,
    PERCENT,
    EVENTS_n_pct
  )

severity_table
# ------------------------------------------------------------
# 7.4 Save severity table
# ------------------------------------------------------------

write_csv(
  severity_table,
  here(
    "output",
    "tables",
    "05_ae_severity.csv"
  )
)

cat(
  "Saved: output/tables/05_ae_severity.csv\n"
)

# ------------------------------------------------------------
# 7.5 TEAE records by toxicity grade
# ------------------------------------------------------------

teae_grade <- adae %>%
  filter(
    TRTEMFL == "Y"
  ) %>%
  count(
    TRT01A,
    AETOXGR,
    name = "EVENTS"
  ) %>%
  arrange(
    TRT01A,
    AETOXGR
  )

teae_grade

teae_grade_summary <- teae_grade %>%
  group_by(TRT01A) %>%
  mutate(
    TOTAL_EVENTS = sum(EVENTS),
    PERCENT = 100 * EVENTS / TOTAL_EVENTS
  ) %>%
  ungroup()

teae_grade_summary


# ------------------------------------------------------------
# 7.6 Severity / grade QC
# ------------------------------------------------------------

severity_grade_qc <- adae %>%
  filter(
    TRTEMFL == "Y"
  ) %>%
  mutate(
    EXPECTED_GRADE = case_when(
      AESEV == "MILD" ~ 1,
      AESEV == "MODERATE" ~ 2,
      AESEV == "SEVERE" ~ 3,
      TRUE ~ NA_real_
    )
  )

stopifnot(
  all(
    severity_grade_qc$AETOXGR ==
      severity_grade_qc$EXPECTED_GRADE
  )
)

cat(
  "AE severity / toxicity grade QC PASSED\n"
)

# ------------------------------------------------------------
# 7.7 Figure 4 — AE severity distribution
# ------------------------------------------------------------

severity_plot <- ggplot(
  teae_severity_summary,
  aes(
    x = TRT01A,
    y = PERCENT,
    fill = AESEV
  )
) +
  geom_col(
    width = 0.7
  ) +
  geom_text(
    aes(
      label = sprintf(
        "%.1f%%",
        PERCENT
      )
    ),
    position = position_stack(
      vjust = 0.5
    ),
    size = 3.2
  ) +
  scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, 20)
  ) +
  labs(
    title = "TEAE Severity Distribution",
    subtitle = "Distribution of treatment-emergent AE records",
    x = "Treatment",
    y = "TEAE Records (%)",
    fill = "Severity"
  ) +
  theme_minimal(
    base_size = 13
  )

severity_plot


# ------------------------------------------------------------
# 7.8 Save Figure 4
# ------------------------------------------------------------

ggsave(
  filename = here(
    "output",
    "figures",
    "04_ae_severity.png"
  ),
  plot = severity_plot,
  width = 8,
  height = 6,
  dpi = 300
)

cat(
  "Figure 4 saved: output/figures/04_ae_severity.png\n"
)


