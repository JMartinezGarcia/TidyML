    ########################################
    #             Predictions              #
    ########################################

get_predictions_binary <- function(tidy_object, new_data = "test"){

  model_workflow <- tidy_object$final_models

  y = all.vars(tidy_object$formula)[1]

  if (new_data == "all"){

    data_sets = c("train", "validation", "test")

    temp = list()

    for (data_set in data_sets){

      dat = tidy_object[[paste0(data_set, "_data")]]

      predictions_class = predict(model_workflow, new_data = dat)
      predictions_prob = predict(model_workflow, new_data = dat, type = "prob")
      predictions = cbind(predictions_class, predictions_prob, y = as.factor(dat[[y]]))
      predictions$data_set = data_set

      temp[[data_set]] = predictions
    }

    predictions = rbind(temp[["train"]], temp[["validation"]], temp[["test"]])

  } else {

    dat = tidy_object[[paste0(new_data, "_data")]]

    predictions_class = predict(model_workflow, new_data = dat)
    predictions_prob = predict(model_workflow, new_data = dat, type = "prob")
    predictions = cbind(predictions_class, predictions_prob, y = as.factor(dat[[y]]))
    predictions$data_set = new_data

  }

  return (predictions)

}

    ########################################
    #             SUMMARY                  #
    ########################################

summary_binary <- function(tidy_object, new_data = "test"){

  metric_funcs <- list(

    Accuracy = function(data) accuracy(data, y, .pred_class),
    Balanced_Accuracy = function(data) bal_accuracy(data, y, .pred_class),
    Precision = function(data) precision(data, y, .pred_class),
    Recall = function(data) recall(data, y, .pred_class),
    Specificity = function(data) specificity(data, y, .pred_class),
    Sensitivity = function(data) sensitivity(data, y, .pred_class),
    Kappa = function(data) kap(data, y, .pred_class),
    F1_score = function(data) f_meas(data, y, .pred_class),
    MCC = function(data) mcc(data, y, .pred_class),
    J_index = function(data) j_index(data, y, .pred_class),
    Detection_Prevalence = function(data) detection_prevalence(data, y, .pred_class, event_level = "second"),
    AUC_ROC = function(data) roc_auc(data, y, data[[predicted]], event_level = "second"),
    AUC_PR = function(data) pr_auc(data, y, data[[predicted]], event_level = "second"),
    Gain_Capture = function(data) gain_capture(data, y, data[[predicted]], event_level = "second"),
    Brier_Score = function(data) brier_class(data, y, data[[predicted]], event_level = "second")

  )

  predictions <- get_predictions_binary(tidy_object, new_data = new_data)

  positive_class = levels(predictions$y)[2]

  predicted = paste0(".pred_", positive_class)

  results <- lapply(metric_funcs, function(f) f(predictions)$.estimate)

  results <- as.data.frame(results)

  return(results)

}

    ########################################
    #             Plots                  #
    ########################################

plot_roc_curve_binary <- function(predictions, new_data = "all"){

  positive_class = levels(predictions$y)[2]

  predicted = paste0(".pred_", positive_class)

  if (new_data == "all"){

    curve_plot <- predictions %>%
      dplyr::group_by(data_set) %>%
      yardstick::roc_curve(y, predicted, event_level = "second")

    return(curve_plot)

  }

}

plot_pr_curve_binary <- function(predictions, new_data = "all"){

  positive_class = levels(predictions$y)[2]

  predicted = paste0(".pred_", positive_class)

  if (new_data == "all"){

    curve_plot <- predictions %>%
      dplyr::group_by(data_set) %>%
      yardstick::pr_curve(y, predicted, event_level = "second")

    return(curve_plot)

  }


}

plot_gain_curve_binary <- function(predictions, new_data = "all"){

  positive_class = levels(predictions$y)[2]

  predicted = paste0(".pred_", positive_class)

  if (new_data == "all"){

    curve_plot <- predictions %>%
      dplyr::group_by(data_set) %>%
      yardstick::gain_curve(y, predicted, event_level = "second")

    return(curve_plot)

  }


}

plot_lift_curve_binary <- function(predictions, new_data = "all"){

  positive_class = levels(predictions$y)[2]

  predicted = paste0(".pred_", positive_class)

  if (new_data == "all"){

    curve_plot <- predictions %>%
      dplyr::group_by(data_set) %>%
      yardstick::lift_curve(y, predicted, event_level = "second")

    return(curve_plot)

  }


}

plot_dist_probs_binary <- function(predictions, new_data = "test"){

  positive_class = levels(predictions$y)[2]

  predicted = paste0(".pred_", positive_class)

  predictions %>%
    dplyr::group_by(y) %>%
    ggplot2::ggplot(ggplot2::aes_string(x = predicted, fill = "y")) +
    ggplot2::geom_density(alpha = 0.5) +
    ggplot2::labs(title = "Probability Distribution by Class",
                  x = "Predicted Probability",
                  y = "Density",
                  fill = "Class") +
    ggplot2::theme_minimal()

}

plot_calibration_curve_binary <- function(predictions, new_data = "test"){

  positive_class = levels(predictions$y)[2]

  predicted = sym(paste0(".pred_", positive_class))

  predictions %>%
    dplyr::mutate(y = sapply(y, function(x) if(x == positive_class) 1 else 0)) %>%
    dplyr::mutate(pred_bin = cut(predictions[[predicted]],
                                 breaks = seq(0, 1, by = 0.1), include.lowest = TRUE)) %>%  # Crear bins de probabilidad
    dplyr::group_by(pred_bin) %>%
    dplyr::summarise(
      prob_pred = mean({{predicted}}),  # Promedio de las probabilidades predichas en cada bin
      prob_observed = mean(y)  # Promedio de 1s observados (probabilidad observada)
    ) %>%
    ggplot2::ggplot(ggplot2::aes(x = prob_pred, y = prob_observed)) +
    ggplot2::geom_point() +  # Graficar los puntos
    ggplot2::geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +  # Línea de calibración ideal
    ggplot2::labs(title = "Reliability Plot", x = "Predicted Probability", y = "Observed Probability") +
    ggplot2::theme_minimal()

}


plot_conf_mat_binary <- function(predictions, new_data = "test"){

  confusion_matrix = yardstick::conf_mat(predictions, truth = y, estimate = .pred_class)

  return(confusion_matrix)

}
