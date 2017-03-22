
library(shiny)
library(pacman)
p_load(shinythemes)

shinyUI(
  navbarPage(
    title = "Foosball performance analysis",
    theme = shinytheme("flatly"),
    tabPanel(
      "Current rankings",
      fluidRow(column(
        8,
        h4("Latest SF Office foosball rankings"),
        p("So how do you rank up?"),
        p(
          "Add your name to the list - track your games in ",
          tags$a(href = "https://docs.google.com/spreadsheets/d/1Zjyp6lVjJ1ADfRsK4u8OV9W9kSD7IrDHkwcy_E1iZ5I/edit?usp=sharing", "this google sheet"),
          "to make the rankings more accurate!"
        )
      )),
      DT::dataTableOutput("rank_table")
    ),
    ########## Expectancies table ############################################
    tabPanel(
      "Player expectancies",
      fluidRow(column(
        8,
        h4("Expected chance of player match-ups"),
        p(
          "These player odds are calculated by the",
          tags$a(href = "http://www.eloratings.net/system.html", "difference in ratings"),
          " method."
        ),
        p("Read across: Row Player's chance of beating Column Player")
      )),
      tableOutput("player_expectancy")
    ),


    ################ Current games #####################################
    tabPanel(
      "Game records",
      fluidRow(column(
        8,
        h4("Game records"),
        p(
          "You can see them here or you can see them ",
          tags$a(href = "https://docs.google.com/spreadsheets/d/1Zjyp6lVjJ1ADfRsK4u8OV9W9kSD7IrDHkwcy_E1iZ5I/edit?usp=sharing", "here"),
          "."
        )
      )),
      DT::dataTableOutput("games_record")
    ),

    navbarMenu("Rankings graphs",

     #################### New rankings graph #################################
     tabPanel(
       "New rankings graph",
       fluidRow(column(
         8,
         h4("Tracking player rankings over games"),
         p(
           "The latest and greatest, based on",
           tags$a(href = "https://docs.google.com/spreadsheets/d/1Zjyp6lVjJ1ADfRsK4u8OV9W9kSD7IrDHkwcy_E1iZ5I/edit?usp=sharing", "your inputs"),
           "!"
         )
       )),
       sidebarLayout(
         sidebarPanel(
           # verbatimTextOutput('selected_players'),
           selectInput(
             'playerlist',
             'Players to plot',
             player_list,
             selected = player_list,
             multiple = TRUE,
             selectize = TRUE
           ),
           sliderInput(
             "games",
             "Number of games:",
             min = 1,
             max = 30,
             value = 10
           ),
           radioButtons("includePoints", "Include Points?",
                        c("Yes" = TRUE, "No" = FALSE))
         ),
         mainPanel(plotOutput("rank_plot"))
       )
     ),
      ########## Old rankings graph #############################################
      tabPanel(
        "Old rankings graph",
        fluidRow(column(
          8,
          h4("Tracking player rankings over games"),
          p(
            "Don't you wanna see your line move? Update ",
            tags$a(href = "https://docs.google.com/spreadsheets/d/1Zjyp6lVjJ1ADfRsK4u8OV9W9kSD7IrDHkwcy_E1iZ5I/edit?usp=sharing", "that tracker"),
            "
            for sweet graphing glory!"
          )
          )),
        sidebarLayout(
          sidebarPanel(
            # verbatimTextOutput('old_selected_players'),
            selectInput(
              'playersToShowOld',
              'Players to plot',
              old_player_list,
              selected = old_player_list,
              multiple = TRUE,
              selectize = TRUE
            ),
            sliderInput(
              "numGamesOld",
              "Number of games:",
              min = 1,
              max = 60,
              value = 30
            ),
            radioButtons(
              "includePointsOld",
              "Include Points?",
              c("Yes" = TRUE, "No" = FALSE)
            )
          ),
          mainPanel(plotOutput("old_rank_plot"))
        )
        )
     ),


    tabPanel("About Elo",
             includeMarkdown("elo.md"))

)
)
