formula_bin <- "species ~ ."
formula_reg <- "bill_length_mm ~ ."

df <- palmerpenguins::penguins %>%
  na.omit() %>%
  select(-year) %>%
  filter(species == "Adelie" | species == "Gentoo") %>%
  mutate(species = droplevels(species))

transformer_ob_reg = transformer(df, formula_reg,
                                 norm_num_vars = "all",
                                 encode_cat_vars = "all"
)

transformer_ob_bin = transformer(df, formula_bin,
                                 norm_num_vars = "all",
                                 encode_cat_vars = "all"
)

hyper_nn_tune_list = list(

  learn_rate = c(-2, -1),
  hidden_units = c(3,10)

)

hyper_rf_tune_list = list(

  mtry = c(2,6),
  trees = 100

)

model_object_bin = create_models(tidy_object = transformer_ob_bin,
                                 model_names = "Neural Network",
                                 hyperparameters = hyper_nn_tune_list,
                                 task = "classification")

model_object_reg = create_models(tidy_object = transformer_ob_reg,
                                 model_names = "Random Forest",
                                 hyperparameters = hyper_rf_tune_list,
                                 task = "regression")

### create_workflow

test_that("Check create_workflow works properly", {

  workflow_bin = create_workflow(model_object_bin)
  workflow_reg = create_workflow(model_object_reg)

  expect_equal(class(workflow_bin$pre$actions$recipe), c("action_recipe", "action_pre", "action"))
  expect_equal(class(workflow_reg$pre$actions$recipe), c("action_recipe", "action_pre", "action"))

})

###### split_data

test_that("Check split_data works properly", {

  split_data_bin <- split_data(model_object_bin, model = model_object_bin$models_names)
  split_data_reg <- split_data(model_object_reg, model = model_object_reg$models_names)

  expect_equal(class(split_data_bin$sampling_method$splits[[1]]), c("val_split", "rsplit"))
  expect_equal(split_data_bin$final_split, rbind(model_object_bin$train_data, model_object_bin$validation_data))

  expect_equal(class(split_data_reg$sampling_method$splits[[1]]), c("vfold_split", "rsplit") )
  expect_equal(split_data_reg$final_split, model_object_reg$train_data)

})


##### create_metric_set

test_that("Test create_metric_set works properly", {

  metrics_bin = c("roc_auc", "accuracy")
  metrics_reg = c("rmse", "ccc")

  model_object_bin$modify("metrics", metrics_bin)
  model_object_reg$modify("metrics", metrics_reg)

  metric_set_bin <- create_metric_set(model_object_bin$metrics)
  metric_set_reg <- create_metric_set(model_object_reg$metrics)

  expect_equal(class(metric_set_bin), c("class_prob_metric_set", "metric_set", "function"))
  expect_equal(class(metric_set_reg), c("numeric_metric_set", "metric_set", "function"))

})

###### extract_hyperparams

test_that("Test extract_hyperparams works properly", {

  model_object_bin2 = model_object_bin$clone()
  model_object_reg2 = model_object_reg$clone()

  model_object_bin2$modify("workflow", create_workflow(model_object_bin))
  model_object_reg2$modify("workflow", create_workflow(model_object_reg))

  extracted_hyp_bin <- extract_hyperparams(model_object_bin2)
  extracted_hyp_reg <- extract_hyperparams(model_object_reg2)

  expect_equal(extracted_hyp_bin$name, c("hidden_units", "activation", "learn_rate"))
  expect_equal(length(extracted_hyp_bin$object), 3)

  expect_equal(extracted_hyp_reg$name, c("mtry", "min_n"))
  expect_equal(length(extracted_hyp_reg$object), 2)

})
##### hyperparams_grid

###### tune_models_bayesian


###### tune_models_grid_search_cv


##### tune_models
