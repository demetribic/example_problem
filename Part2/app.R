library(tidyverse)
library(shiny)
library(plotly)
library(DT)

items = read_csv('items.csv')

customers = read_csv('customers.csv')

orders = read_csv('orders.csv')

shipments = read_csv('shipments.csv')

orders$order_date <- as.Date(orders$order_date)
shipments$ship_date <- as.Date(shipments$ship_date)

bar_metrics <- list(
  money = c(column = "total_value", title = "Order value ($)"),
  unshipped = c(column = "incomplete_pct", title = "Incomplete lines (%)"),
  shipping = c(column = "avg_ship_days", title = "Average shipping days")
)

ui <- fluidPage(
  h2("Sales & Fulfillment Dashboard"),
  
  fluidRow(
    column(5, dateRangeInput(
      "dates", "Order dates",
      start = min(orders$order_date),
      end = max(orders$order_date),
      width = "100%"
    )),
    column(4, selectInput(
      "target", "Analyze by",
      c("Company" = "company", "Company + Product" = "product"),
      width = "100%"
    )),
    column(3, numericInput(
      "max_rows", "Max rows", 10, min = 1, width = "100%"
    ))
  ),
  
  tabsetPanel(
    id = "tab",
    tabPanel("Order Value", value = "money"),
    tabPanel("Incomplete Lines", value = "unshipped"),
    tabPanel("Shipping Times", value = "shipping"),
    tabPanel("3D Analysis", value = "3d")
  ),
  
  plotlyOutput("chart"),
  h4("Results — click a column to sort"),
  DTOutput("results")
)

server <- function(input, output, session) {
  
  summary_data <- reactive({
    req(input$dates, input$target)
    groups <- c(
      "company",
      if (input$target == "product") c("item_id", "name")
    )
    
    orders |>
      filter(between(order_date, input$dates[1], input$dates[2])) |>
      left_join(shipments, by = "id", relationship = "one-to-one") |>
      left_join(items, by = "item_id", relationship = "many-to-one") |>
      mutate(
        incomplete = is.na(status) | status != "Complete",
        ship_days = if_else(
          status == "Complete",
          as.numeric(ship_date - order_date),
          NA_real_
        )
      ) |>
      group_by(across(all_of(groups))) |>
      summarize(
        total_value = sum(price * quantity, na.rm = TRUE),
        total_lines = n(),
        incomplete_lines = sum(incomplete),
        incomplete_pct = 100 * mean(incomplete),
        completed_lines = sum(!is.na(ship_days)),
        avg_ship_days = if (all(is.na(ship_days))) NA_real_
        else mean(ship_days, na.rm = TRUE),
        .groups = "drop"
      ) |>
      mutate(
        label = if (input$target == "product")
          paste(company, name, item_id, sep = " | ")
        else company
      )
  })
  
  filtered_data <- reactive({
    req(input$tab)
    rows <- summary_data()
    
    if (input$tab %in% c("shipping", "3d")) {
      rows <- filter(rows, is.finite(avg_ship_days))
    }
    
    rows
  })
  
  output$results <- renderDT({
    table_data <- filtered_data() |>
      transmute(
        `Company / Product` = label,
        `Order Value ($)` = total_value,
        `Total Lines` = total_lines,
        `Incomplete Lines` = incomplete_lines,
        `Incomplete (%)` = incomplete_pct,
        `Completed Lines` = completed_lines,
        `Avg Ship Days` = avg_ship_days
      )
    
    datatable(
      table_data,
      rownames = FALSE,
      selection = "none",
      options = list(
        dom = "t",
        paging = TRUE,
        pageLength = max(1L, as.integer(req(input$max_rows))),
        searching = FALSE,
        scrollX = TRUE,
        orderMulti = FALSE,
        order = list(list(1, "desc"))
      )
    ) |>
      formatCurrency("Order Value ($)", digits = 0) |>
      formatRound(c("Incomplete (%)", "Avg Ship Days"), digits = 1)
  }, server = FALSE)
  
  output$chart <- renderPlotly({
    rows <- filtered_data()
    validate(need(nrow(rows) > 0, "No results to display"))
    
    req(input$results_rows_current)
    rows <- rows[input$results_rows_current, , drop = FALSE]
    validate(need(nrow(rows) > 0, "No results to display"))
    
    if (input$tab == "3d") {
      plot_ly(
        rows,
        x = ~total_value,
        y = ~avg_ship_days,
        z = ~incomplete_pct,
        text = ~label,
        type = "scatter3d",
        mode = "markers",
        marker = list(
          size = 6,
          color = rows$incomplete_pct,
          colorscale = "magma",
          cmin = 0,
          cmax = 100,
          showscale = TRUE
        )
      ) |>
        layout(scene = list(
          xaxis = list(title = "Order value ($)"),
          yaxis = list(title = "Average shipping days"),
          zaxis = list(title = "Incomplete lines (%)")
        ))
    } else {
      metric <- bar_metrics[[input$tab]]
      
      plot_ly(
        rows,
        x = rows[[metric[["column"]]]],
        y = ~label,
        type = "bar",
        orientation = "h"
      ) |>
        layout(
          xaxis = list(title = metric[["title"]]),
          yaxis = list(
            title = "",
            categoryorder = "array",
            categoryarray = rev(rows$label)
          ),
          margin = list(l = 210)
        )
    }
  })
}

shinyApp(ui, server)
