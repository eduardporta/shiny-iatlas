subtypepredictor_UI <- function(id) {
  
  ns <- NS(id)
  
  tagList(
    titleBox("iAtlas Tools — Immune Subtype Predictor"),
    textBox(
      width = 12,
      p("Upload gene expression* and predict immune subtypes (* RSEM RPKM).")  
    ),
    
    # Immunomodulator distributions section ----
    sectionBox(
      title = "Model Based Clustering",
      messageBox(
        width = 12,
        p("Upload gene expression (csv or tsv). RSEM RPKM expression values were used to train the model, and for best results, your expression data should also be RSEM RPKMs (FPKMs will also work)."),
        p(""),
        p("Tool settings:"),
        tags$ul(
          tags$li(shiny::em('Log 2'), ", if the data is not already log transformed, select this."), 
          tags$li(shiny::em('Ensemble size'), ", try different ensemble sizes to check for robust results."),
          tags$li(shiny::em('File separator'), ", select commas or tabs.")
        ),
        p(""),
        p("Notes on input data:"),
        tags$ul(
          tags$li("First column should contain gene symbols, after that, samples."), 
          tags$li("Gene names (rows) must be unique (duplicated gene names not allowed)."),
          tags$li("Gene expression values will be log2 transformed and median centered per sample."),
          tags$li("For an example of outputs, leave the input file blank, set ensemble size to a small number (32) and click GO.")
        ),
        p(""),
        p("Manuscript context:  See figure 1A.")
      ),
      fluidRow(
        optionsBox(
          width = 12,
          column(
              width = 2,
              radioButtons(ns("sep"), "File Separator",
                           choices = c(Comma = ",", Tab = "\t"), selected = ","),
              checkboxInput(ns("logged"), "Apply Log2", TRUE)
          ),
          column(
            width = 4,
            fileInput(ns("expr_file_pred"), "Choose CSV file, First column gene symbols. Leave blank for example run.",
                      multiple = FALSE,
                      accept = c("text/csv",
                                 "text/comma-separated-values,text/plain",
                                 ".csv",
                                 ".csv.gz",
                                 "text/tsv",
                                 "text/comma-separated-values,text/plain",
                                 ".tsv",
                                 ".tsv.gz"),
                      placeholder = 'data/ivy20.csv')
          ),
          column(
            width = 3,
            numericInput(ns("ensemblenum"), "Ensemble Size (32-256)", 256, max = 256, min = 32, width = '100')
          ),
          column(
              width = 3,
              numericInput(ns("corenum"), "Cores (1-4)", 4, width = '100'),
              actionButton(ns("subtypeGObutton"), "GO")
          )
        )
      ),
      fluidRow(
        plotBox(
          width = 12,
          plotOutput(ns("distPlot")) %>% 
            shinycssloaders::withSpinner()
        )
      ),
      fluidRow(
        plotBox(
          width = 12,
          plotOutput(ns('barPlot')) %>% 
            shinycssloaders::withSpinner()
        )
      )
    ),
    
    # Immunomodulator annotations section ----
    sectionBox(
      title = "Subtype Prediction Results Table",
      messageBox(
        width = 12,
        p("The table shows the results of subtype prediction. Use the Search box in the upper right to find sample of interest.")  
      ),
      fluidRow(
        tableBox(
          width = 12,
          div(style = "overflow-x: scroll",
              DT::dataTableOutput(ns("subtypetable")) %>%
                shinycssloaders::withSpinner()
          )
        )
      )
    )
  )
}


subtypepredictor <- function(
    input, output, session, group_display_choice, group_internal_choice, 
    subset_df, plot_colors) {
    
    ns <- session$ns
    
    # in src files ... have same path as app.R
    reportedClusters <- getSubtypeTable()

    # get new calls
    getCalls <- eventReactive(input$subtypeGObutton, {
      newdat <- input$expr_file_pred
      print(head(newdat))
      #withProgress(message = 'Working...', value = 0, {
      #  newScores(newdat, input$logged, input$corenum)
      #})
      newScores(newdat, input$logged, input$corenum, input$ensemblenum)
    })
    
    # plot of where a sample is in signature space X clusters    
    output$distPlot <- renderPlot({
      #heatmap(as.matrix(getCalls()$Table), xlab = 'Reported Clusters', ylab = 'New Calls')
      imagePlot(getCalls()$Table)
    })
    
    
    output$barPlot <- renderPlot({
      counts <- table(getCalls()$MaxCalls)
      barplot(counts, main="New Cluster Label Calls", 
              xlab="Cluster Labels")
    })
    
    
    # Filter data based on selections
    output$subtypetable <- DT::renderDataTable(
      DT::datatable(
        as.data.frame(getCalls()$ProbCalls),
        extensions = 'Buttons', options = list(
          dom = 'Bfrtip',
          buttons = 
            list('copy', 'print', 
                 list(
                   extend = 'collection',
                   buttons = c('csv', 'excel', 'pdf'),
                   text = 'Download')
            )
        )
        
      )
    )
    
}