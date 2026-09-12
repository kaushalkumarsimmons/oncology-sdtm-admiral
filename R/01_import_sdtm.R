# ============================================================
# Oncology SDTM to ADaM with {admiral}
# Purpose:
#   Import the raw SDTM domains used and perform initial structural exploration of the datasets.
#
# Study domains:
#   DM = Demographics
#   AE = Adverse Events
# ------------------------------------------------------------
# 1. Load required R packages
# ------------------------------------------------------------
library(tidyverse)

# {here} creates project-relative file paths.
library(here)
# ------------------------------------------------------------
# 2. Import raw SDTM datasets
# ------------------------------------------------------------

# DM: Demographics domain
# Contains one record per study subject and includes
# demographic information, treatment assignment, and
# important subject-level reference dates.
dm <- read_csv(
  here("data", "raw", "DM.csv"),
  show_col_types = FALSE
)

# AE: Adverse Events domain
# Contains records describing adverse events experienced
# by study subjects, including severity, toxicity grade,
# seriousness, relationship to treatment, and dates.
ae <- read_csv(
  here("data", "raw", "AE.csv"),
  show_col_types = FALSE
)

# ------------------------------------------------------------
# 3. Confirm that the expected raw files are available
# ------------------------------------------------------------

# list.files() displays the files currently available in
# the raw SDTM directory.

list.files(
  here("data", "raw")
)


# ------------------------------------------------------------
# 4. Inspect dataset dimensions
# ------------------------------------------------------------

dim(dm)
dim(ae)
dim(ex)
dim(lb)
dim(vs)


# ------------------------------------------------------------
# 5. Inspect variable names
# ------------------------------------------------------------

# names() returns the variable names contained in each
# SDTM domain.
#
# This allows us to understand the structure of the source
# datasets before deriving ADaM datasets.
names(dm)
names(ae)
names(ex)
names(lb)
names(vs)


# ------------------------------------------------------------
# 6. Inspect the structure and data types
# ------------------------------------------------------------

# glimpse() provides a compact overview of each dataset.
#
# It shows:
#   - variable names
#   - variable data types
#   - example values
#
# This is useful for identifying whether variables such as
# dates, numeric measurements, and categorical variables
# have been imported with the expected data types.
glimpse(dm)
glimpse(ae)
glimpse(ex)
glimpse(lb)
glimpse(vs)


# ------------------------------------------------------------
# 7. Explore the treatment structure
# ------------------------------------------------------------

# ARM represents the planned treatment assignment.
#
# count() calculates how many subjects belong to each
# planned treatment arm.
dm %>%
  count(ARM)


# ACTARM represents the actual treatment received.
#
# Comparing ARM and ACTARM is important because a subject's
# planned treatment and actual treatment may differ.
dm %>%
  count(ACTARM)


# ------------------------------------------------------------
# 8. Inspect key subject-level treatment and date variables
# ------------------------------------------------------------

# Select a small set of clinically important variables
# from the Demographics domain for an initial inspection.
#
# USUBJID  = Unique Subject Identifier
# SUBJID   = Subject Identifier
# RFSTDTC  = Study Reference Start Date
# RFENDTC  = Study Reference End Date
# ARM      = Planned Treatment
# ACTARM   = Actual Treatment
#
# head(20) displays the first 20 subjects so that we can
# visually inspect the imported values.
dm %>%
  select(
    STUDYID,
    USUBJID,
    SUBJID,
    RFSTDTC,
    RFENDTC,
    ARM,
    ACTARM
  ) %>%
  head(20)



# Formal data-quality checks are performed in:
#   R/02_qc_sdtm.R
# ============================================================
