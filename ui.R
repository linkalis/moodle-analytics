library(shiny)


shinyUI(pageWithSidebar(
  
  # Application title
  headerPanel("Moodle Analytics 2.4",
              
              ## Suppress the word 'Error' and change color of error messages with CSS styling
              tags$head(
                tags$style(type="text/css",
                           ".shiny-output-error { color: green; }",
                           ".shiny-output-error:before { visibility: hidden; }"
                ))),
  
  sidebarPanel(
    
    h3("1. Upload your logs"),
    p("To access the logs from within your Moodle site, click on 'Navigation' > 'Reports' > 'Logs'. 
      On the 'Logs' page, select 'All participants', 'All days', 'All activities', and 'All actions'. Finally, 
      select 'Download in text format' and save the file to your computer."),
    fileInput("userfile", "Then, upload your Moodle log file in .txt format here:", accept="txt file"),
    
    h3("2. Select a student"),
    uiOutput("studentnames"),
    
    h3("3. Select activities"),
    checkboxGroupInput("activities", "Select activities to add to chart:", 
                       c("Assignment view" = "assign view",
                         "Course view" = "course view",
                         "Forum discussion" = "forum add discussion",
                         "Forum post" = "forum add post",
                         "Forum view" = "forum view forum",
                         "Page view" = "page view",
                         "Quiz view" = "quiz view",
                         "URL view" = "url view"  
                       ), 
                       selected = c("Course view")),
    p("Questions? Contact linkalis (at) gmail (dot) com.")
    ),
  
  mainPanel(
    tabsetPanel(      
      
      tabPanel("Charts",
               
               h2("What did they access?"),
               p("Compare the number of times the selected student accessed each activity (in green)
                 vs. the class average (in gray). Use the checkboxes in the left-hand panel to add and remove 
                 activities from the chart."),
               plotOutput("studentvsaverageplot"),
               
               
               h2("When in the semester did they access?"),
               p("Visualize when in the semester the selected student most frequently accessed the selected activities. 
                 Note: The scale along the bottom DOES NOT correspond one-to-one with weeks in the semester.  You may 
                 need to do some mental calculation to map dates to semester weeks."),
               plotOutput("studentchronology"),
               
               h2("What days of the week did they access?"),
               p("Visualize what days of the week the selected student most frequently accessed the selected activities."),
               plotOutput("daysoftheweek"),
               
               h2("What times of day did they access?"),
               p("Visualize the times of day that the selected student most frequently accessed the selected activities."),
               plotOutput("timesofday")),
      
      tabPanel("Activity Summary",
               p("This table is an overview of ALL activities that were accessed at some point during
                 your Moodle course. In the middle column, examine how frequently your selected student 
                 accessed each activity. In the right-hand column, compare their access patterns to the
                 class average."),
               tableOutput("studentactivitysummary"))
    )
    
  )
))