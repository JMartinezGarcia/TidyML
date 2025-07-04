###########################
#       Interpretable ML
###########################

#' Perform Sensitivity Analysis and Interpretable ML methods
#'
#' As the final step in the TidyML package workflow, this function performs Sensitivity Analysis (SA) on a fitted
#' ML model stored in an `analysis_object` (in the examples, e.g., tidy_object). It evaluates the importance
#' of features using various methods such as Permutation Feature Importance (PFI), SHAP (SHapley Additive
#' exPlanations), Integrated Gradients, Olden sensitivity analysis, and Sobol indices. The function generates
#' numerical results and visualizations (e.g., bar plots, box plots, beeswarm plots) to help interpret the impact
#' of each feature on the model's predictions for both regression and classification tasks, providing critical
#' insights after model training and evaluation.
#'
#' Following the steps of data preprocessing, model fitting, and performance assessment in the TidyML pipeline,
#' *sensitivity_analysis()* processes the training and test data using the preprocessing recipe stored in the
#' analysis_object, applies the specified SA methods, and stores the results within the analysis_object. It
#' supports different metrics for evaluation and handles multi-class classification by producing class-specific
#' analyses and plots, ensuring a comprehensive understanding of model behavior (Iooss & Lemaître, 2015).
#'
#' @param analysis_object analysis_object created from fine_tuning function.
#' @param methods Method to be used. A string of the method name: "PFI" (Permutation Feature Importance),
#'     "SHAP" (SHapley Additive exPlanations), "Integrated Gradients" (Neural Network only), "Olden"
#'     (Neural Network only), "Sobol_Jansen" (only when all input features are continuous).
#' @param  metric Metric used for "PFI" method (Permutation Feature Importance).
#'  A string of the name of metric (see Metrics).
#'
#' @param verbose Boolean. Whether to print results to console.
#'
#' @details
#' As the concluding phase of the TidyML workflow—after data preparation, model training, and evaluation—this
#' function enables users to interpret their models by quantifying and visualizing feature importance. It first
#' validates the input arguments using `check_args_sensitivity_analysis()`. Then, it preprocesses the training
#' and test data using the recipe stored in `analysis_object$transformer`. Depending on the specified `methods`,
#' it calculates feature importance using:
#' - **PFI (Permutation Feature Importance):** Assesses importance by shuffling feature values and measuring
#'                                             the change in model performance (using the specified or default
#'                                             `metric`).
#' - **SHAP (SHapley Additive exPlanations):** Computes SHAP values to explain individual predictions by
#'                                             attributing contributions to each feature.
#' - **Integrated Gradients:** Evaluates feature importance by integrating gradients of the model's output
#'                             with respect to input features.
#' - **Olden:** Calculates sensitivity based on connection weights, typically for neural network models, to
#'             determine feature contributions.
#' - **Sobol_Jansen:** Performs variance-based global sensitivity analysis by decomposing the model output variance
#'                     into contributions from individual features and their interactions, quantifying how much each
#'                     feature and combination of features accounts for the variability in predictions. Only for
#'                     continuous outcomes, not for categorical. Specifically, estimates first-order and total-order
#'                     Sobol' sensitivity indices simultaneously using the Jansen (1999) Monte Carlo estimator.
#'
#' For classification tasks with more than two outcome levels, the function generates separate results and plots
#' for each class. Visualizations include bar plots for importance metrics, box plots for distribution of values,
#' and beeswarm plots for detailed feature impact across observations. All results are stored in the `analysis_object`
#' under the `sensitivity_analysis` slot, finalizing the TidyML pipeline with a deep understanding of model drivers.
#' @returns An updated `analysis_object` with the results of the sensitivity analysis stored in the
#' `sensitivity_analysis` slot as a list. Each method's results are accessible under named elements
#' (e.g., `sensitivity_analysis[["PFI"]]`). Additionally, the function produces various plots (bar plots,
#' box plots, beeswarm plots) for visual interpretation of feature importance, tailored to the task type
#' and number of outcome levels, completing the TidyML workflow with actionable model insights.
#' @examples
#' # Example 1: Using PFI
#'
#' library(TidyML)
#'
#' data(sim_data) # sim_data is a simulated dataset with psychological variables
#'
#' tidy_object <- preprocessing(
#'        df = sim_data,
#'        formula = psych_well ~ depression + emot_intel + resilience + life_sat,
#'        task = "regression"
#'        )
#'
#' tidy_object <- build_model(
#'                analysis_object = tidy_object,
#'                model_name = "Random Forest",
#'                hyperparameters = list(
#'                                  mtry = 3,
#'                                  trees = 20
#'                                  )
#'                            )
#'
#' tidy_object <- fine_tuning(tidy_object,
#'                 tuner = "Grid Search CV",
#'                 metrics = c("rmse"),
#'                 plot_results = FALSE
#'                 )
#'
#'
#' tidy_object <- sensitivity_analysis(tidy_object, methods = "PFI", metric = "mape")
#'
#' @references
#' Iooss, B., & Lemaître, P. (2015). A review on global sensitivity analysis methods. In C. Meloni & G. Dellino
#' (Eds.), *Uncertainty Management in Simulation-Optimization of Complex Systems: Algorithms and Applications*
#' (pp. 101-122). Springer. https://doi.org/10.1007/978-1-4899-7547-8_5
#'
#' Jansen, M. J. W. (1999). Analysis of variance designs for model output. Computer Physics Communications,
#' 117(1-2), 35–43. https://doi.org/10.1016/S0010-4655(98)00154-4
#' @export
sensitivity_analysis <- function(analysis_object, methods = c("PFI"), metric = NULL, verbose = TRUE){

  check_args_sensitivity_analysis(analysis_object = analysis_object, methods = methods, metric = metric)

  analysis_object = analysis_object$clone()

  task = analysis_object$task

  y = all.vars(analysis_object$formula)[1]

  rec =  analysis_object$transformer %>%
    recipes::prep(training = analysis_object$train_data)

  bake_train = recipes::bake(rec, new_data = analysis_object$train_data)
  bake_test = recipes::bake(rec, new_data = analysis_object$test_data)

  model_parsnip <- analysis_object$final_model %>%
    tune::extract_fit_parsnip()

  if (is.null(analysis_object$sensitivity_analysis)){

    sensitivity_analysis_list = list()

  } else {

    sensitivity_analysis_list = analysis_object$sensitivity_analysis

  }

  feature_names <- names(bake_train)[which(names(bake_test) != y)]

  plot_ob = analysis_object$plots

  if ("PFI" %in% methods){

    method_name = "PFI"

    if (is.null(metric)){

      if (task == "regression"){

        metric = "rmse"

      } else{

        metric = "roc_auc"

      }
    }

    results <- pfi_calc(model = model_parsnip, train = bake_train, test = bake_test, y = y,
                        task = task, metric = metric, outcome_levels = analysis_object$outcome_levels)

    sensitivity_analysis_list[["PFI"]] <- results

    if (analysis_object$outcome_levels > 2){

    y_classes <- levels(bake_train[[y]])

    if (verbose == T){

        cat("######### PFI Method Results ############## \n")

    }

    for (target_class in y_classes){

      if (verbose == T){

          cat("\n")
          print(paste0("PFI for class ", target_class))
          print(results[[target_class]])
          cat("\n")

      }

      p <- plot_barplot(results[[target_class]], func = NULL, title = paste0("Permutation Feature Importance for class ",
                                                        target_class), x_label = "Importance")

      plot_name <- paste0(method_name,"_",target_class,"_barplot")

      plot_ob[[plot_name]] = p

      print(p)

      }

    } else{

      if (verbose == T){

          cat("######### PFI Method Results ############## \n")
          cat("\n")
          print(results)
          cat("\n")

      }

      p <- plot_barplot(results, func = NULL, title = "Permutation Feature Importance", x_label = "Importance")

      plot_name <- paste0(method_name,"_barplot")

      plot_ob[[plot_name]] = p

      print(p)

    }

  }

  if ("SHAP" %in% methods){

    method_name = "SHAP"

    results <- shap_calc(model = model_parsnip, train = bake_train, test = bake_test, y = y,
                         task = task, outcome_levels = analysis_object$outcome_levels)

    sensitivity_analysis_list[["SHAP"]] <- results

    test <- bake_test[which(names(bake_test) != y)]

    if (analysis_object$outcome_levels > 2){

      y_classes = levels(bake_train[[y]])

      if (verbose == T){

          cat("######### SHAP Method Results ############## \n")

      }

      for (target_class in y_classes){


        if (verbose == T){

            cat("\n")
            print(paste0("abs(SHAP) for class ", target_class))
            print(summarize_importance(abs(results[[target_class]]), feature_names))
            cat("\n")

        }

        p <- plot_barplot(results[[target_class]], func = function(x) mean(abs(x)),
                     func_se = function(x) sd(abs(x)) / sqrt(length(x)),
                     x_label = "Mean |SHAP|",
                     title = paste0("Mean |SHAP| value for class ", target_class)
                     )

        plot_name <- paste0(method_name,"_",target_class,"_barplot")

        plot_ob[[plot_name]] = p

        print(p)

        p <- plot2(results[[target_class]], test, func = function(x) mean(x),
              func_se = function(x) sd(x),
              x_label = "Mean (SHAP * sign(X))",
              title = paste0("Directional Sensitivity of SHAP Values for class ", target_class)
              )

        plot_name <- paste0(method_name,"_",target_class,"_barplot2")

        plot_ob[[plot_name]] = p

        print(p)

        p <- plot_boxplot(results[[target_class]], y_label = "SHAP value",
                     title = paste0("SHAP Value Distribution for class ", target_class)
                     )

        plot_name <- paste0(method_name,"_",target_class,"_boxplot")

        plot_ob[[plot_name]] = p

        print(p)

        p <- plot_beeswarm(results[[target_class]], X_orig = test, x_label = "SHAP value",
                      title = paste0("SHAP Swarm Plot for class ", target_class)
                      )

        plot_name <- paste0(method_name,"_",target_class,"_swarmplot")

        plot_ob[[plot_name]] = p

        print(p)

      }

    } else{

      if (verbose == T){

          cat("######### SHAP Method Results ############## \n")
          cat("\n")
          print(summarize_importance(abs(results), feature_names))
          cat("\n")

      }

    p <- plot_barplot(results, func = function(x) mean(abs(x)),
                 func_se = function(x) sd(abs(x)) / sqrt(length(x)),
                 x_label = "Mean |SHAP|",
                 title = "Mean |SHAP| value")

    plot_name <- paste0(method_name, "_barplot")

    plot_ob[[plot_name]] = p

    print(p)

    p <- plot2(results, test, func = function(x) mean(x),
            func_se = function(x) sd(x),
            x_label = "Mean (SHAP * sign(X))",
            title = "Directional Sensitivity of SHAP Values")

    plot_name <- paste0(method_name, "_barplot2")

    plot_ob[[plot_name]] = p

    print(p)

    p <- plot_boxplot(results, y_label = "SHAP value", title = "SHAP Value Distribution")

    plot_name <- paste0(method_name, "_boxplot")

    plot_ob[[plot_name]] = p

    print(p)

    p <- plot_beeswarm(results, X_orig = test, x_label = "SHAP value", title = "SHAP Swarm Plot")

    plot_name <- paste0(method_name, "_swarmplot")

    plot_ob[[plot_name]] = p

    print(p)

    }

  }

  if ("Integrated Gradients" %in% methods){

    method_name = "IntegratedGradients"

    results <- IntGrad_calc(model = model_parsnip, train = bake_train, test = bake_test, y = y,
                            task = task, outcome_levels = analysis_object$outcome_levels)

    sensitivity_analysis_list[["IntegratedGradients"]] <- results

    test <- bake_test[which(names(bake_test) != y)]

    if (analysis_object$outcome_levels > 2){

      y_classes = levels(bake_train[[y]])

      if (verbose == T){

          cat("######### Integrated Gradients Method Results ############## \n")

      }

      for (target_class in y_classes){

        if (verbose == T){

            cat("\n")
            print(paste0("abs(Integrated Gradients) for class ", target_class))
            print(summarize_importance(abs(results[[target_class]]), feature_names))
            cat("\n")

        }

        p <- plot_barplot(results[[target_class]], func = function(x) mean(abs(x)),
                     func_se = function(x) sd(abs(x)) / sqrt(length(x)),
                     x_label = "Mean |Integrated Gradient|",
                     title = paste0("Mean |Integrated Gradient| value for class ", target_class)
        )

        plot_name <- paste0(method_name,"_",target_class,"_barplot")

        plot_ob[[plot_name]] = p

        print(p)

        p <- plot2(results[[target_class]], test, func = function(x) mean(x),
              func_se = function(x) sd(x),
              x_label = "Mean (Integrated Gradient * sign(X))",
              title = paste0("Directional Sensitivity of Integrated Gradients Values for class ", target_class)
              )

        plot_name <- paste0(method_name,"_",target_class,"_barplot2")

        plot_ob[[plot_name]] = p

        print(p)

        p <- plot_boxplot(results[[target_class]], y_label = "Integrated Gradient value",
                     title = paste0("Integrated Gradient Value Distribution for class ", target_class)
                     )

        plot_name <- paste0(method_name,"_",target_class,"_boxplot")

        plot_ob[[plot_name]] = p

        print(p)

        p <- plot_beeswarm(results[[target_class]], X_orig = test, x_label = "SHAP value",
                      title = paste0("Integrated Gradient Swarm Plot for class ", target_class))

        plot_name <- paste0(method_name,"_",target_class,"_swarmplot")

        plot_ob[[plot_name]] = p

        print(p)

      }

    } else{

      if (verbose == T){

          cat("######### Integrated Gradients Method Results ############## \n")
          cat("\n")
          print(summarize_importance(abs(results), feature_names))
          cat("\n")

      }

      p <- plot_barplot(results, func = function(x) mean(abs(x)),
                   func_se = function(x) sd(abs(x)) / sqrt(length(x)),
                   x_label = "Mean |Integrated Gradient|",
                   title = "Mean |Integrated Gradient| value"
                   )

      plot_name <- paste0(method_name,"_barplot")

      plot_ob[[plot_name]] = p

      print(p)

      p <- plot2(results, test, func = function(x) mean(x),
            func_se = function(x) sd(x),
            x_label = "Integradient Gradient Correlation",
            title = "Directional Sensitivity of Integrated Gradients Values")

      plot_name <- paste0(method_name,"_barplot2")

      plot_ob[[plot_name]] = p

      print(p)

      p <- plot_boxplot(results, y_label = "Integrated Gradient value", title = "Integrated Gradient Distribution")

      plot_name <- paste0(method_name,"_boxplot")

      plot_ob[[plot_name]] = p

      print(p)

      p <- plot_beeswarm(results, X_orig = test, x_label = "Integrated Gradient value",
                    title = "Integrated Gradient Swarm Plot")

      plot_name <- paste0(method_name,"_swarmplot")

      plot_ob[[plot_name]] = p

      print(p)

    }

  }

  if ("Olden" %in% methods){

    method_name = "Olden"

    y_classes = levels(bake_train[[y]])

    results = olden_calc(model = model_parsnip, task,
                         outcome_levels = analysis_object$outcome_levels, y_classes = y_classes)

    df_results <- as.data.frame(t(results))

    names(df_results) <- feature_names

    sensitivity_analysis_list[["Olden"]] <- df_results


    if (analysis_object$outcome_levels > 2){

      rownames(df_results) <- y_classes

      if (verbose == T){

          cat("######### Olden's Method Results ############## \n")
          cat("\n")
          print(df_results)
          cat("\n")

      }

      for (i in 1:length(y_classes)){

        net_importance = results[,i]

        title = paste0("Olden Feature Importance for class ", y_classes[i])

        plot_name = paste0("Olden_", y_classes[i])

        p <- olden_barplot(net_importance, feature_names, title)

        plot_name = paste0("Olden_", y_classes[i], "_barplot")

        plot_ob[[plot_name]] = p

        print(p)
      }

    } else{

      if (verbose == TRUE){

          cat("######### Olden's Method Results ############## \n")
          cat("\n")
          print(df_results)
          cat("\n")

      }

      p <- olden_barplot(results, feature_names)

      plot_name <- paste0(method_name,"_barplot")

      plot_ob[[plot_name]] = p

      print(p)

    }
  }

    if ("Sobol_Jansen" %in% methods){

      results <- sobol_calc(model_parsnip, bake_train, task, feature_names)

      sensitivity_analysis_list[["Sobol_Jansen"]] <- results

      if (verbose == TRUE){

          cat("######### Sobol_Jansen's Method Results ############## \n")
          cat("\n")
          print(results)
          cat("\n")
          print("##############################################")
          cat("\n")

      }

      p <- sobol_plot(results)

      plot_ob[["Sobol_Jansen"]] = p

      print(p)


    }


  analysis_object$modify("sensitivity_analysis", sensitivity_analysis_list)

  analysis_object$modify("plots", plot_ob)

  return(analysis_object)

}

####################
#   Global Plots   #
####################

#### plot_global

plot_barplot <- function(X, func = NULL, func_se = stats::sd, title, x_label) {

  X <- base::as.data.frame(X)

  if (!is.null(func)){

  summary_df <- tibble::tibble(
      Variable = base::colnames(X),
      Importance = base::sapply(X, func),
      StDev = base::sapply(X, func_se)
    )

  } else{summary_df <- X}



  summary_df$Variable <- factor(summary_df$Variable,
                                levels = summary_df$Variable[order(summary_df$Importance, decreasing = F)])

    p <- ggplot2::ggplot(summary_df, ggplot2::aes(x = Importance, y = Variable)) +
      ggplot2::geom_col(fill = "steelblue", width = 0.7) +
      ggplot2::geom_errorbar(ggplot2::aes(xmin = Importance - StDev, xmax = Importance + StDev), width = 0.2) +
      ggplot2::geom_text(ggplot2::aes(label = paste0(round(Importance, 3), " +/- ", round(StDev, 3))),
                vjust =  -0.5,
                hjust = -0.2) +
      ggplot2::labs(
        x_label = x_label,
        y = "Feature",
        title = title
        ) +
      ggplot2::theme_grey()

  return(p)

}


plot2 <- function(X, test, func = NULL, func_se = stats::sd, title, x_label) {

  X <- base::as.data.frame(X)

  test <- base::as.data.frame(test)

  N = base::ncol(test)

  feat_names <- names(test)

  collapse_imp <- list()

  for (i in 1:N){

    collapse_imp[[feat_names[i]]] <- stats::cov(X[[i]], test[[i]]) / stats::var(test[[i]])

  }

  collapse_imp <- base::as.data.frame(collapse_imp)


   df <- tibble::tibble(
    variable = base::colnames(collapse_imp),
    importance = base::unlist(collapse_imp, use.names = FALSE)
  )

  # Order decreasing
  df$variable <- factor(df$variable, levels = df$variable[order(df$importance, decreasing = T)])

  # Plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = variable, y = importance, fill = importance > 0)) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(label = round(importance, 3)),
                       vjust = ifelse(df$importance >= 0, -0.5, 1.2)) +
    ggplot2::scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "firebrick")) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed") +
    ggplot2::labs(
      title = title,
      x = "Feature",
      y = "Feature Importance"
    ) +
    ggplot2::theme_grey() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  return(p)

}

plot_boxplot <- function(X, title, y_label){

  X <- base::as.data.frame(X)

  summary_df <- tibble::tibble(
    variable = base::colnames(X),
    value = base::sapply(X, function(x) mean(abs(x)))
  )

    X_long <- tidyr::pivot_longer(
      data = X,
      cols = tidyselect::everything(),
      names_to = "variable",
      values_to = "value"
    )

    X_long$variable <- factor(X_long$variable,
                                  levels = summary_df$variable[order(summary_df$value, decreasing = T)])

    p <- ggplot2::ggplot(X_long, ggplot2::aes(x = variable, y = value)) +
      ggplot2::geom_boxplot(fill = "lightgray") +
      ggplot2::labs(
        x = "Feature",
        y = y_label,
        title = title
      ) +
      ggplot2::theme_grey() +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  return(p)

}

###### Beeswarm

plot_beeswarm <- function(X_vals, X_orig, title, x_label){

  order_df <- tibble::tibble(
    variable = base::colnames(X_vals),
    value = base::sapply(X_vals, function(x) mean(abs(x)))
  )


  summary_df <- X_vals %>%
    tidyr::pivot_longer(cols = dplyr::everything(), names_to = "variable", values_to = "value")

  summary_df$variable <- factor(summary_df$variable,
                            levels = order_df$variable[order(order_df$value, decreasing = F)])

  X <- X_orig %>%
    tidyr::pivot_longer(cols = dplyr::everything(), names_to = "variable", values_to = "val_color")

  X$variable <- factor(X$variable,
                                 levels = order_df$variable[order(order_df$value, decreasing = F)])

  summary_df["val_color"] = X["val_color"]


  p <- ggplot2::ggplot(summary_df, ggplot2::aes(x=value, y=variable, color = val_color)) +
    ggbeeswarm::geom_quasirandom(bandwidth = 0.2, method = "pseudorandom", cex = 2, orientation = 'x') +
    ggplot2::labs(x = x_label, y = "Feature" ,title = title) +
    ggplot2::theme_grey() +
    ggplot2::scale_color_viridis_c(option = "A")

  return(p)

}

###########################
#   Prediction Wrappers   #
###########################

pred_reg <- function(object, newdata){

  return(predict(object,new_data= newdata)$.pred)

}

pred_bin <- function(object, newdata){

  return(predict(object, new_data = newdata, type = "prob")[,2][[1]])

}

pred_bin_class <- function(object, newdata){

  return(predict(object, new_data = newdata, type = "class")$.pred_class)

}

summarize_importance <- function(importance_matrix, feature_names) {

  # Calcular media y error estandar para cada variable
  mean_importance <- colMeans(importance_matrix, na.rm = TRUE)
  std_error <- apply(importance_matrix, 2, function(x) sd(x, na.rm = TRUE) / sqrt(length(x)))

  # Crear resumen ordenado
  summary_df <- data.frame(
    Importance = signif(mean_importance,3),
    StDev = signif(std_error,2)
  )

  rownames(summary_df) <- feature_names

  # Ordenar de mayor a menor importancia

  summary_df <- summary_df[order(-summary_df$Importance), ]

  return(summary_df)
}


