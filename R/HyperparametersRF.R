HyperparamsRF <- R6::R6Class("Random Forest Hyperparameters",

                              inherit = HyperparametersBase,

                              public = list(

                                mtry_tune = TRUE,
                                trees_tune = TRUE,
                                min_n_tune = TRUE,

                                default_hyperparams = function(){

                                  list(

                                    mtry = dials::mtry(range = c(3, 8)),
                                    trees = dials::trees(range = c(100, 300)),
                                    min_n = dials::min_n(range = c(2, 25))

                                  )

                                },

                                set_hyperparams = function(hyperparams = NULL){

                                  def_hyperparams = self$default_hyperparams()

                                    if (!is.null(hyperparams)) {

                                      def_hyperparams[names(hyperparams)] <- Map(function(name, value) {

                                        if (length(value) > 1) {

                                          func <- get(name, envir = asNamespace("dials"))
                                          func(range = value)

                                        } else {

                                          self[[paste0(name, "_tune")]] <- FALSE
                                          value
                                        }
                                      }, names(hyperparams), hyperparams)
                                    }

                                  return(def_hyperparams)

                                }
                              )
)
