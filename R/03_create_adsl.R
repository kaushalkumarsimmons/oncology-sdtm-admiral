# ============================================================
# Oncology SDTM to ADaM with {admiral}
#
# File: 03_create_adsl.R
#
# Purpose:
#   Create the Analysis Subject-Level Dataset (ADSL) from
#   the SDTM Demographics (DM) domain.
#
# ADSL is the main subject-level ADaM dataset.
# It contains one record per subject and combines important
# demographic, treatment, and analysis-population variables.
#
# Main derivations in this script:
#   - TRT01P   = Planned Treatment
#   - TRT01A   = Actual Treatment
#   - TRTSDT   = Treatment Start Date
#   - TRTEDT   = Treatment End Date
#   - TRTDURD  = Treatment Duration in Days
#   - SAFFL    = Safety Population Flag
#
# The dataset is then QC'd and saved as:
#   data/adam/adsl.csv
# ============================================================


# ------------------------------------------------------------
# 1. Load required R packages
# ------------------------------------------------------------

# {tidyverse} provides functions for selecting variables,
# creating new variables, counting observations, and
# summarising data.
library(tidyverse)

# {here} creates project-relative file paths.
# This makes the project reproducible across different
# computers and environments.
library(here)

# {admiral} provides functions specifically designed for
# creating ADaM datasets from clinical-trial SDTM data.
#
# In this script, we use {admiral} to derive treatment
# duration (TRTDURD).
library(admiral)


# ------------------------------------------------------------
# 2. Select subject-level variables from DM
# ------------------------------------------------------------

# The SDTM DM domain contains one record per subject.
#
# We select the variables needed for the ADSL dataset.
#
# The selected variables include:
#   - Study and subject identifiers
#   - Demographics
#   - Planned and actual treatment
#   - Important study dates
#   - Death information
#
# The resulting dataset will still contain one record
# per subject.
adsl <- dm %>%
  select(
    STUDYID,
    USUBJID,
    SUBJID,
    SITEID,
    AGE,
    AGEU,
    SEX,
    RACE,
    ETHNIC,
    ARMCD,
    ARM,
    ACTARMCD,
    ACTARM,
    COUNTRY,
    RFSTDTC,
    RFENDTC,
    RFXSTDTC,
    RFXENDTC,
    RFICDTC,
    RFPENDTC,
    DTHDTC,
    DTHFL
  )


# ------------------------------------------------------------
# 3. Derive treatment variables
# ------------------------------------------------------------

# In ADaM, TRT01P represents the first planned treatment
# period/treatment.
#
# TRT01A represents the first actual treatment received.
#
# Here:
#   TRT01P = ARM
#   TRT01A = ACTARM
#
# ARM and ACTARM come from SDTM DM.
#
# This creates analysis-ready treatment variables while
# preserving the original SDTM variables.
adsl <- adsl %>%
  mutate(
    TRT01P = ARM,
    TRT01A = ACTARM
  )


# ------------------------------------------------------------
# 4. Check planned treatment
# ------------------------------------------------------------

# count() shows how many subjects belong to each planned
# treatment group.
#
# This provides a quick check that the treatment assignment
# was transferred correctly from ARM to TRT01P.
adsl %>%
  count(TRT01P)


# ------------------------------------------------------------
# 5. Check actual treatment
# ------------------------------------------------------------

# This performs the same check for actual treatment.
#
# ACTARM from SDTM DM should correspond to TRT01A in ADSL.
adsl %>%
  count(TRT01A)


# ------------------------------------------------------------
# 6. Derive treatment dates
# ------------------------------------------------------------

# RFXSTDTC = Date/time of first exposure to study treatment
# RFXENDTC = Date/time of last exposure to study treatment
#
# For this educational project, these variables are used
# as the treatment start and treatment end dates in ADSL.
#
# TRTSDT = Treatment Start Date
# TRTEDT = Treatment End Date
#
# The dates are already stored as Date variables after import,
# so they can be assigned directly.
adsl <- adsl %>%
  mutate(
    TRTSDT = RFXSTDTC,
    TRTEDT = RFXENDTC
  )


# ------------------------------------------------------------
# 7. Inspect treatment dates
# ------------------------------------------------------------

# Display the first 10 subjects with their treatment
# assignment and treatment dates.
#
# This is a visual check before deriving treatment duration.
adsl %>%
  select(
    USUBJID,
    TRT01P,
    TRT01A,
    TRTSDT,
    TRTEDT
  ) %>%
  head(10)


# ------------------------------------------------------------
# 8. Derive treatment duration using {admiral}
# ------------------------------------------------------------

# derive_var_trtdurd() is an {admiral} function specifically
# designed to derive treatment duration.
#
# It calculates the duration between the treatment start
# and treatment end dates.
#
# The function creates the variable:
#
#   TRTDURD = Treatment Duration in Days
#
# For this project, the resulting duration follows the
# inclusive convention:
#
#   TRTDURD = TRTEDT - TRTSDT + 1
#
# Using {admiral} here demonstrates how a Pharmaverse
# function can be used instead of manually calculating
# an ADaM variable.
adsl <- adsl %>%
  derive_var_trtdurd(
    start_date = TRTSDT,
    end_date = TRTEDT
  )


# ------------------------------------------------------------
# 9. Inspect treatment duration
# ------------------------------------------------------------

# Display treatment dates together with the newly derived
# treatment duration.
adsl %>%
  select(
    USUBJID,
    TRT01P,
    TRT01A,
    TRTSDT,
    TRTEDT,
    TRTDURD
  ) %>%
  head(10)


# summary() provides descriptive statistics for TRTDURD.
#
# It shows:
#   - minimum
#   - first quartile
#   - median
#   - mean
#   - third quartile
#   - maximum
#
# This gives us a quick overview of treatment exposure
# duration across subjects.
summary(adsl$TRTDURD)


# ------------------------------------------------------------
# 10. Derive the Safety Population Flag
# ------------------------------------------------------------

# SAFFL identifies whether a subject belongs to the
# Safety Analysis Set.
#
# For this educational dataset, we define a subject as
# belonging to the safety population when a treatment
# start date is available.
#
#   SAFFL = "Y"  -> subject has a treatment start date
#   SAFFL = "N"  -> treatment start date is missing
#
# Note:
#   This is a simplified educational definition.
#   Production clinical-trial programming should follow
#   the study-specific Statistical Analysis Plan (SAP).
adsl <- adsl %>%
  mutate(
    SAFFL = if_else(
      !is.na(TRTSDT),
      "Y",
      "N"
    )
  )


# ------------------------------------------------------------
# 11. Check the Safety Population Flag
# ------------------------------------------------------------

# Count subjects by SAFFL to see how many subjects are
# included in the safety population.
adsl %>%
  count(SAFFL)


# ============================================================
# Final ADSL Quality Control
# ============================================================


# ------------------------------------------------------------
# 12. QC: One record per subject
# ------------------------------------------------------------

# ADSL is a subject-level analysis dataset.
#
# Therefore, there should be exactly one record for every
# subject.
#
# If the number of rows differs from the number of unique
# USUBJID values, duplicate subject records exist.
#
# stopifnot() stops the script if the condition is FALSE.
stopifnot(
  nrow(adsl) == n_distinct(adsl$USUBJID)
)


# ------------------------------------------------------------
# 13. QC: Expected number of subjects
# ------------------------------------------------------------

# ADSL was created directly from DM, which contains one
# record per subject.
#
# Therefore, the number of ADSL records should equal the
# number of DM records.
stopifnot(
  nrow(adsl) == nrow(dm)
)


# ------------------------------------------------------------
# 14. QC: Planned treatment counts
# ------------------------------------------------------------

# Re-check the planned treatment distribution after
# creating ADSL.
#
# This confirms that treatment assignment has been
# transferred correctly.
adsl %>%
  count(TRT01P)


# ------------------------------------------------------------
# 15. QC: Actual treatment counts
# ------------------------------------------------------------

# Re-check the actual treatment distribution.
adsl %>%
  count(TRT01A)


# ------------------------------------------------------------
# 16. QC: Independent treatment-duration calculation
# ------------------------------------------------------------

# Here we independently calculate treatment duration
# without using the {admiral} function.
#
# The independent calculation is:
#
#   End Date - Start Date + 1
#
# This is useful because it allows us to compare the
# {admiral}-derived TRTDURD against an independently
# calculated value.
#
# If the number of differences is zero, the two methods
# agree for all subjects.
adsl %>%
  mutate(
    TRTDURD_QC = as.integer(TRTEDT - TRTSDT) + 1
  ) %>%
  summarise(
    differences = sum(TRTDURD != TRTDURD_QC)
  )


# ------------------------------------------------------------
# 17. QC: Safety population
# ------------------------------------------------------------

# Check the number of subjects in each safety population
# category.
#
# We expect subjects with a valid treatment start date
# to have SAFFL = "Y".
adsl %>%
  count(SAFFL)


# ------------------------------------------------------------
# 18. QC: Treatment date completeness
# ------------------------------------------------------------

# Check whether treatment start or treatment end dates
# are missing.
#
# sum(is.na(...)) counts the number of missing values.
#
# A value of zero means that no subjects have a missing
# treatment date.
adsl %>%
  summarise(
    TRTSDT_missing = sum(is.na(TRTSDT)),
    TRTEDT_missing = sum(is.na(TRTEDT))
  )


# ------------------------------------------------------------
# 19. Save the final ADSL dataset
# ------------------------------------------------------------

# write_csv() saves the completed ADSL dataset as a CSV file.
#
# here() constructs the project-relative path:
#
#   data/adam/adsl.csv
#
# This creates the ADaM dataset that will be used by
# downstream analysis programs.
write_csv(
  adsl,
  here("data", "adam", "adsl.csv")
)


# ------------------------------------------------------------
# 20. Confirm that the output file exists
# ------------------------------------------------------------

# file.exists() returns TRUE when the expected file exists
# at the specified location.
#
# TRUE confirms that the ADSL dataset was successfully
# written to disk.
file.exists(
  here("data", "adam", "adsl.csv")
)


# ============================================================
# End of 03_create_adsl.R
#
# ADSL has now been:
#   1. Created from SDTM DM
#   2. Enriched with analysis treatment variables
#   3. Given treatment dates
#   4. Given treatment duration using {admiral}
#   5. Assigned a safety population flag
#   6. QC'd
#   7. Saved to data/adam/adsl.csv
#
# Next:
#   04_create_adae.R
#
# The ADAE program will use SDTM AE together with ADSL
# treatment information to create the Adverse Events
# Analysis Dataset.
# ============================================================
