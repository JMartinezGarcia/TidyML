devtools::load_all()

formula = "y ~ x1 + x2 + x3 + x4 + x1_squared + x2_log"
formula = as.formula(formula)

set.seed(42)  # Para reproducibilidad

# Crear el dataframe original
df <- data.frame(
  x1 = runif(100, 2, 7),  # Variable continua
  x2 = runif(100, 3, 8),  # Variable continua
  x3 = sample(0:1, 100, replace = TRUE),  # Factor binario
  x4 = sample(0:2, 100, replace = TRUE)   # Factor con 3 niveles
)

# Introducir ruido en las variables continuas
df$x1 <- df$x1 + rnorm(100, mean = 0, sd = 0.5)
df$x2 <- df$x2 + rnorm(100, mean = 0, sd = 0.5)

# Crear interacciones no lineales y no triviales
df$x1_squared <- df$x1^2
df$x2_log <- log(df$x2 + 1)  # log transformada de x2

# Introducir observaciones atípicas (outliers) en x1 y x2
outlier_indices <- sample(1:100, size = 5)  # 5 outliers aleatorios
df$x1[outlier_indices] <- df$x1[outlier_indices] * 2  # Multiplicar por 2 para crear outliers
df$x2[outlier_indices] <- df$x2[outlier_indices] * 2  # Hacer lo mismo para x2

# Crear 'y' basado en reglas más complicadas
df$y <- with(df, ifelse((x1 + x2 > 12) | (x3 == 1 & x4 != 2) | (x1_squared < 25 & x2_log > 1), 1, 0))

# Convertir las variables categóricas
df$x3 <- factor(df$x3)
df$x4 <- factor(df$x4, levels = c(0, 1, 2))
df$y <- as.factor(df$y)  # Para clasificación


transformer_ob = transformer(df, formula, "y",
                             num_vars = c("x1", "x2"),
                             cat_vars = c("x3", "x4"),
                             norm_num_vars = "all",
                             encode_cat_vars = "all"
                             )

#tidy_object <- TidyMLObject$new(df, transformer_ob)

hyper_nn_tune_list = list(
  learn_rate = c(-2, -1),
  hidden_units = 3
)

metrics = c("roc_auc", "accuracy")

test_that("create_workflow works properly", {

  model_object = create_models(tidy_object = transformer_ob,
                               model_names = "Neural Network",
                               hyperparameters = hyper_nn_tune_list,
                               task = "classification")

  workflow = create_workflow(model_object)

  expect_equal(class(workflow$pre$actions$recipe), c("action_recipe", "action_pre", "action"))

})

test_that("create_val_set works properly", {

  model_object = create_models(tidy_object = transformer_ob,
                               model_names = "Neural Network",
                               hyperparameters = hyper_nn_tune_list,
                               task = "classification")

  val_set <- create_val_set(model_object)

  expect_equal(class(val_set)[1], "validation_set")

  expect_equal(is.null(model_object$train), F)

  expect_equal(is.null(model_object$validation), F)

  expect_equal(is.null(model_object$test), F)

})

test_that("create_metric_set works properly", {

  model_object = create_models(tidy_object = transformer_ob,
                               model_names = "Neural Network",
                               hyperparameters = hyper_nn_tune_list,
                               task = "classification")

  metrics = c("roc_auc", "accuracy")

  model_object$add_metrics(metrics)

  metric_set <- create_metric_set(model_object$metrics)

  expect_equal(class(metric_set), c("class_prob_metric_set", "metric_set", "function"))

})

test_that("extract_hyperparams works properly", {

  model_object = create_models(tidy_object = transformer_ob,
                               model_names = "Neural Network",
                               hyperparameters = hyper_nn_tune_list,
                               task = "classification")

  metrics = c("roc_auc", "accuracy")

  model_object$add_workflow(create_workflow(model_object))

  model_object$add_metrics(metrics)

  extracted_hyperparams <- extract_hyperparams(model_object)

  expect_equal(extracted_hyperparams$object[[1]]$values, c("relu", "tanh", "sigmoid"))

  expect_equal(extracted_hyperparams$object[[2]]$range, list(lower = -2, upper = -1))

})

test_that("tune_models_bayesian works properly", {

  model_object = create_models(tidy_object = transformer_ob,
                               model_names = "Neural Network",
                               hyperparameters = hyper_nn_tune_list,
                               task = "classification")

  model_object$add_workflow(create_workflow(model_object))

  model_object$add_metrics(metrics)

  set.seed(123)

  val_set <- create_val_set(model_object)

  tune_fit <- tune_models_bayesian(model_object, val_set, verbose = F)

  expect_equal(class(tune_fit)[1:2], c("iteration_results", "tune_results"))

  expect_equal(is.null(tune_fit$.predictions), F)

  expect_equal(is.null(tune_fit$.metrics), F)

  expect_equal(tune_fit$.iter, c(0,1,2,3,4,5))

})








