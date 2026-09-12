# Oncology Clinical Trial Analysis: SDTM to ADaM with `{admiral}`

A small reproducible R workflow for transforming synthetic oncology SDTM data into ADaM datasets and performing safety analysis.

## Workflow

```text
SDTM DM + AE
     ↓
ADSL + ADAE
     ↓
Quality Control
     ↓
Safety Analysis
     ↓
Tables + Figures
```

## Data

Synthetic oncology clinical-trial dataset with **120 subjects** and three treatment groups.

**Educational use only — not real clinical-trial evidence.**

## ADaM datasets

- **ADSL** — Subject-Level Analysis Dataset
- **ADAE** — Adverse Events Analysis Dataset

## Safety analysis

- TEAE incidence
- Grade ≥3 TEAE
- Serious TEAE
- Treatment-related TEAE
- Top TEAE preferred terms
- AE severity

## Results

### Key Safety Events

![Key safety event incidence](output/figures/02_safety_event_incidence.png)

### Top 10 Treatment-Emergent Adverse Events

![Top 10 TEAEs](output/figures/03_top_teae_preferred_terms.png)

## Tools

- R
- `{admiral}`
- `{tidyverse}`
- `{here}`

This project demonstrates a reproducible **SDTM → ADaM → safety analysis** workflow for clinical statistical programming.