library(shiny)

## Allow Shiny to accept file uploads up to 30MB
options(shiny.maxRequestSize=30*1024^2)

shinyServer(function(input, output) {
  
  ##################
  ## Read in data ##
  ##################
  
  # Full course logs for detailed activity summary table
  courselogsfull <- reactive({
    if(is.null(input$userfile)) stop('Please upload a file')
      inFile <- input$userfile
      logs <- read.table(inFile$datapath, sep="\t", skip=1, header=TRUE)
      logs <- logs[order(logs$User.full.name, logs$Action), ]
    })
  
  # Course logs aggregated into activity categories
  courselogs <- reactive({
    if(is.null(input$userfile)) stop('Please upload a file')
      ## Read in file, skipping first line; then order by 1) student name, and 2) activity
      inFile <- input$userfile
      logs <- read.table(inFile$datapath, sep="\t", skip=1, header=TRUE)
      logs <- logs[order(logs$User.full.name, logs$Action), ]
      
      ## Strip URL labels from actions, then calculate overall usage counts for each action category
      # http://stackoverflow.com/questions/1138552/replace-string-in-parentheses-using-regex
      logs$Action <- gsub("[ ]\\(.+?\\)", "", logs$Action)
      logs
    })
  
  
  #################################
  ## Student Selector UI Element ##
  #################################
  output$studentnames <- renderUI({
    students <- unique(courselogs()$User.full.name)
    # To 'students' array is in factor format and masks student names in selectInput and uses numbers instead.
    # To have student full names show in the selectInput, comment out the line below to convert 'students' to vector format:
    # students <- as.vector(students)
    selectInput("student", "Choose a student:", students)
  })
  

  #######################################################
  ## Calculate average usage data for comparison plots ##
  #######################################################
  
  ## Calculate number of students
  numstudents <- reactive({
    length(unique(courselogs()$User.full.name))
    })
  
  ## Create a data frame with Var1, Freq, averageactions
  classaverageactions <- reactive({
    totalactions <- as.data.frame(table(courselogs()$Action))
    totalactions$averageactions <- totalactions$Freq/numstudents()
    totalactions
  })
  
  
  ############################
  ## Activity summary table ##
  ############################
  
  output$studentactivitysummary <- renderTable({
    # Calculate full activity counts for single student
    studentlogs <- courselogsfull()[courselogsfull()$User.full.name==Student(), ]
    studentactions <- as.data.frame(table(studentlogs$Action))
    
    # Calculate class average activity counts
    totalactions <- as.data.frame(table(courselogsfull()$Action))
    totalactions$averageactions <- totalactions$Freq/numstudents()
    
    # Combine relevant columns into single data frame to compare single student to class average
    activitysummarydf <- cbind(studentactions[ , c(1,2)], totalactions[ , 3])
    setNames(activitysummarydf, c("Moodle Activity", "Student's Frequency of Access", "Class Average Frequency of Access"))
  })
  
  
  ###########################################################################
  ## Generate charts based on student selected and actions checked by user ##
  ###########################################################################  

  Student <- reactive({
    input$student
  })
  
  Actions <- reactive({
    input$activities
  })
  
  ## 'What did they access?' Plot ##
  output$studentvsaverageplot <- renderPlot({
    studentlogs <- courselogs()[courselogs()$User.full.name==Student() & (courselogs()$Action %in% Actions()), ]
    studentactions <- as.data.frame(table(studentlogs$Action))
    #studentactions <- studentactions[order(studentactions$Var1), ]
    totalactions <- classaverageactions()[classaverageactions()$Var1 %in% Actions(), ]
    #totalactions <- totalactions[order(totalactions$Var1), ]
    studentvsaverage <- rbind(studentactions$Freq, totalactions$averageactions)
    
    if(nrow(studentactions) != length(Actions())) stop('Selected student did not access this activity. Please unselect and try a different activity.')
    barplot(studentvsaverage, col=c("green", "grey"), names.arg=Actions(), beside=T, ylab="Number of times accessed", ylim=c(0,400))
  })
    # Isn't updating column heights properly--seems to be shifting them over to other parts of plot w/o fully refreshing!
    # Problem w/ alphabetization?
  
  ## 'When in the semester did they access?' Plot ##
  output$studentchronology <- renderPlot({
    studentlogs <- courselogs()[courselogs()$User.full.name==Student() & (courselogs()$Action %in% Actions()), ]
    studentlogs$Time <- as.POSIXct(as.character(studentlogs$Time), format="%B %d %Y, %I:%M %p")
    #studentlogs$Time <- studentlogs$Time[!is.na(studentlogs$Time)]
    hist(studentlogs$Time, breaks="weeks", col="green", xlab=NULL, ylab="Number of times activities were accessed", main=NULL, freq=TRUE, las=2, format="%b %d")
  })
  
  ## 'What days of the week did they access?' Plot ##
  output$daysoftheweek <- renderPlot({
    studentlogs <- courselogs()[courselogs()$User.full.name==Student() & (courselogs()$Action %in% Actions()), ]
    studentlogs$Time <- as.POSIXct(as.character(studentlogs$Time), format="%B %d %Y, %I:%M %p")
    #studentlogs$Time <- studentlogs$Time[!is.na(studentlogs$Time)]
    studentlogs$Weekdays <- factor(weekdays(studentlogs$Time), levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"), ordered=TRUE)
    barplot(table(studentlogs$Weekdays), col="green", ylab="Frequency")
  })
  
  ## 'What times of day did they access?' Plot ##
  output$timesofday <- renderPlot({
    studentlogs <- courselogs()[courselogs()$User.full.name==Student() & (courselogs()$Action %in% Actions()), ]
    studentlogs$Time <- as.POSIXct(as.character(studentlogs$Time), format="%B %d %Y, %I:%M %p")
    #studentlogs$Time <- studentlogs$Time[!is.na(studentlogs$Time)]
    studentlogs$Accesstime <- format(studentlogs$Time, format="%H:%M")
    studentlogs$Accesshour <- as.numeric(strsplit(studentlogs$Accesstime, ":[0-5][0-9]"))
    #barplot(table(studentlogs$Accesshour), xlab="24-hour times", main="What time of day did they access?")
    hist(studentlogs$Accesshour, breaks=c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24), col="green", labels=c("12am", "1am", "2am", "3am", "4am", "5am", "6am", "7am", "8am", "9am", "10am", "11am", "12pm", "1pm", "2pm", "3pm", "4pm", "5pm", "6pm", "7pm", "8pm", "9pm", "10pm", "11pm"), xlab=NULL, xaxt="n", ylab="Frequency", main=NULL, freq=TRUE)
  })
    # Fix this to be more elegant!  How to make a better hist with hours data??  Maybe some kind of mod function?
    # Also, are these the right break points for a histogram mapping data with hour values that range from 00 - 23? (%H)
    # Seems like it may be "phase shifted" an hour earlier than expected...
  
})
  