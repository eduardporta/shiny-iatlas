# Load curated data ----

load_manifest <- function() {
    if (!USE_REMOTE_GS) {
        list(
            feature_df = feather::read_feather("data/feature_df.feather"),
            feature_method_df = read_feather("data/feature_method_df.feather"),
            sample_group_df = read_feather("data/sample_group_df.feather")
        )
    } else {
        fetch_manifest() %>% 
            format_manifest()
    }
}

load_feature_matrix <- function() {
    if (!USE_REMOTE_GS) {
        fmx <- list(
            fmx_df = read_feather("data/fmx_df.feather")
        )
    } else {
        fmx <- fetch_feature_matrix() %>% 
            format_feature_matrix()
    }
    return(fmx)
}

load_im_annotations <- function() {
    if (!USE_REMOTE_GS) {
        list(
            im_direct_relationships = read_feather(
                "data/im_direct_relationships.feather"
            ),
            im_potential_factors = read_feather(
                "data/im_potential_factors.feather"
            )
        )
    } else {
        fetch_im_annotations() %>% 
            format_im_annotations()
    }
}

load_im_expression <- function() {
    if (!USE_REMOTE_BQ) {
        list(
            im_expr_df = read_feather("data/im_expr_df.feather")
        )
    } else {
        fetch_im_expression() %>% 
            format_im_expression()
    }
}

load_driver_mutation <- function() {
  if (!USE_REMOTE_BQ) {
    list(
      driver_mutation_df = read_feather("data/driver_mutations.feather")
    )
  } else {
    fetch_driver_mutation() %>% 
      format_driver_mutation()
  }
}

# Helper functions ----

# ** Color maps for sample groups ----

create_immune_subtype_colors <- function(sample_group_df) {
    immune_subtypes_df <- sample_group_df %>% 
        filter(sample_group == "immune_subtype") %>% 
        distinct()
    
    immune_subtypes_df$FeatureHex %>% 
        set_names(immune_subtypes_df$FeatureValue)
}

create_tcga_study_colors <- function(sample_group_df) {
    tcga_study_df <- sample_group_df %>% 
        filter(sample_group == "tcga_study") %>% 
        distinct()
    
    tcga_study_df$FeatureHex %>% 
        set_names(tcga_study_df$FeatureValue)
}

create_tcga_subtype_colors <- function(sample_group_df) {
    tcga_subtype_df <- sample_group_df %>%
        filter(sample_group == "tcga_subtype",
               !is.na(FeatureValue)) %>% 
        group_by(`TCGA Studies`) %>% 
        mutate(
            FeatureHex = suppressWarnings(
                RColorBrewer::brewer.pal(length(FeatureValue), "Set1") %>% 
                    .[1:length(FeatureValue)]
            )
        ) %>% 
        ungroup() 
    
    tcga_subtype_df$FeatureHex %>%
        set_names(tcga_subtype_df$FeatureValue)
}


## selection choices for the cell fractions.  Lots of other choices possible.
create_cell_fraction_options <- function() {
    if (!USE_REMOTE_BQ) {
        config_yaml$cell_fractions_local
    } else {
        config_yaml$cell_fractions_bq
    }
}

# Load global data ----

load_data <- function() {
    
    manifest_data <- load_manifest()
    feature_matrix_data <- load_feature_matrix()
    im_annotations_data <- load_im_annotations()
    im_expression_data <- load_im_expression()
    driver_mutation_data <- load_driver_mutation()
    list(
        feature_df = manifest_data$feature_df,
        feature_method_df = manifest_data$feature_method_df,
        sample_group_df = manifest_data$sample_group_df,
        fmx_df = feature_matrix_data$fmx_df,
        tcga_study_colors = create_tcga_study_colors(
            manifest_data$sample_group_df),
        immune_subtype_colors = create_immune_subtype_colors(
            manifest_data$sample_group_df),
        tcga_subtype_colors = create_tcga_subtype_colors(
            manifest_data$sample_group_df),
        im_direct_relationships = im_annotations_data$im_direct_relationships,
        im_potential_factors = im_annotations_data$im_potential_factors,
        im_expr_df = im_expression_data$im_expr_df,
        driver_mutation_df = driver_mutation_data$driver_mutation_df
    )
}
