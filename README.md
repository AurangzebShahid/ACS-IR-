# ACS-IR: Stata Data Management Pipeline

Stata code for compiling, cleaning, validating and analysing data from the ACS-IR
(antenatal corticosteroids, implementation research) project, a WHO-funded
study in Pakistan. The code merges and appends data from multiple study forms,
creates analysis variables, runs data quality checks, and exports an analysis-ready
dataset that feeds Power BI dashboards for near real-time monitoring.

> **This repository contains code only. No participant data, identifiers or
> study datasets are included or may be committed.**

## Repository contents

| File | Purpose |
|---|---|
| `1. ACSIR  PHASE I_Data_Compilation.do` | Phase I: imports each form, removes duplicates, reshapes and merges into one database |
| `1.2. ACSIR  Phase_I_Variable_Creation.do` | Phase I: derives dates, gestational-age and facility variables |
| `1.3. ACSIR  Phase_I_Outcome_Analysis.do` | Phase I: reshapes to one row per baby, builds outcome and coverage variables, applies exclusion rules, exports the final analysis dataset |
| `1.4. ACSIR Phase_I_Data Quality Checks.do` | Phase I: data quality checks |
Phase II
| `2.1  ACSIR Phase_ II_Data.do compilation.do` | Phase II: data compilation |
| `2.2 ACS-IR Phase_II_Data Quality Control Checks.do` | Phase II: QC checks that flag anomalies, missing values and cross-form inconsistencies for monthly review |
| `2.3 ACSIR_Phase_II_Monthly Progress Review.do` | Phase II: monthly progress indicators |

## Run order

Run the scripts in numeric order within each phase. Each script reads the output
of the previous one.

```
Phase I   1. Compilation -> 1.2 Variable creation -> 1.3 Outcome analysis -> (final dataset)
                                                   -> 1.4 Data quality checks
Phase II  2.1 Compilation -> 2.2 QC checks -> 2.3 Monthly progress review
```

## Setup

1. Install Stata [version, e.g. 17].
2. Place the study data in a folder **outside this repository**.
3. Edit the working directory at the top of each script. The scripts currently use
   hardcoded paths. Set it once and reuse it:

   ```stata
   global root "[path to your local data folder]"
   cd "$root"
   ```

## Inputs and outputs

- **Inputs:** raw exports of the study forms (not included).
- **Outputs:** an analysis-ready long-format dataset (one row per baby), QC flag
  lists, and tables used in monitoring reports and dashboards.

## Data protection

- Do not commit `.dta`, `.xlsx`, `.csv`, `.log` or `.pbix` files, or any file
  containing participant identifiers (PIDs, phone numbers, national ID numbers) or
  staff names.
- Keep any mapping of tablet or user codes to people outside the repository.

## Conventions

- Missing and invalid codes (for example 88/99 and 8888/9999) are recoded to
  missing before analysis.
- Analysis excludes births below 26 weeks by earliest ultrasound, births under
  500 g where no ultrasound is available, and births outside the network of care.
- `capture` hides command output in Stata. Use `capture noisily` when you need to see it.

## Author

Aurangzeb, Data Manager.
Legacy code by [WHO Technical Team, Geneva].

## Licence

[Choose a licence, or state "All rights reserved" if the code should not be reused.]

