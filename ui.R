#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Brexit prediction model"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
       selectInput("weights",
                   label = "Weights to use",
                   choices = list("None" = "ones",
                                  "N-weighted" = "N",
                                  "Sqrt(N)-weighted" = "sqrt_N"),
                   selected = "N"),
       
       sliderInput("span",
                   label = "Smoothing factor",
                   min = 0.05, max = 2,
                   value = .75,
                   step = .05),
       dateInput("date_start",
                      label = "Show polls from",
                      min = "2010-09-09",
                      max = "2016-06-23",
                      value = "2010-09-09"),
       actionButton("go", label = "Go!"),
       helpText("The plots will only update when you click this magic button.")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      HTML("<p>This is an interactive prediction model to forecast the result of <a href='https://en.wikipedia.org/wiki/United_Kingdom_European_Union_membership_referendum,_2016'>the British election about leaving the EU</a> ('Brexit') to be held on the 23rd of June, 2016.</p>"),
      HTML("<p>The model uses a moving average-type function (<a href='https://en.wikipedia.org/wiki/Local_regression'>LOESS</a>) to predict future values from the polling data <a href='https://ig.ft.com/sites/brexit-polling/'>here</a>. You can control the settings of the model by using the menu to the left.</p>"),
      tabsetPanel(
        tabPanel(title = "polls",
                 HTML("<p>This tab shows the polls and the fit. The red vertical line marks election day. Mouse-over the predicted value on election day to see the predicted outcome.</p>"),
                 plotlyOutput("polls")
                 ),
        tabPanel(title = "prediction confidence",
                 HTML("<p>How much confidence should we have in the prediction? This tab shows the distributed of predicted values based on <a href='https://en.wikipedia.org/wiki/Bootstrapping_%28statistics%29'>bootstrapping</a>. This may take a some seconds to calculate (depending on server load).</p>"),
                 plotOutput("confidence"),
                 HTML("<p>This calculation uses a <a href='https://en.wikipedia.org/wiki/Random_seed'>seed</a> to ensure reproducible results when using the same settings and data. Otherwise, results would vary slightly.</p>")
                 )
      ),
      HTML("<p>Made by <a href='http://emilkirkegaard.dk/'>Emil O. W. Kirkegaard</a>. Source code on <a href=''>Github</a>.</p>")
      
      
    )
  )
))
