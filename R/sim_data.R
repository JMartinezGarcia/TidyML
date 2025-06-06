#' sim_data
#'
#' This dataset, included in the tidyML package, is a simulated dataset (Martínez et al., 2025) designed to capture
#' relationships among psychological and demographic variables influencing psychological wellbeing, the primary
#' outcome variable. It comprises data for 1,000 individuals.
#'
#' The predictor variables include gender (50.7% female), age (range: 18-85 years, mean = 51.63, median = 52,
#' SD = 17.11), and socioeconomic status, categorized as Low (n = 343), Medium (n = 347), and High (n = 310).
#' Additional predictors are emotional intelligence (range: 24-120, mean = 71.97, median = 71, SD = 23.79),
#' resilience (range: 4-20, mean = 11.93, median = 12, SD = 4.46), life satisfaction (range: 5-35, mean = 20.09,
#' median = 20, SD = 7.42), and depression (range: 0-63, mean = 31.45, median = 32, SD = 14.85). The primary
#' outcome variable is emotional wellbeing, measured on a scale from 0 to 100 (mean = 50.22, median = 49,
#' SD = 24.45).
#'
#' The dataset incorporates correlations as conditions for the simulation. Psychological wellbeing is positively
#' correlated with emotional intelligence (r = 0.50), resilience (r = 0.40), and life satisfaction (r = 0.60),
#' indicating that higher levels of these factors are associated with better emotional health outcomes. Conversely,
#' a strong negative correlation exists between depression and psychological wellbeing (r = -0.80), suggesting that
#' higher depression scores are linked to lower emotional wellbeing. Age shows a slight positive correlation with
#' emotional wellbeing (r = 0.15), reflecting the expectation that older individuals might experience greater
#' emotional stability. Gender and socioeconomic status are included as potential predictors, but the simulation
#' assumes no statistically significant differences in psychological wellbeing across these categories.
#'
#' Additionally, the dataset includes categorical transformations of psychological wellbeing into binary and
#' polytomous formats: a binary version ("Low" = 477, "High" = 523) and a polytomous version with four levels:
#' "Low" (n = 161), "Somewhat" (n = 351), "Quite a bit" (n = 330), and "Very much" (n = 158). The polytomous
#' transformation uses the 25th, 50th, and 75th percentiles as thresholds for categorizing psychological wellbeing
#' scores. These transformations enable analyses using machine learning models for regression (continuous outcome)
#' and classification (binary or polytomous outcomes) tasks.
#'
#' @docType data
#' @name sim_data
#' @usage data(sim_data)
#' @format A data frame with 1,000 rows and 10 columns:
#' \describe{
#'   \item{psych_well}{Psychological Wellbeing Indicator. Continuous with (0,100)}
#'   \item{psych_well_bin}{Psychological Wellbeing Binary Indicator. Factor with ("Low", "High")}
#'   \item{psych_well_pol}{Psychological Wellbeing Polytomic Indicator. Factor with ("Low", "Somewhat", "Quite a bit", "Very Much")}
#'   \item{gender}{Patient Gender. Factor ("Female", "Male")}
#'   \item{age}{Patient Age. Continuous (18, 85)}
#'   \item{socioec_status}{Socioeconomial Status Indicator. Factor ("Low", "Medium", "High")}
#'   \item{emot_intel}{Emotional Intelligence Indicator. Continuous (24, 120)}
#'   \item{resilience}{Resilience Indicator. Continuous (4, 20)}
#'   \item{depression}{Depression Indicator. Continuous (0, 63)}
#'   \item{life_sat}{Life Satisfaction Indicator. Continuous (5, 35)}
#' }
#' @references
#' Martínez-García, J., Montaño, J.J., Jiménez, R., Gervilla, E., Cajal, B., Núñez-Prats, A., Leguizamo-Barroso, F.,
#' & Sesé, A. (2025). Decoding Artificial Intelligence: A tutorial on Neural Networks in Behavioral Research.
#' *Clinical and Health, 36*(2). https://doi.org/10.5093/clh2025a13
#' @note This paper is also interesting for ML users as it serves as a primer for estimating ML models using Python
#' code, particularly in the context of Social, Health, and Behavioral research.
#'
NULL

