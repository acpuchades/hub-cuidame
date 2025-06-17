source("R/data.R")

rulm.data <- datos_escalas |>
  filter(scale == "RULM") |>
  select(
    score, patient_id, ccaa, gender, age,
    sma_type, smn2num, treatment_start_age,
    txgroup, years_from_baseline
  ) |>
  mutate(across(patient_id, as.factor)) |>
  filter(n() >= 2, .by=patient_id) |>
  drop_na()

rulm.fit0 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~ 1 | patient_id,
  data = rulm.data,
)

summary(rulm.fit0)

rulm.fit1 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~ age | patient_id,
  data = rulm.data,
)

anova(rulm.fit0, rulm.fit1)

rulm.fit2 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~ age | ccaa/patient_id,
  data = rulm.data,
  control = lmeControl(opt="optim", maxIter=1e5, msMaxIter=1e5)
)

anova(rulm.fit1, rulm.fit2)

rulm.fit3 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varIdent(form=~1 | sma_type),
  data = rulm.data
)

anova(rulm.fit1, rulm.fit3)

rulm.fit4 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | sma_type),
    varIdent(form=~1 | gender)
  ),
  data = rulm.data
)

anova(rulm.fit3, rulm.fit4)

rulm.fit5 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | sma_type),
    varIdent(form=~1 | gender),
    varIdent(form=~1 | txgroup)
  ),
  data = rulm.data
)

anova(rulm.fit4, rulm.fit5)

rulm.fit6 <- lme(
  score ~ (sma_type + gender + smn2num + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | sma_type),
    varIdent(form=~1 | gender),
    varIdent(form=~1 | txgroup)
  ),
  correlation = corCAR1(form=~years_from_baseline | patient_id),
  data = rulm.data
)

anova(rulm.fit5, rulm.fit6)

rulm.fit <- rulm.fit6
summary(rulm.fit)
