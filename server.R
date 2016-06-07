#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# scrape data -------------------------------------------------------------
#get newest data on website
d_brexit = read_html("https://ig.ft.com/sites/brexit-polling/") %>% html_node("table") %>% html_table()

#rename
colnames(d_brexit) = c("Stay", "Leave", "Undecided", "Date", "Pollster", "N")

# transform ---------------------------------------------------------------
#make gap
d_brexit$Favor_Leave = d_brexit$Leave - d_brexit$Stay

#interpret date
d_brexit$Date = lubridate::mdy(d_brexit$Date, locale = "English_United States.1252")
#this code may not run on your computer. If not, then find out how locales are treated there. You may not need to use a custom locale at all.

#num date
d_brexit$Date_num = as.numeric(d_brexit$Date)

#fix N
d_brexit$N[d_brexit$N == "-"] = NA #recode NA
d_brexit$N = d_brexit["N"] %>% as_num_df() %>% unlist() #convert to num

#impute N with medians
d_brexit$N[is.na(d_brexit$N)] = median(d_brexit$N, na.rm=T)

#other Ns
d_brexit$sqrt_N = sqrt(d_brexit$N) #for sqrt weights
d_brexit$ones = rep(1, nrow(d_brexit)) #for no weights

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
   
  output$polls = renderPlotly({
    
    #replot
    input$go
    
    isolate({
      #fetch weight data
      d_brexit$weights_var = d_brexit[[input$weights]]
  
      #loess
      fit_loess = loess("Favor_Leave ~ Date_num", data = d_brexit, control=loess.control(surface="direct"), weights = weights_var, span = input$span)
      v_predicted_outcome = predict(object = fit_loess, newdata = data.frame(Date_num = dmy("23 Jun 2016") %>% as.numeric()))
      d_brexit$loess_predict = fitted(fit_loess) #get values

      #plot
      gg = ggplot(d_brexit, aes(x = Date, y = Favor_Leave, weight = weights_var)) + 
        geom_point(aes(size = sqrt(N)), alpha = .3) + 
        scale_size_continuous(guide = F) + 
        geom_smooth(method = loess, fullrange = TRUE, method.args = list(control = loess.control(surface = "direct"), span = input$span)) +
        ylab("Leave advantage (%)") + 
        scale_x_date(limits = c(input$date_start, dmy("23 Jun 2016"))) +
        geom_vline(xintercept = dmy("23 Jun 2016") %>% as.numeric(), linetype = "dotted", color = "red")
      
      ggplotly(gg)
    })
    
    
  })
  
  output$confidence = renderPlot({
    
    #replot
    input$go
    
    isolate({
      #fetch weight data
      d_brexit$weights_var = d_brexit[[input$weights]]
  
      #bootstrap
      set.seed(1) #reproducible results
      boot_replications = boot(data = d_brexit, statistic = function(data, i) {
        #subset data
        tmp = data[i, ]
  
        #fit
        fit_loess = loess("Favor_Leave ~ Date_num", data = tmp, control=loess.control(surface="direct"), weights = weights_var, span = input$span)
  
        #get value
        predict(object = fit_loess, newdata = data.frame(Date_num = dmy("23 Jun 2016") %>% as.numeric()))
      }, R = 1000)
      
      #extract values
      v_values = boot_replications$t %>% as.vector()
      
      #leave win %
      v_leave_pct = percent_cutoff(v_values, cutoffs = 0)
      
      #plot
      GG_denhist(v_values) + 
        xlab("Election day 'Leave' advantage (bootstrapped, 1000 runs)") +
        annotate(geom = "text", x = 0, y = .5, label = "Probability that Leave will win = " + (v_leave_pct * 100) + "%", size = 5)
    })
    

  })
  
})
