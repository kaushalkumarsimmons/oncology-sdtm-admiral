# ============================================================
# Purpose:
#   Create the Analysis Adverse Events (ADAE) dataset from:
#
#     1. SDTM AE  = Adverse Events
#     2. ADaM ADSL = Subject-Level Analysis Dataset
#
# ADAE is an analysis-level dataset containing adverse-event
# records together with subject-level treatment information
# required for safety analyses.
#
# Main derivations in this script:
#
#   TRT01P  = Planned Treatment
#   TRT01A  = Actual Treatment
#   TRTSDT  = Treatment Start Date
#   TRTEDT  = Treatment End Date
#   SAFFL   = Safety Population Flag
#   TRTEMFL = Treatment-Emergent Adverse Event Flag
#   ASTDT   = Analysis Start Date
#   AENDT   = Analysis End Date
#   ADURN   = Analysis Duration
#   AOCCFL  = Grade >= 3 Treatment-Emergent AE Flag
#
# The final ADAE dataset is saved as:
#   data/adam/adae.csv
# ============================================================


# ------------------------------------------------------------
# 1. Load required R packages
# ------------------------------------------------------------

# {tidyverse} provides functions for:
#   - selecting variables
#   - joining datasets
#   - creating variables
#   - counting observations
#   - filtering records
#   - summarising data
library(tidyverse)

# {here} creates reproducible project-relative file paths.
# It allows us to save the final ADAE dataset without using
# machine-specific paths.
library(here)

# {admiral} provides functions for creating ADaM datasets
# from SDTM data.
#
# In this script, we use an {admiral} duration function to
# derive the adverse-event duration variable ADURN.
library(admiral)


# ============================================================
# Step 1: Inspect the SDTM AE domain
# ============================================================

# ------------------------------------------------------------
# 2. Check the dimensions of AE
# ------------------------------------------------------------

# dim() returns:
#
#   number of rows = number of AE records
#   number of columns = number of AE variables
#
# This gives us a quick overview of the source AE domain.
dim(ae)


# ------------------------------------------------------------
# 3. Inspect AE variable names
# ------------------------------------------------------------

# names() displays all variables contained in the AE domain.
#
# This helps us understand which SDTM variables are available
# before constructing the analysis dataset.
names(ae)


# ------------------------------------------------------------
# 4. Inspect important AE variables
# ------------------------------------------------------------

# We display a subset of clinically important AE variables.
#
# USUBJID  = Unique Subject Identifier
# AESEQ    = Sequence number within subject
# AETERM   = Reported adverse-event term
# AEDECOD  = Standardised adverse-event term
# AEBODSYS = Body-system classification
# AESEV    = Severity
# AETOXGR  = Toxicity Grade
# AESER    = Seriousness
# AEREL    = Relationship to treatment
# AEACN    = Action taken
# AEOUT    = Outcome
# AESTDTC  = AE start date
# AEENDTC  = AE end date
#
# head(10) displays the first 10 records.
ae %>%
  select(
    USUBJID,
    AESEQ,
    AETERM,
    AEDECOD,
    AEBODSYS,
    AESEV,
    AETOXGR,
    AESER,
    AEREL,
    AEACN,
    AEOUT,
    AESTDTC,
    AEENDTC
  ) %>%
  head(10)


# ============================================================
# Step 2: Bring subject-level treatment information from ADSL
# ============================================================

# ADAE needs treatment information so that adverse events
# can be analysed by treatment group.
#
# Treatment information already exists in ADSL, so we do not
# recreate it from the AE domain.
#
# Instead, we select the required subject-level variables
# from ADSL and merge them with AE using USUBJID.
adsl_ae <- adsl %>%
  select(
    USUBJID,
    TRT01P,
    TRT01A,
    TRTSDT,
    TRTEDT,
    SAFFL
  )


# ------------------------------------------------------------
# 5. Check that ADSL contains one record per subject
# ------------------------------------------------------------

# Because ADSL is a subject-level dataset, each USUBJID
# should occur only once.
#
# If a subject appears more than once here, a left_join()
# with AE could create duplicate AE records.
#
# Therefore, this is an important pre-join QC check.
adsl_ae %>%
  count(USUBJID) %>%
  filter(n > 1)


# ------------------------------------------------------------
# 6. Join AE with ADSL
# ------------------------------------------------------------

# left_join() combines the AE records with subject-level
# information from ADSL.
#
# The datasets are matched using:
#
#   USUBJID = Unique Subject Identifier
#
# The AE domain remains the primary dataset.
#
# Therefore:
#   - every AE record should remain
#   - ADSL treatment variables are added to each AE record
#
# This is why we use left_join() rather than inner_join().
adae <- ae %>%
  left_join(
    adsl_ae,
    by = "USUBJID"
  )


# ------------------------------------------------------------
# 7. Check ADAE dimensions after the join
# ------------------------------------------------------------

# The number of ADAE records should initially be the same
# as the number of AE records.
#
# If the number increases unexpectedly, this can indicate
# duplicate subject records in the dataset being joined.
dim(adae)


# ------------------------------------------------------------
# 8. Inspect the joined treatment information
# ------------------------------------------------------------

# Display AE records together with the treatment information
# brought from ADSL.
adae %>%
  select(
    USUBJID,
    AESEQ,
    AETERM,
    TRT01P,
    TRT01A,
    TRTSDT,
    TRTEDT,
    SAFFL
  ) %>%
  head(10)


# ============================================================
# Step 3: Derive Treatment-Emergent Adverse Events
# ============================================================

# ------------------------------------------------------------
# 9. Explore AE timing relative to treatment
# ------------------------------------------------------------

# An adverse event is considered treatment-emergent in this
# educational example when its start date is on or after
# the treatment start date.
#
# Here we first create a temporary logical variable:
#
#   TRUE  = AE starts on/after treatment start
#   FALSE = AE starts before treatment start
#
# This is an exploratory step before creating the final
# character flag TRTEMFL.
adae %>%
  select(
    USUBJID,
    AESEQ,
    AESTDTC,
    TRTSDT,
    TRTEDT
  ) %>%
  mutate(
    AE_AFTER_TRT = AESTDTC >= TRTSDT
  ) %>%
  count(AE_AFTER_TRT)


# ------------------------------------------------------------
# 10. Derive TRTEMFL
# ------------------------------------------------------------

# TRTEMFL = Treatment-Emergent Adverse Event Flag
#
# In this educational dataset:
#
#   Y = AE started on or after treatment start
#   N = AE started before treatment start
#
# The resulting flag can be used to restrict analyses
# to treatment-emergent adverse events.
adae <- adae %>%
  mutate(
    TRTEMFL = if_else(
      AESTDTC >= TRTSDT,
      "Y",
      "N"
    )
  )


# Check the resulting treatment-emergent AE distribution.
adae %>%
  count(TRTEMFL)


# ============================================================
# Step 4: Create analysis dates
# ============================================================

# ------------------------------------------------------------
# 11. Derive analysis start and end dates
# ------------------------------------------------------------

# ASTDT = Analysis Start Date
# AENDT = Analysis End Date
#
# For this educational example, the analysis dates are
# directly copied from the SDTM AE dates:
#
#   ASTDT = AESTDTC
#   AENDT = AEENDTC
#
# More complex clinical-trial datasets may require
# date imputation or other analysis-date derivations.
adae <- adae %>%
  mutate(
    ASTDT = AESTDTC,
    AENDT = AEENDTC
  )


# ------------------------------------------------------------
# 12. Inspect analysis dates
# ------------------------------------------------------------

adae %>%
  select(
    USUBJID,
    AESEQ,
    AESTDTC,
    AEENDTC,
    ASTDT,
    AENDT,
    TRTSDT,
    TRTEMFL
  ) %>%
  head(10)


# ============================================================
# Step 5: Derive adverse-event duration
# ============================================================

# ------------------------------------------------------------
# 13. Derive ADURN using {admiral}
# ------------------------------------------------------------

# ADURN = Analysis Duration
#
# derive_vars_duration() calculates the duration between
# the analysis start and analysis end dates.
#
# start_date = ASTDT
# end_date   = AENDT
#
# in_unit and out_unit specify that the calculation is
# performed and returned in days.
#
# This demonstrates the use of an {admiral} derivation
# function in the ADaM workflow.
adae <- adae %>%
  derive_vars_duration(
    new_var = ADURN,
    start_date = ASTDT,
    end_date = AENDT,
    in_unit = "days",
    out_unit = "days"
  )


# ------------------------------------------------------------
# 14. Inspect ADURN
# ------------------------------------------------------------

adae %>%
  select(
    USUBJID,
    AESEQ,
    ASTDT,
    AENDT,
    ADURN
  ) %>%
  head(10)


# ------------------------------------------------------------
# 15. Independent QC of ADURN
# ------------------------------------------------------------

# Calculate the duration independently from the {admiral}
# result.
#
# The expected inclusive duration is:
#
#   AENDT - ASTDT + 1
#
# We then compare the independently calculated value
# (ADURN_QC) with the {admiral}-derived value (ADURN).
#
# differences:
#   Number of records where the two calculations disagree.
#
# missing_end_dates:
#   Number of AE records without an end date.
#
# missing_durations:
#   Number of AE records without a calculated duration.
adae %>%
  mutate(
    ADURN_QC = if_else(
      !is.na(ASTDT) & !is.na(AENDT),
      as.integer(AENDT - ASTDT) + 1L,
      NA_integer_
    )
  ) %>%
  summarise(
    differences = sum(
      !is.na(ADURN_QC) &
        ADURN != ADURN_QC
    ),
    missing_end_dates = sum(is.na(AENDT)),
    missing_durations = sum(is.na(ADURN))
  )


# ============================================================
# Step 6: Understand AE severity and toxicity grade
# ============================================================

# ------------------------------------------------------------
# 16. Explore AE severity
# ------------------------------------------------------------

# AESEV describes the clinical severity of the event,
# for example:
#
#   MILD
#   MODERATE
#   SEVERE
#
# count() shows how frequently each severity category occurs.
adae %>%
  count(AESEV)


# ------------------------------------------------------------
# 17. Explore toxicity grade
# ------------------------------------------------------------

# AETOXGR contains the toxicity grade.
#
# In this synthetic dataset, grades range from 1 to 3.
#
# Toxicity grade is particularly useful when defining
# higher-grade safety outcomes such as Grade >= 3 AEs.
adae %>%
  count(AETOXGR)


# ------------------------------------------------------------
# 18. Compare severity and toxicity grade
# ------------------------------------------------------------

# This cross-tabulation allows us to understand the
# relationship between AESEV and AETOXGR.
#
# It is useful because AESEV and AETOXGR are related concepts
# but are not necessarily interchangeable in clinical-trial
# programming.
adae %>%
  count(AESEV, AETOXGR) %>%
  arrange(AESEV, AETOXGR)


# ============================================================
# Step 7: Explore treatment-emergent toxicity
# ============================================================

# ------------------------------------------------------------
# 19. Examine toxicity grades among TEAEs
# ------------------------------------------------------------

# Restrict the analysis to treatment-emergent AEs and
# display the distribution of toxicity grades.
#
# This gives us the basis for identifying higher-grade
# treatment-emergent adverse events.
adae %>%
  filter(TRTEMFL == "Y") %>%
  count(AETOXGR)


# ------------------------------------------------------------
# 20. Count Grade >= 3 TEAEs
# ------------------------------------------------------------

# Here we identify treatment-emergent AEs with toxicity
# grade 3 or higher.
#
# n() counts the number of AE records satisfying the filter.
adae %>%
  filter(
    TRTEMFL == "Y",
    AETOXGR >= 3
  ) %>%
  summarise(
    n_grade3plus = n()
  )


# ============================================================
# Step 8: Create Grade >= 3 AE flag
# ============================================================

# ------------------------------------------------------------
# 21. Derive AOCCFL
# ------------------------------------------------------------

# AOCCFL is used here as an occurrence flag for
# treatment-emergent Grade >= 3 adverse events.
#
#   Y = treatment-emergent and toxicity grade >= 3
#   N = otherwise
#
# This flag will later allow us to identify subjects
# experiencing at least one higher-grade TEAE.
adae <- adae %>%
  mutate(
    AOCCFL = if_else(
      TRTEMFL == "Y" & AETOXGR >= 3,
      "Y",
      "N"
    )
  )


# ------------------------------------------------------------
# 22. QC the Grade >= 3 flag
# ------------------------------------------------------------

# Examine the relationship between treatment-emergent
# status and the Grade >= 3 flag.
adae %>%
  count(TRTEMFL, AOCCFL)


# Compare:
#
#   grade3plus_flagged
#       = number of records flagged AOCCFL = "Y"
#
#   grade3plus_expected
#       = number of records satisfying the underlying
#         definition directly
#
# The two values should be identical.
adae %>%
  summarise(
    grade3plus_flagged = sum(AOCCFL == "Y"),
    grade3plus_expected = sum(
      TRTEMFL == "Y" & AETOXGR >= 3
    )
  )


# ============================================================
# Final ADAE Quality Control
# ============================================================


# ------------------------------------------------------------
# 23. QC: Record count unchanged from SDTM AE
# ------------------------------------------------------------

# The AE domain is the source of the ADAE records.
#
# Therefore, adding subject-level variables and analysis
# variables should not change the number of AE records.
#
# If this fails, an unexpected join duplication may have
# occurred.
stopifnot(
  nrow(adae) == nrow(ae)
)


# ------------------------------------------------------------
# 24. QC: Every ADAE subject exists in ADSL
# ------------------------------------------------------------

# Every subject in ADAE should have a corresponding subject
# in ADSL.
#
# %in% checks whether each ADAE USUBJID occurs in the
# ADSL USUBJID vector.
#
# all() confirms that every subject passes the check.
stopifnot(
  all(adae$USUBJID %in% adsl$USUBJID)
)


# ------------------------------------------------------------
# 25. QC: AESEQ uniqueness within subject
# ------------------------------------------------------------

# AESEQ is the sequence number of an AE within a subject.
#
# Therefore, the combination:
#
#   USUBJID + AESEQ
#
# should uniquely identify an AE record.
#
# We first identify any duplicate combinations.
ae_seq_check <- adae %>%
  count(USUBJID, AESEQ) %>%
  filter(n > 1)


# The check passes only when no duplicate combinations exist.
stopifnot(
  nrow(ae_seq_check) == 0
)


# ------------------------------------------------------------
# 26. QC: AE duration cannot be negative
# ------------------------------------------------------------

# If an AE has both a start date and an end date,
# the end date should not occur before the start date.
#
# Any returned record would represent a date inconsistency.
duration_check <- adae %>%
  filter(
    !is.na(ASTDT),
    !is.na(AENDT)
  ) %>%
  filter(
    AENDT < ASTDT
  )


# The check passes only when no negative durations exist.
stopifnot(
  nrow(duration_check) == 0
)


# ------------------------------------------------------------
# 27. QC: TRTEMFL derivation
# ------------------------------------------------------------

# Recalculate the treatment-emergent definition independently
# and compare it with the stored TRTEMFL value.
#
# This confirms that TRTEMFL was derived consistently.
stopifnot(
  all(
    adae$TRTEMFL ==
      if_else(
        adae$AESTDTC >= adae$TRTSDT,
        "Y",
        "N"
      )
  )
)


# ------------------------------------------------------------
# 28. QC: Grade >= 3 flag
# ------------------------------------------------------------

# Recalculate the AOCCFL definition independently.
#
# The stored flag should agree exactly with the underlying
# treatment-emergent and toxicity-grade conditions.
stopifnot(
  all(
    adae$AOCCFL ==
      if_else(
        adae$TRTEMFL == "Y" & adae$AETOXGR >= 3,
        "Y",
        "N"
      )
  )
)


# ------------------------------------------------------------
# 29. Report successful QC
# ------------------------------------------------------------

# If the script reaches this point, all stopifnot()
# statements above have passed.
cat("ADAE QC PASSED\n")


# ============================================================
# Step 9: Save the final ADAE dataset
# ============================================================

# write_csv() saves the completed ADAE dataset.
#
# The resulting file will be stored at:
#
#   data/adam/adae.csv
write_csv(
  adae,
  here("data", "adam", "adae.csv")
)


# ============================================================
# Step 10: Patient-level TEAE summary by treatment arm
# ============================================================

# The ADAE dataset is event-level:
#
#   one row = one adverse-event record
#
# But safety analyses often need patient-level results:
#
#   one patient counts only once, even if that patient
#   experienced multiple TEAEs.
#
# Therefore:
#
#   n_distinct(USUBJID)
#       = number of unique patients with at least one TEAE
#
#   n()
#       = total number of TEAE records
#
# These are deliberately different quantities.
adae %>%
  filter(TRTEMFL == "Y") %>%
  group_by(TRT01A) %>%
  summarise(
    patients_with_teae = n_distinct(USUBJID),
    ae_records = n(),
    .groups = "drop"
  )


# ============================================================

# ADAE has now been:
#
#   1. Created from SDTM AE
#   2. Joined with ADSL treatment information
#   3. Assigned treatment-emergent status
#   4. Given analysis dates
#   5. Given analysis duration using {admiral}
#   6. Checked for AE severity and toxicity grade
#   7. Assigned a Grade >= 3 occurrence flag
#   8. QC'd
#   9. Saved to data/adam/adae.csv
#  10. Summarised at the patient level
# ============================================================

