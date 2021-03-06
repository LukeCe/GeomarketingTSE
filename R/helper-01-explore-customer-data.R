concentration_plot <- function(data_table,variable){

  data_table <- copy(data_table) %>% setDT()
  data_table <- data_table[variable > 0,]
  data_table[,sales_rank:=frank(-sales,ties.method = "random")]
  setorder(data_table,sales_rank)

  nb_customer <- nrow(data_table)
  total_sales <- sum(sales)

  data_table[order(sales_rank),cum_sales := cumsum(sales)]
  data_table[order(sales_rank),rcum_sales := cum_sales / total_sales]
  data_table[,client_no := sales_rank / nb_customer]

  half_turnover <- data_table[rcum_sales < 0.5,] %>% nrow() / nb_customer
  half_turnover <- half_turnover %>% round(2)

}
