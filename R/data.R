library(readxl)
library(janitor)
library(stringi)
library(tidyverse)

library(nlme)
library(ggeffects)

library(ggplot2)

data_path <- "data/20250321_POVEDANO.xlsx"

as_gender <- function(x) factor(x, levels=c("F", "M"))

as_sma_type <- function(x) {
  x |>
    case_match(
      "sma_type/type1" ~ "SMA-I",
      "sma_type/type2" ~ "SMA-II",
      "sma_type/type3" ~ "SMA-III",
      "sma_type/type4" ~ "SMA-IV",
    ) |>
    factor(levels = c("SMA-II", "SMA-III"))
}

as_smn2_copy_number <- function(x) {
  x |>
    case_match(
      "smn2_copy_number/1" ~ "1",
      "smn2_copy_number/2" ~ "2",
      "smn2_copy_number/3" ~ "3",
      "smn2_copy_number/4" ~ "4",
      "smn2_copy_number/>4" ~ ">4",
      "smn2_copy_number/uknown" ~ NA,
    ) |>
    factor(levels=c("1", "2", "3", "4", ">4"))
}

as_treatment_group <- function(x) factor(x, levels = c("NO TREATED", "NUS", "RIS"))

datos_ccaa <- read_xlsx(data_path, sheet="CCAA") |>
  clean_names() |>
  mutate(across(ccaa, ~stri_trans_general(.x, "Latin-ASCII") |> as.factor()))

datos_pacientes <- read_xlsx(data_path, sheet="Clinical Profile") |>
  clean_names()

datos_alsfrs <- read_xlsx(data_path, sheet="ALSFRS") |>
  clean_names() |>
  select(patient_id, assessment_date = "assessment_d", score)
  
datos_ek2 <- read_xlsx(data_path, sheet="Ek2") |>
  clean_names() |>
  select(patient_id, assessment_date = "assessment_d", score)

datos_escalas <- read_xlsx(data_path, sheet="Escalas") |>
  clean_names() |>
  select(patient_id, assessment_date, scale, score) |>
  bind_rows(datos_alsfrs |> mutate(scale="ALSFRS_R")) |>
  bind_rows(datos_ek2 |> mutate(scale="EK2"))

datos_respi <- read_xlsx(data_path, sheet="Pulmonary_Function_and_Vaccines") |>
  clean_names()

pacientes <- datos_pacientes |>
  left_join(datos_ccaa, by = "patient_id") |>
  mutate(
    across(gender, as_gender),
    across(sma_type, as_sma_type),
    across(smn2num, as_smn2_copy_number),
    treated = tx_classification != "NO TREATED",
    age = coalesce(
      floor((death_d - birth_d) / dyears(1)),
      floor((now() - birth_d) / dyears(1)),
    ),
    txgroup = as_treatment_group(tx_classification),
    treatment_start_age = floor((treatment_start_d - birth_d) / dyears(1)),
  )

pacientes_ccaa <- pacientes |>
  mutate(ccaa = factor(ccaa) |> fct_lump_min(10))

datos_escalas <- datos_escalas |>
  left_join(
    pacientes |> select(
      patient_id, txgroup, ccaa, gender, birth_d, sma_type, smn2num, treatment_start_age
    ),
    by = "patient_id"
  ) |>
  mutate(
    age = floor((assessment_date - birth_d) / dyears(1))
  ) |>
  mutate(
    years_from_baseline = (assessment_date - min(assessment_date, na.rm = TRUE)) / dyears(1),
    .by = c(patient_id, scale)
  ) |>
  slice_head(n=1, by = c(patient_id, assessment_date, scale))
