# ============================================================
# Oncology SDTM to ADaM with {admiral}
#
# File: 02_qc_sdtm.R
# Purpose: Basic SDTM quality control
# ============================================================

library(tidyverse)
library(here)

# ------------------------------------------------------------
# 1. Study-level information
# ------------------------------------------------------------

dm %>%
  count(STUDYID)

# Number of subjects
n_distinct(dm$USUBJID)

# ------------------------------------------------------------
# 2. One DM record per subject
# ------------------------------------------------------------

stopifnot(
  nrow(dm) == n_distinct(dm$USUBJID)
)

# ------------------------------------------------------------
# 3. Planned treatment allocation
# ------------------------------------------------------------

dm %>%
  count(ARMCD, ARM)

# ------------------------------------------------------------
# 4. Actual treatment received
# ------------------------------------------------------------

dm %>%
  count(ACTARMCD, ACTARM)

# ------------------------------------------------------------
# 5. Planned vs actual treatment
# ------------------------------------------------------------

dm %>%
  count(ARM, ACTARM)

# ------------------------------------------------------------
# 6. Subjects in each SDTM domain
# ------------------------------------------------------------

domain_subjects <- tibble(
  domain = c("DM", "AE", "EX", "LB", "VS"),
  records = c(
    nrow(dm),
    nrow(ae),
    nrow(ex),
    nrow(lb),
    nrow(vs)
  ),
  subjects = c(
    n_distinct(dm$USUBJID),
    n_distinct(ae$USUBJID),
    n_distinct(ex$USUBJID),
    n_distinct(lb$USUBJID),
    n_distinct(vs$USUBJID)
  )
)

domain_subjects

# ------------------------------------------------------------
# 7. Check that domain subjects exist in DM
# ------------------------------------------------------------

ae_not_in_dm <- setdiff(
  unique(ae$USUBJID),
  unique(dm$USUBJID)
)

ex_not_in_dm <- setdiff(
  unique(ex$USUBJID),
  unique(dm$USUBJID)
)

lb_not_in_dm <- setdiff(
  unique(lb$USUBJID),
  unique(dm$USUBJID)
)

vs_not_in_dm <- setdiff(
  unique(vs$USUBJID),
  unique(dm$USUBJID)
)

ae_not_in_dm
ex_not_in_dm
lb_not_in_dm
vs_not_in_dm


# ============================================================
# Oncology SDTM to ADaM with {admiral}
#
# File: 02_qc_sdtm.R
# Purpose:
#   Perform basic quality-control checks on the imported
#   SDTM datasets before creating ADaM datasets.
#
# The checks in this script focus on:
#   1. Study identification
#   2. Subject counts
#   3. DM subject-level uniqueness
#   4. Planned treatment allocation
#   5. Actual treatment received
#   6. Planned vs actual treatment
#   7. Cross-domain subject consistency
#
# Important:
#   This is a basic educational QC script.
#   It does not represent the complete validation process
#   required for a regulatory clinical-trial submission.
# ============================================================


# ------------------------------------------------------------
# 1. Load required R packages
# ------------------------------------------------------------

# {tidyverse} provides functions for data manipulation,
# summarisation, counting, and working with data frames.
library(tidyverse)

# {here} creates reproducible project-relative file paths.
# It is included here for consistency with the other project
# scripts, although this particular QC script does not
# currently use a file path directly.
library(here)


# ------------------------------------------------------------
# 2. Study-level information
# ------------------------------------------------------------

# STUDYID identifies the clinical study.
#
# count(STUDYID) tells us how many records belong to each
# study identifier.
#
# In this project we expect one study.
dm %>%
  count(STUDYID)


# n_distinct() counts the number of unique values.
#
# Here we use it to determine the number of unique subjects
# in the Demographics (DM) domain.
#
# USUBJID = Unique Subject Identifier
n_distinct(dm$USUBJID)


# ------------------------------------------------------------
# 3. Check that DM contains one record per subject
# ------------------------------------------------------------

# The SDTM DM domain is a subject-level domain.
#
# Therefore, each subject should normally have exactly
# one DM record.
#
# nrow(dm) = total number of DM records
# n_distinct(dm$USUBJID) = number of unique subjects
#
# If these two numbers are different, at least one subject
# appears more than once in DM.
#
# stopifnot() stops the R script if the condition is FALSE.
# This makes the check an actual QC test rather than just
# displaying a result.
stopifnot(
  nrow(dm) == n_distinct(dm$USUBJID)
)


# ------------------------------------------------------------
# 4. Check planned treatment allocation
# ------------------------------------------------------------

# ARMCD = Planned Treatment Code
# ARM   = Planned Treatment Description
#
# count() shows how many subjects were assigned to each
# planned treatment arm.
#
# This allows us to verify the expected treatment allocation.
dm %>%
  count(ARMCD, ARM)


# ------------------------------------------------------------
# 5. Check actual treatment received
# ------------------------------------------------------------

# ACTARMCD = Actual Treatment Code
# ACTARM   = Actual Treatment Description
#
# These variables describe the treatment actually received
# by the subject.
#
# Comparing actual treatment with planned treatment is
# important because a subject may not always receive the
# treatment originally assigned.
dm %>%
  count(ACTARMCD, ACTARM)


# ------------------------------------------------------------
# 6. Compare planned and actual treatment
# ------------------------------------------------------------

# This cross-tabulation compares:
#
#   ARM     = planned treatment
#   ACTARM  = actual treatment received
#
# If planned and actual treatment are identical for every
# subject, the counts should appear only on the diagonal
# of the resulting table.
#
# Any off-diagonal combination indicates that at least some
# subjects received a treatment different from the planned
# treatment assignment.
dm %>%
  count(ARM, ACTARM)


# ------------------------------------------------------------
# 7. Summarise subjects and records across SDTM domains
# ------------------------------------------------------------

# Different SDTM domains contain different types of
# observations.
#
# For example:
#   DM = usually one record per subject
#   AE = potentially many records per subject
#   EX = potentially many exposure records per subject
#   LB = potentially many laboratory records per subject
#   VS = potentially many vital-sign records per subject
#
# Therefore, the number of records and number of subjects
# can differ substantially between domains.
#
# Here we create a small QC summary containing:
#
#   domain  = SDTM domain name
#   records = total number of records
#   subjects = number of unique subjects
domain_subjects <- tibble(
  domain = c("DM", "AE", "EX", "LB", "VS"),
  
  records = c(
    nrow(dm),
    nrow(ae),
    nrow(ex),
    nrow(lb),
    nrow(vs)
  ),
  
  subjects = c(
    n_distinct(dm$USUBJID),
    n_distinct(ae$USUBJID),
    n_distinct(ex$USUBJID),
    n_distinct(lb$USUBJID),
    n_distinct(vs$USUBJID)
  )
)


# Display the QC summary.
domain_subjects


# ------------------------------------------------------------
# 8. Check that AE subjects exist in DM
# ------------------------------------------------------------

# setdiff() identifies values that occur in the first vector
# but do not occur in the second vector.
#
# Here we ask:
#
# "Which subjects appear in AE but are not present in DM?"
#
# DM is the subject-level reference domain, so every subject
# appearing in another domain should normally have a
# corresponding subject record in DM.
ae_not_in_dm <- setdiff(
  unique(ae$USUBJID),
  unique(dm$USUBJID)
)


# ------------------------------------------------------------
# 9. Check that EX subjects exist in DM
# ------------------------------------------------------------

# The same logic is applied to the Exposure (EX) domain.
#
# Any returned subject ID would indicate that EX contains
# a subject who cannot be found in DM.
ex_not_in_dm <- setdiff(
  unique(ex$USUBJID),
  unique(dm$USUBJID)
)


# ------------------------------------------------------------
# 10. Check that LB subjects exist in DM
# ------------------------------------------------------------

# Check the Laboratory (LB) domain against the subject-level
# DM domain.
lb_not_in_dm <- setdiff(
  unique(lb$USUBJID),
  unique(dm$USUBJID)
)


# ------------------------------------------------------------
# 11. Check that VS subjects exist in DM
# ------------------------------------------------------------

# Check the Vital Signs (VS) domain against DM.
vs_not_in_dm <- setdiff(
  unique(vs$USUBJID),
  unique(dm$USUBJID)
)


# ------------------------------------------------------------
# 12. Display subjects not found in DM
# ------------------------------------------------------------

# Ideally, all four results should be character(0).
#
# character(0) means:
#   "No subject IDs were found that violate the check."
#
# If an ID appears here, that subject exists in the
# corresponding SDTM domain but does not exist in DM.
ae_not_in_dm
ex_not_in_dm
lb_not_in_dm
vs_not_in_dm


# ============================================================
# End of 02_qc_sdtm.R
#
# The basic SDTM QC checks have now been performed.
#
# Next:
#   03_create_adsl.R
#
# This script will use the validated DM data to create the
# subject-level ADaM dataset (ADSL).
# ============================================================
