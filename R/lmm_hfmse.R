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
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~ 1 | patient_id,
  data = hfmse.data
)

summary(hfmse.fit0)

hfmse.fit1 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~ age | patient_id,
  data = hfmse.data
)

anova(hfmse.fit0, hfmse.fit1)

hfmse.fit2 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varIdent(form=~1 | ccaa),
  data = hfmse.data,
  control = lmeControl(maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit1, hfmse.fit2)

hfmse.fit3 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | ccaa),
    varIdent(form=~1 | gender)
  ),
  data = hfmse.data,
  control = lmeControl(maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit2, hfmse.fit3)

hfmse.fit4 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | ccaa),
    varIdent(form=~1 | gender),
    varIdent(form=~1 | sma_type)
  ),
  data = hfmse.data,
  control = lmeControl(maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit3, hfmse.fit4)

hfmse.fit5 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | ccaa),
    varIdent(form=~1 | gender),
    varIdent(form=~1 | sma_type),
    varIdent(form=~1 | smn2num)
  ),
  data = hfmse.data,
  control = lmeControl(maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit4, hfmse.fit5)

hfmse.fit6 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | ccaa),
    varIdent(form=~1 | gender),
    varIdent(form=~1 | sma_type),
    varIdent(form=~1 | txgroup)
  ),
  data = hfmse.data,
  control = lmeControl(maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit4, hfmse.fit6)

hfmse.fit7 <- lme(
  score ~ (gender + smn2num + sma_type + txgroup + treatment_start_age) * age,
  random = ~age | patient_id,
  weights = varComb(
    varIdent(form=~1 | ccaa),
    varIdent(form=~1 | gender),
    varIdent(form=~1 | sma_type),
    varIdent(form=~1 | txgroup)
  ),
  correlation = corCAR1(form=~years_from_baseline | patient_id),
  data = hfmse.data,
  control = lmeControl(maxIter=1e3, msMaxIter=1e3)
)

anova(hfmse.fit6, hfmse.fit7)

hfmse.fit <- hfmse.fit7
summary(hfmse.fit)
