##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    UI
##
##      This file is the User Interface for the app.
##      This is where the text for each page happens,
##        and where the structure of the app is defined.
##
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(shiny)
library(shinythemes)

link_to_form <-
  "https://docs.google.com/forms/d/e/1FAIpQLScpY5PEZpB6TsuTwAfg5-CZmFDcFpPcw_tdFLhI_v5U-E09hA/viewform"

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
        p("Add your name to the list - track your games with ",
          tags$a(href = link_to_form, "this form"),
          "to make the rankings more accurate!")
      )),
      DT::dataTableOutput("rank_table")
    ),

    #### Expectancies table ----------------------------------------------------
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
      d3heatmapOutput("player_expectancy")
    ),

    #### Current games ---------------------------------------------------------
    tabPanel(
      "Game records",
      fluidRow(column(
        8,
        h4("Game records"),
        p("Try searching for your foos-nemesis to see how they've been doing."),
        p("Note: Doubles games are omitted.")
      )),
      DT::dataTableOutput("games_record")
    ),

    navbarMenu(
      "Rankings graphs",

      ## 2017 rankings graph --------------------------------------------------
      tabPanel(
        "2017 rankings graph",
        fluidRow(column(
          8,
          h4("Tracking player rankings over games"),
          p("The latest and greatest, based on",
            tags$a(href = link_to_form, "your inputs"),"!")
        )),
        plotlyOutput("rank_plot_2017")
      ),
      ## 2016 rankings graph --------------------------------------------------
      tabPanel(
        "2016 rankings graph",
        fluidRow(column(
          8,
          h4("Tracking player rankings over games"),
          p("How'd 2016 go?")
        )),
        sidebarLayout(
          sidebarPanel(
            radioButtons("includePoints", "Include Points?",
                         c("Yes" = TRUE, "No" = FALSE)),
            width = 2
          ),
          mainPanel(
            plotlyOutput("rank_plot_2016")))
        ),
      ## Initial rankings graph --------------------------------------------------
      tabPanel(
        "Initial rankings graph",
        fluidRow(column(
          8,
          h4("Tracking player rankings over games"),
          p("Try pressing the play button!"),
          p(
            "Don't you wanna see your line move? Update ",
            tags$a(href = link_to_form, "that tracker"),
            "for sweet graphing glory!"
          )
          )),
        sidebarLayout(
          sidebarPanel(
            # selectInput(
            #   'playersToShowOld',
            #   'Players to plot',
            #   player_list_f3m,
            #   selected = player_list_f3m,
            #   multiple = TRUE,
            #   selectize = TRUE
            # ),
            sliderInput(
              "numGamesOld",
              "Number of games:",
              min = 1,
              max = nrow(singles_games_f3m),
              value = nrow(singles_games_f3m),
              step = 1,
              animate = animationOptions(interval = 250, loop = FALSE)
            ),
            radioButtons(
              "includePointsOld",
              "Include Points?",
              c("Yes" = TRUE, "No" = FALSE)
            ),
            width = 2
          ),
          mainPanel(plotlyOutput("rank_plot_initial"))
        )
      )),

    tabPanel("About Elo",
             includeMarkdown("files/elo.md"))

  ))
