
test_that("get_variable_classes", {
    test_df <- data_frame(
        "class" = c("class1", "class1", "class1", "class2", "class2", "class3",
                    "class4", "class4", "class4"),
        "type" = c("Numeric", "Numeric", "Numeric", "Factor", "Factor", 
                   "Numeric", "Logical", "Logical", "Logical"))
    expect_that(
        get_variable_classes(
            test_df, "class", "type", "Numeric"),
        is_identical_to(c("class1", "class3")))
})

test_that("get_feature_df_nested_list", {
    test_data_df <- data_frame(
        "name1" = c(1L, 2L, 3L),
        "name2" = c(1.1, 2.0, 3),
        "name3" = c(1L, 2L, 3L),
        "name4" = c(1.1, 2.0, 3),
        "name5" = c(1L, 2L, 3L),
        "name6" = c(1.1, 2.0, 3),
        "name7" = c("A", "B", "C"),
        "name8" = c(T, F, F),
        "name9" = factor(c("A", "B", "C")))
    test_feature_df <- data_frame(
        "class_col" = c(
            "class1", "class1", "class1", "class2", "class2", "class3",
            "class4", "class4", "class4"),
        "internal_col" = c(
            "name1", "name2", "name3", "name4", "name5", "name6",
            "name7", "name8", "name9"),
        "display_col" = c(
            "value1", "value2", "value3", "value4", "value5", "value6",
            "value7", "value8", "value9"))
    expect_that(
        get_feature_df_nested_list(
            test_feature_df, test_data_df, "class_col", "internal_col", "display_col"),
        is_identical_to(list(
            "class1" = c("value1" = "name1",
                         "value2" = "name2",
                         "value3" = "name3"),
            "class2" = c("value4" = "name4",
                         "value5" = "name5"),
            "class3" = c("value6" = "name6"))))
})

test_that("df_to_nested_list", {
    test_df1 <- data_frame(
        "class_col" = c("class1", "class1", "class1", "class2", "class2", "class3"),
        "internal_col" = c("name1", "name2", "name3", "name4", "name5", "name6"),
        "display_col" = c("value1", "value2", "value3", "value4", "value5", "value6"))
    expect_that(
        df_to_nested_list(test_df1, "class_col", "internal_col", "display_col"),
        is_identical_to(list(
            "class1" = c("value1" = "name1",
                         "value2" = "name2",
                         "value3" = "name3"),
            "class2" = c("value4" = "name4",
                         "value5" = "name5"),
            "class3" = c("value6" = "name6"))))
})

test_that("get_display_numeric_columns", {
    test_df1 <- data_frame(
        "col1" = c(1L, 2L, 3L),
        "col2" = c(1.1, 2.0, 3),
        "col3" = c("A", "B", "C"),
        "col4" = c(T, F, F),
        "col5" = factor(c("A", "B", "C")))
    translation_df <- data_frame(
        "internal_name" = c("col1", "col2", "col3", "col4", "col5"),
        "display_name1" = c("int", "dbl", "chr", "lgl", "fct"),
        "display_name2" = c("colA", "colB", "colC", "colD", "colF"))
    expect_that(
        get_display_numeric_columns(test_df1, translation_df, "internal_name", "display_name1"),
        is_identical_to(c("int", "dbl")))
    expect_that(
        get_display_numeric_columns(test_df1, translation_df, "internal_name", "display_name2"),
        is_identical_to(c("colA", "colB")))
})

test_that("decide_plot_colors", {
    test_group_df <- data_frame(
        "user_group1" = c("class1", "class2", "class3", "class4"),
        "user_group2" = c("class1", "class2", "class3", "class3"))
    test_config_list <- list(
        "immune_groups" = list(
            "preset_group1", 
            "preset_group2", 
            "preset_group3", 
            "preset_group4"),
        "immune_group_colors" = list(
            "preset_group1" = "colors1",
            "preset_group2" = "colors2",
            "preset_group3" = "colors3"))
    test_data_object <- list(
        "colors1" = c("BRCA" = "#ED2891", "GBM" = "#B2509E"),
        "colors2" = c("C1" = "#FF0000", "C2" = "#FFFF00"))
    
    expect_that(
        decide_plot_colors("preset_group1", test_group_df, test_data_object, test_config_list),
        is_identical_to(c(
            "BRCA" = "#ED2891", 
            "GBM" = "#B2509E")))
    expect_that(
        decide_plot_colors("user_group1", test_group_df, test_data_object, test_config_list),
        is_identical_to(c(
            "class1" = "#E41A1C", 
            "class2" = "#377EB8", 
            "class3" = "#4DAF4A", 
            "class4" = "#984EA3")))
    
    expect_that(
        get_study_plot_colors("preset_group1", test_data_object, test_config_list),
        is_identical_to(c("BRCA" = "#ED2891", "GBM" = "#B2509E")))
    expect_that(
        get_study_plot_colors("preset_group2", test_data_object, test_config_list),
        is_identical_to(c("C1" = "#FF0000", "C2" = "#FFFF00")))
    expect_that(
        get_study_plot_colors("preset_group3", test_data_object, test_config_list),
        throws_error("color group missing from data object for: preset_group3 colors3"))
    expect_that(
        get_study_plot_colors("preset_group4", test_data_object, test_config_list),
        throws_error("colors group name missing from config for: preset_group4"))
        
    expect_that(
        create_user_group_colors("user_group1", test_group_df),
        is_identical_to(c(
            "class1" = "#E41A1C", 
            "class2" = "#377EB8", 
            "class3" = "#4DAF4A", 
            "class4" = "#984EA3")))
    expect_that(
        create_user_group_colors("user_group2", test_group_df),
        is_identical_to(c(
            "class1" = "#E41A1C", 
            "class2" = "#377EB8", 
            "class3" = "#4DAF4A")))
})

test_that("get_factored_variables_by_class", {
    test_df <- data_frame(
        "class col" = c("class1", "class1", "class1", "class2", "class2", "class2"),
        "variable col" = c("var1", "var2", "var3", "var4", "var5", "var6"),
        "order col" = c(1,2,3,3,2,1))
    expect_that(
        get_factored_variables_by_class(
            "class1", test_df, "class col", "variable col", "order col"),
        is_identical_to(
            factor(c("var1", "var2", "var3"), levels = c("var1", "var2", "var3"))))
    expect_that(
        get_factored_variables_by_class(
            "class2", test_df, "class col", "variable col", "order col"),
        is_identical_to(
            factor(c("var6", "var5", "var4"),  levels = c("var6", "var5", "var4"))))
    expect_that(
        get_factored_variables_by_class(
            "class3", test_df, "class col", "variable col", "order col"),
        throws_error("empty class: class3"))
})

test_that("factor_variables_with_df", {
    test_df1 <- data_frame(
        "variable_col" = c("var1", "var2", "var3"),
        "order_col" = c(1,2,3))
    test_df2 <- data_frame(
        "variable_col" = c("var4", "var5", "var6"),
        "order_col" = c(3,2,1))
    expect_that(
        factor_variables_with_df(test_df1, "variable_col", "order_col"),
        is_identical_to(factor(c("var1", "var2", "var3"),
                               levels = c("var1", "var2", "var3"))))
    expect_that(
        factor_variables_with_df(test_df2, "variable_col", "order_col"),
        is_identical_to(factor(c("var6", "var5", "var4"),
                               levels = c("var6", "var5", "var4"))))
})

test_that("get_complete_class_df", {
    test_df <- data_frame(
        "class col" = c("class1", "class1", "class1", "class2", "class2", "class2"),
        "variable col" = c("var1", "var2", "var3", "var4", "var5", "var6"),
        "order col" = c(1,2,3,3,2,1))
    result_df1 <- data_frame(
        "variable col" = c("var1", "var2", "var3"),
        "order col" = c(1,2,3))
    result_df2 <- data_frame(
        "variable col" = c("var4", "var5", "var6"),
        "order col" = c(3,2,1))
    expect_that(
        get_complete_class_df("class1", test_df, "class col", "variable col", "order col"),
        is_identical_to(result_df1))
    expect_that(
        get_complete_class_df("class2", test_df, "class col", "variable col", "order col"),
        is_identical_to(result_df2))
})

test_that("get_complete_df_by_columns",{
    test_df <- data_frame(
        "col1" = c("val1", "val2", "val3"),
        "col2" = c(NA, 1, 2))
    expect_that(
        get_complete_df_by_columns(test_df, c("col1")),
        is_identical_to(data_frame(
            "col1" = c("val1", "val2", "val3"))))
    expect_that(
        get_complete_df_by_columns(test_df, c("col1", "col2")),
        is_identical_to(data_frame(
            "col1" = c("val2", "val3"),
            "col2" = c(1, 2))))
})

test_that("get_group_internal_name", {
    test_df1 <- data_frame("FriendlyLabel" = c("value1", "value3", "value3"),
                           "FeatureMatrixLabelTSV" = c("A", "B", "C"))
    expect_that(
        get_group_internal_name("value1", test_df1), 
        is_identical_to("A"))
    expect_that(
        get_group_internal_name("value2", test_df1), 
        is_identical_to("value2"))
    expect_that(
        get_group_internal_name("value3", test_df1),
        throws_error("group name has multiple matches: value3 matches: B, C"))
})

test_that("convert_value_between_columns", {
    test_df1 <- data_frame("col1" = c("value1", "value2"),
                           "col2" = c("A", "B"),
                           "col3" = c("C", "C"))
    expect_that(
        convert_value_between_columns(test_df1, "value1", "col1", "col2"), 
        is_identical_to("A"))
    expect_that(
        convert_value_between_columns(test_df1, "value2", "col1", "col2"), 
        is_identical_to("B"))
    expect_that(
        convert_value_between_columns(test_df1, "value1", "col1", "col3"), 
        is_identical_to("C"))
    expect_that(
        convert_value_between_columns(test_df1, "C", "col3", "col1"), 
        is_identical_to(c("value1", "value2")))
    expect_that(
        convert_value_between_columns(test_df1, "value3", "col1", "col2"), 
        is_identical_to(vector(mode = "character", length = 0)))
})

test_that("get_unique_column_values", {
    test_df1 <- data_frame("col" = c("value1", "value2"))
    test_df2 <- data_frame("col" = c("value1", "value1"))
    test_df3 <- data_frame("col" = c("value1", NA))
    test_df4 <- data_frame("col" = c(5, 6))
    test_df5 <- data_frame("col" = c("value2", "value1"))
    expect_that(
        get_unique_column_values("col", test_df1),
        is_identical_to(c("value1", "value2")))
    expect_that(
        get_unique_column_values("col", test_df2),
        is_identical_to(c("value1")))
    expect_that(
        get_unique_column_values("col", test_df3),
        is_identical_to(c("value1")))
    expect_that(
        get_unique_column_values("col", test_df4),
        is_identical_to(c("5", "6")))
    expect_that(
        get_unique_column_values("col", test_df5),
        is_identical_to(c("value1", "value2")))
})