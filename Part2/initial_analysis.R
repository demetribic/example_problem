library(tidyverse)

items = read_csv('items.csv')

customers = read_csv('customers.csv')

orders = read_csv('orders.csv')

shipments = read_csv('shipments.csv')

# Company-level analysis
#   - which companies bring in the most money for the company?

get_grouping_columns <- function(level) {
  switch(
    level,
    "company" = "company",
    "product" = c("company", "name"),
    stop("Invalid grouping level")
  )
}

get_target_bringing_in_most_money <- function(
    target = "company",
    start_date = min(orders$order_date, na.rm = TRUE),
    end_date = max(orders$order_date, na.rm = TRUE)
) {
  
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  
  if (start_date > end_date) {
    stop("start date cannot be after end date")
  }
  
  orders |>
    filter(
      order_date >= start_date,
      order_date <= end_date
    ) |>
    left_join(items, by = "item_id") |>
    mutate(total_value = price * quantity) |>
    group_by(across(all_of(get_grouping_columns(target)))) |>
    summarize(
      total_value = sum(total_value, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(total_value))
}

#   - the most potentially unshipped lines
get_target_with_most_potentially_unshipped_lines <- function(
    target = "company",
    start_date = min(orders$order_date, na.rm = TRUE),
    end_date = max(orders$order_date, na.rm = TRUE)
)
  {
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  
  if (start_date > end_date) {
    stop("start date cannot be after end date")
  }
  orders |>
    filter(
      order_date >= start_date,
      order_date <= end_date
    ) |>
    left_join(shipments, by = 'id', relationship = 'one-to-one') |>
    left_join(items, by = 'item_id', relationship = 'many-to-one') |>
    mutate(
      why_unshipped = case_when(
        is.na(status) ~ "No shipment record", 
        status == "Pending" ~ "Not yet shipped",
        TRUE ~ NA), 
      total_value = price * quantity) |>
    filter(!is.na(why_unshipped)) |>
    group_by(across(all_of(get_grouping_columns(target)))) |>
    summarize(missing_orders = n(), .groups = "drop") |>
    arrange(desc(missing_orders))
}
  

#   - quickest / slowest ship times?
get_target_with_quickest_ship_times <- function(
    target = "company",
    start_date = min(orders$order_date, na.rm = TRUE),
    end_date = max(orders$order_date, na.rm = TRUE)
){
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  
  if (start_date > end_date) {
    stop("start date cannot be after end date")
  }
  orders |>
    filter(
      order_date >= start_date,
      order_date <= end_date
    ) |>
    left_join(shipments, by = 'id', relationship = 'one-to-one') |>
    left_join(items, by = 'item_id', relationship = 'many-to-one') |>
    mutate(
      why_unshipped = case_when(
        is.na(status) ~ "No shipment record", 
        status == "Pending" ~ "Not yet shipped",
        TRUE ~ NA), 
      total_value = price * quantity,
      time_to_ship = ship_date - order_date) |>
    filter(is.na(why_unshipped)) |>
    group_by(across(all_of(get_grouping_columns(target)))) |>
    summarize(avg_time = mean(time_to_ship),  .groups = "drop") |>
    arrange(avg_time)
}


