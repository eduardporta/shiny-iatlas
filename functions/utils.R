
# these switch between internal name and display name -------------------------

get_group_internal_name <- function(input_name, df = panimmune_data$feature_df){
    internal_name <- get_variable_internal_name(input_name, df)
    if (length(internal_name) == 0){
        return(input_name) # user supplied group names
    } else if (length(internal_name) == 1) {
        return(internal_name) # standard group names
    } else {
        stop("group name has multiple matches: ", 
             input_name, 
             " matches: ", 
             str_c(internal_name, collapse = ", "))
    }
}

get_variable_display_name <- function(name, df = panimmune_data$feature_df){
    convert_value_between_columns(
        df, name, "FeatureMatrixLabelTSV", "FriendlyLabel")
}

get_variable_internal_name <- function(name, df = panimmune_data$feature_df){
    convert_value_between_columns(
        df, name, "FriendlyLabel", "FeatureMatrixLabelTSV")
}

get_im_display_name <- function(
    name, df = panimmune_data$im_direct_relationships){
    
    convert_value_between_columns(df, name, "HGNC Symbol", "Gene")
}

convert_value_between_columns <- function(df, value, old_col, new_col){
    df %>% 
        dplyr::select(OLD = old_col, NEW = new_col) %>% 
        dplyr::filter(OLD == value) %>% 
        magrittr::use_series(NEW)
}

# factor variables ------------------------------------------------------------

get_factored_variables_from_feature_df <- function(class_name){
    get_factored_variables_by_class(
        class_name, 
        df = panimmune_data$feature_df,
        class_column = "Variable Class",
        variable_column = "FeatureMatrixLabelTSV",
        order_column = "Variable Class Order" 
    )
}

get_factored_variables_by_class <- function(
    class_name, df, class_column, variable_column, order_column){
    
    class_df <- get_complete_class_df(
        class_name, df, class_column, variable_column, order_column)
    if (nrow(class_df) == 0) {
        stop("empty class: ", class_name)
    }
    factor_variables_with_df(class_df, variable_column, order_column)
}

factor_variables_with_df <- function(df, variable_column, order_column){
    df %>% 
        dplyr::select(VAR = variable_column, ORDER = order_column) %>% 
        dplyr::arrange(ORDER) %>% 
        magrittr::use_series(VAR) %>% 
        factor(., levels = .)
}

get_complete_class_df <- function(
    class_name, df, class_column, variable_column, order_column){
    
    df %>% 
        dplyr::select(CLASS = class_column, variable_column, order_column) %>% 
        get_complete_df_by_columns(c(
            "CLASS",
            variable_column,
            order_column)) %>% 
        dplyr::filter(CLASS == class_name) %>% 
        dplyr::select(variable_column, order_column)
}


get_complete_df_by_columns <- function(df, columns){
    df %>%
        dplyr::select(columns) %>%
        .[complete.cases(.),] 
}

# colors for plotting groups --------------------------------------------------

decide_plot_colors <- function(
    sample_group_label, 
    group_df = NULL, 
    data_object = panimmune_data, 
    config_list = config_yaml) {
    
    if (sample_group_label %in% config_list$immune_groups) {
        return(get_study_plot_colors(sample_group_label, data_object, config_list))
    } else {
        return(create_user_group_colors(sample_group_label, group_df))
    }
}

get_study_plot_colors <- function(
    group_name, data_object = panimmune_data, config_list = config_yaml){
    
    color_group_name <- config_list$immune_group_colors[[group_name]]
    if(is.null(color_group_name)){
        stop("colors group name missing from config for: ", group_name)
    }
    color_group <- data_object[[color_group_name]]
    if(is.null(color_group)){
        stop("color group missing from data object for: ", group_name, " ", color_group_name)
    }
    return(color_group)
}

create_user_group_colors <- function(sample_group_label, group_df){
    groups <- group_df %>% 
        magrittr::extract2(sample_group_label) %>% 
        unique() %>% 
        sort()
    colors <- RColorBrewer::brewer.pal(length(groups), "Set1")
    magrittr::set_names(colors, groups)
}


# -----------------------------------------------------------------------------

get_feature_df_nested_list <- function(){
    get_nested_list1(
        feature_df = panimmune_data$feature_df,
        data_df = panimmune_data$fmx_df,
        class_column = "Variable Class",
        internal_column = "FeatureMatrixLabelTSV",
        display_column = "FriendlyLabel"
    )
}


get_immunomodulator_nested_list <- function(
    class_column = "Gene Family",
    display_column = "Gene",
    internal_column = "HGNC Symbol"){
    
    panimmune_data$im_direct_relationships %>%
        dplyr::select(
            CLASS = class_column,
            DISPLAY = display_column,
            INTERNAL = internal_column) %>% 
        dplyr::mutate(CLASS = ifelse(is.na(CLASS), "Other", CLASS)) %>%
        drop_na() %>% 
        df_to_nested_list(
            group_column = "CLASS",
            key_column = "INTERNAL",
            value_column = "DISPLAY")
}

get_nested_list1 <- function(
    feature_df,
    data_df,
    class_column,
    internal_column,
    display_column){
    
    numeric_columns <- get_display_numeric_columns(
        df = data_df,
        translation_df = feature_df,
        df_column = internal_column,
        translation_df_column = display_column)
    feature_df %>%
        dplyr::select(
            CLASS = class_column,
            DISPLAY = display_column,
            INTERNAL = internal_column) %>%
        dplyr::filter(DISPLAY %in% numeric_columns) %>%
        dplyr::mutate(CLASS = ifelse(is.na(CLASS), "Other", CLASS)) %>%
        df_to_nested_list(
            group_column = "CLASS",
            key_column = "INTERNAL",
            value_column = "DISPLAY")
}

get_display_numeric_columns <- function(
    df, translation_df, df_column, translation_df_column){
    
    df %>% 
        dplyr::select_if(is.numeric) %>% 
        colnames() %>% 
        purrr::map(function(name) convert_value_between_columns(
            translation_df,
            name,
            df_column,
            translation_df_column)) %>% 
        purrr::compact() %>% 
        unlist() %>% 
        purrr::discard(~is.na(.))
}

df_to_nested_list <- function(df, group_column, key_column, value_column){
    df %>% 
        dplyr::select(group_column, value_column, key_column) %>% 
        tidyr::nest(-1) %>%
        dplyr::mutate(data = purrr::map(data, tibble::deframe)) %>% 
        tibble::deframe()
}


# -----------------------------------------------------------------------------

get_numeric_classes_from_feature_df <- function(){
    get_variable_classes(
        df = panimmune_data$feature_df,
        class_column = "Variable Class",
        type_column = "VariableType", 
        value = "Numeric")
}

get_variable_classes <- function(df, class_column, type_column, value){
    df %>% 
        dplyr::select(CLASS = class_column, TYPE = type_column) %>% 
        dplyr::filter(TYPE == value) %>% 
        magrittr::use_series(CLASS) %>% 
        unique %>% 
        purrr::discard(is.na(.))
}

# -----------------------------------------------------------------------------

get_unique_column_values <- function(category, df){
    df %>% 
        magrittr::extract2(category) %>% 
        na.omit() %>%
        unique() %>%
        sort() %>%
        as.character()
}

check_immunefeatures_scatterplot_click_data <- function(
    eventdata, subset_df, group_column, corr_df){
    
    if(is.null(eventdata)) {
        return(FALSE)  
    } 
    column_name <- eventdata$x[[1]]
    row_name  <- eventdata$y[[1]]
    column_name_valid <- column_name %in% extract2(subset_df, group_column)
    row_name_valid <- any(
        get_variable_internal_name(row_name) %in% colnames(corr_df))
    all(column_name_valid, row_name_valid)
}

check_driver_violinplot_click_data <- function(
  eventdata, df_for_regression,subset_df, group_column){
  
  if(is.null(eventdata)) {
    return(FALSE)  
  } 
  
  combo_selected <- eventdata[["key"]][[1]][1]
  combo_valid <- combo_selected %in% extract2(df_for_regression,"combo")
  
  all(combo_valid)
}

create_group_text_from_plotly <- function(
    source_name,
    source_type = "plotly_click",
    prompt_text = "Click above plot for more group information.",
    key_column = "key"){
    
    data <- event_data(source_type, source = source_name)
    
    if (is.null(data)){
        text = prompt_text
    } else {
        key_value <- data %>%
            slice(1) %>% 
            extract2(key_column)
        text <- panimmune_data$sample_group_df %>% 
            filter(FeatureValue == key_value) %>% 
            distinct() %>% 
            slice(1) %>% 
            mutate(Characteristics = 
                       ifelse(is.na(Characteristics), 
                              "No additional infoformation.", 
                              Characteristics)) %>% 
            mutate(name = 
                       ifelse(is.na(FeatureName), 
                              FeatureValue, 
                              FeatureName)) %>% 
            mutate(text = str_c(name, ": ", Characteristics)) %>% 
            use_series(text)
    }
    return(text)
}


## selection choices for the dropdown menu of sample groups
# create_sample_group_options <- function(feature_df) {
#     feature_df %>%
#         filter(`Variable Class` == "Sample Category") %>%
#         use_series(FeatureMatrixLabelTSV) 
# }
