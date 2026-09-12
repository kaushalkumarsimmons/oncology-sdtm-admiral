# ============================================================
# Oncology SDTM to ADaM with {admiral}
#
# File: 01_import_sdtm.R
# Purpose:
#   Import the raw SDTM domains used in this project and
#   perform initial structural exploration of the datasets.
#
# Study domains:
#   DM = Demographics
#   AE = Adverse Events
#   EX = Exposure
#   LB = Laboratory Tests
#   VS = Vital Signs
#
# Note:
#   This script performs data import and initial exploration.
#   Formal SDTM quality-control checks are performed separately
#   in 02_qc_sdtm.R.
# ============================================================


# ------------------------------------------------------------
# 1. Load required R packages
# ------------------------------------------------------------

# {tidyverse} provides functions for data import, manipulation,
# exploration, and transformation. In this script we use
# read_csv(), glimpse(), select(), and count().
library(tidyverse)

# {here} creates project-relative file paths.
# This avoids using machine-specific paths such as
# "C:/Users/..." and makes the project easier to reproduce
# on another computer or through GitHub.
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

# EX: Exposure domain
# Contains information about study treatment exposure,
# including treatment, dose, route, frequency, and
# exposure dates.
ex <- read_csv(
  here("data", "raw", "EX.csv"),
  show_col_types = FALSE
)

# LB: Laboratory Tests domain
# Contains laboratory measurements collected during
# the clinical study, together with test names, results,
# units, reference ranges, visits, and dates.
lb <- read_csv(
  here("data", "raw", "LB.csv"),
  show_col_types = FALSE
)

# VS: Vital Signs domain
# Contains measurements such as vital signs collected
# during study visits, together with measurement dates
# and visit information.
vs <- read_csv(
  here("data", "raw", "VS.csv"),
  show_col_types = FALSE
)


# ------------------------------------------------------------
# 3. Confirm that the expected raw files are available
# ------------------------------------------------------------

# list.files() displays the files currently available in
# the raw SDTM directory.
#
# This is a simple first check that the expected input
# datasets are present before continuing with the analysis.
list.files(
  here("data", "raw")
)


# ------------------------------------------------------------
# 4. Inspect dataset dimensions
# ------------------------------------------------------------

# dim() returns the number of rows and columns in a dataset.
#
# Rows represent observations/records.
# Columns represent variables.
#
# These checks help us understand the size of each SDTM domain
# immediately after import.
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


# ============================================================
# End of 01_import_sdtm.R
#
# The raw SDTM domains are now imported and their basic
# structure has been explored.
#
# Formal data-quality checks are performed in:
#   R/02_qc_sdtm.R
# ============================================================