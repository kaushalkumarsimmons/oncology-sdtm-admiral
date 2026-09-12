# Oncology SDTM to ADaM with {admiral}
#
# File: 02_qc_sdtm.R
#
# Purpose:
#   Perform basic quality-control checks on the SDTM DM and AE
#   datasets before creating the ADaM datasets.
#
# Domains used in this project:
#   DM = Demographics
#   AE = Adverse Events
#
# QC checks:
#   1. Study identification
#   2. Subject counts
#   3. DM subject-level uniqueness
#   4. Planned treatment allocation
#   5. Actual treatment received
#   6. Planned vs actual treatment
#   7. DM and AE subject consistency

# ------------------------------------------------------------
# 1. Load required R packages
# ------------------------------------------------------------

library(tidyverse)
library(here)


# ------------------------------------------------------------
# 2. Study-level information
# ------------------------------------------------------------

# Verify the study identifier in DM.
dm %>%
  count(STUDYID)


# Number of unique subjects in DM.
n_distinct(dm$USUBJID)


# ------------------------------------------------------------
# 3. Check that DM contains one record per subject
# ------------------------------------------------------------

# DM is a subject-level SDTM domain.
#
# Therefore, each subject should normally have one DM record.

stopifnot(
  nrow(dm) == n_distinct(dm$USUBJID)
)


# ------------------------------------------------------------
# 4. Check planned treatment allocation
# ------------------------------------------------------------

# ARMCD = Planned Treatment Code
# ARM   = Planned Treatment Description

dm %>%
  count(ARMCD, ARM)


# ------------------------------------------------------------
# 5. Check actual treatment received
# ------------------------------------------------------------

# ACTARMCD = Actual Treatment Code
# ACTARM   = Actual Treatment Description

dm %>%
  count(ACTARMCD, ACTARM)


# ------------------------------------------------------------
# 6. Compare planned and actual treatment
# ------------------------------------------------------------

# Compare planned treatment with actual treatment received.

dm %>%
  count(ARM, ACTARM)


# ------------------------------------------------------------
# 7. Summarise the two SDTM domains
# ------------------------------------------------------------

# The project uses only DM and AE.
#
# DM is generally one record per subject, whereas AE may
# contain multiple records per subject.

domain_subjects <- tibble(
  domain = c("DM", "AE"),

  records = c(
    nrow(dm),
    nrow(ae)
  ),

  subjects = c(
    n_distinct(dm$USUBJID),
    n_distinct(ae$USUBJID)
  )
)


# Display domain-level QC summary.
domain_subjects


# ------------------------------------------------------------
# 8. Check that AE subjects exist in DM
# ------------------------------------------------------------

# Every subject appearing in AE should also have a
# corresponding subject record in DM.

ae_not_in_dm <- setdiff(
  unique(ae$USUBJID),
  unique(dm$USUBJID)
)


# Display any AE subjects not found in DM.
#
# Expected result:
#   character(0)

ae_not_in_dm


# ------------------------------------------------------------
# 9. Final QC check
# ------------------------------------------------------------

# Confirm that no AE subject is missing from DM.

stopifnot(
  length(ae_not_in_dm) == 0
)

cat("SDTM DM and AE QC PASSED\n")
