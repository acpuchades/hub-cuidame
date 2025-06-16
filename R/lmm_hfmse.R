source("R/data.R")

hfmse.data <- datos_escalas |>
  filter(scale == "HFMSE") |>
  select(
    score, patient_id, ccaa, gender, age,
    sma_type, smn2num, treatment_start_age,
    txgroup, years_from_baseline
  ) |>
  mutate(across(patient_id, as.factor)) |>
  filter(n() >= 2, .by=patient_id) |>
  drop_na()

hfmse.fit0 <- lme(
  score ~ gender + smn2num + sma_type + txgroup + treatment_start_age + age +
    treatment_start_age:age + txgroup:age,
  random = ~ 1 | patient_id,
  data = hfmse.data
)

hfmse.fit1 <- lme(
  score ~ gender + smn2num + sma_type + txgroup + treatment_start_age + age +
    treatment_start_age:age + txgroup:age,
  random = ~ age | patient_id,
  data = hfmse.data
)

anova(hfmse.fit0, hfmse.fit1)

hfmse.fit2 <- lme(
  score ~ gender + smn2num + sma_type + txgroup + treatment_start_age + age +
    treatment_start_age:age + txgroup:age,
  random = ~ age | ccaa/patient_id,
  data = hfmse.data,
  control = lmeControl(opt="optim", maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit1, hfmse.fit2)

hfmse.fit3 <- lme(
  score ~ gender + smn2num + sma_type + txgroup + treatment_start_age + age +
    treatment_start_age:age + txgroup:age,
  random = ~age | ccaa/patient_id,
  weights = varIdent(form=~1 | txgroup),
  data = hfmse.data
)

anova(hfmse.fit2, hfmse.fit3)

hfmse.fit4 <- lme(
  score ~ gender + smn2num + sma_type + txgroup + treatment_start_age + age +
    treatment_start_age:age + txgroup:age,
  random = ~age | ccaa/patient_id,
  weights = varIdent(form=~1 | txgroup),
  correlation = corCAR1(form=~years_from_baseline | ccaa/patient_id),
  data = hfmse.data,
  control = lmeControl(opt="optim")
)

anova(hfmse.fit3, hfmse.fit4)

hfmse.fit <- hfmse.fit4

summary(hfmse.fit)