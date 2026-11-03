# Example Problem
The data for this problem is synthetic data, which means it was made up and doesn't represent the real world.

Please do not use any LLMs for this project to help you write code or advise you
on how to approach things. Most of the time you will not have access to these tools at work so it's better to represent your abilities than an LLMs. 

## Background
You recently joined a computer store as a data analyst. They sell computers and related technology to Fortune 100 customers. Last year the company migrated to a new ERP system that manages their sales and order information. You've been tasked to look into a potential problems:

#### Part 1 - Potentially Missing Shipments
After migrating to the new ERP system, the sales team has received calls from a few of
their customers that they never received products they ordered and were billed for. We don't see any issues in the ERP system, so you've been tasked to see if we are missing shipments.

The following CSV files are exports from a database:
- `items.csv` is a list of all the items and their values.
- `orders.csv` is a list of all the orders customers have placed.
- `shipments.csv` are all the corresponding shipments.
- `customers.csv` are all of our customers.


Orders are entered by line item, so a given `order_id` will have each item listed
an `item_id` that describes the item and an `id` for the line item. The company also doesn't ship complete, so orders are broken up by line item and shipped when available. The company tries to ship in batches as often as possible to save money. 

You've been asked to find the following:
1. Are there any orders or parts of orders that didn't ship? If so, provide the following information for any instance:
    - Order Number
    - Item Name
    - Quantity
    - Total value (price x quantity)
2. Describe how you would implement a process using to alert you of instances when
orders didn't ship completely. How would you track it? How would you automate it?
You don't need to write code for this part, but it would be good to some sort of visualization (diagram, workflow, etc)

#### Part 2 - Explore the data
The executive team is curious to find what insights you can gain from the sales and
order data. Create something visual (plots, dashboard, Shiny app. etc.) based on the data
and insights you found. 

This part is open ended so you get to be in the driver seat. This is a small dataset with a quick turnaround so we're not expecting journal-level statistical rigor or a
production level dashboard/app. Think of this as a prototype or beta version that you'd
present to get buy-in from leadership. 
