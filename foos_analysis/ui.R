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

    #### Rankings table ----------------------------------------------------
    ## TODO :: separate by league
    tabPanel(
      "Current rankings",
      fluidRow(column(
        10,
        h4("Latest Office Foosball Rankings"),
        p("So how do you rank up? (Note: minimum of 6 games to get a ranking.)"),
        p("Add your name to the list - track your games with ",
          tags$a(href = link_to_form, "this form"),
          "to make the rankings more accurate!")
      )),
      fixedRow(column(4,
                      radioButtons(
                        "rankingsOffice",
                        "Office:",
                        c('DC', 'SF'),
                        selected = 'SF'
                      )),
               column(4,
                      radioButtons(
                        "rankingsGameType",
                        "Game Type:",
                        c('Singles' = 'singles_elo', 'Doubles'='dubs_elo'),
                        selected = 'singles_elo'
                      ))),
      DT::dataTableOutput("rank_table")
    ),

    #### Expectancies table ----------------------------------------------------
    tabPanel(
      "Scores",
      fluidRow(column(
        8,
        h4("PvP scores"),
        p(
          "How close are your games?"
        ),
        fixedRow(column(4,
                        checkboxGroupInput(
                          "scoresOffice",
                          "Office:",
                          c('DC', 'SF'),
                          selected = 'SF'
                        )),
                 column(4,
                        selectInput(
                          "scoresGameType",
                          "Game Type:",
                          c('Singles' = 'singles_elo',
                            'Sorry, only singles for now'='dubs_elo'),
                          selected = 'singles_elo'
                        ))),
        # p("Read across: Row Player's chance of beating Column Player")
        p("Goals made versus given, with a simple ratio and averaged by game!")
      )),
      DT::dataTableOutput('scores_record'),

      h5("Who are your closest singles competitors?"),
      selectInput(
        'matchupPlayer',
        'Player',
        player_list_all %>% sort
      ),
      DT::dataTableOutput("matchup_table")
    ),
    #### Expectancies table ----------------------------------------------------
    tabPanel(
      "Matchups",
      fluidRow(column(
        8,
        h4("Expected chance of player match-ups"),
        p(
          "These player odds are calculated by the",
          tags$a(href = "http://www.eloratings.net/system.html", "difference in ratings"),
          " method."
        ),
        fixedRow(column(4,
                        radioButtons(
                          "matchupsOffice",
                          "Office:",
                          c('DC', 'SF'),
                          selected = 'SF'
                        )),
                 column(4,
                        radioButtons(
                          "matchupsGameType",
                          "Game Type:",
                          c('Singles' = 'singles_elo', 'Doubles'='dubs_elo'),
                          selected = 'singles_elo'
                        ))),
        # p("Read across: Row Player's chance of beating Column Player")
        p("The more blue your column, the better!")
      )),
      # uiOutput("ui_player_expectancy")
      plotlyOutput('player_expectancy_ggp'),
      p("Tip: try clicking and dragging across your column to see your matchups.")
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
        fixedRow(column(4,
                        radioButtons(
                          "graphsOffice",
                          "Office:",
                          c('DC', 'SF'),
                          selected = 'SF'
                        )),
                 column(4,
                        radioButtons(
                          "graphsElo",
                          "Game Type:",
                          c('Singles' = 'elo_tracker', 'Doubles'='dubs_elo_tracker'),
                          selected = 'elo_tracker'
                        ))),

        plotlyOutput("rank_plot_2017"),

        fixedRow(column(4,
                        radioButtons(
                          "includePointsNew",
                          "Include Points?",
                          c("Yes" = TRUE, "No" = FALSE)
                        )),
                 column(4,
                        radioButtons(
                          "includeLinesNew", "Include Lines?",
                          c("Yes" = TRUE, "No" = FALSE)
                        )))

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
            radioButtons("includePoints2016", "Include Points?",
                         c("Yes" = TRUE, "No" = FALSE)),
            radioButtons("includeLines2016", "Include Lines?",
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
        # sidebarLayout(
          # sidebarPanel(
            # selectInput(
            #   'playersToShowOld',
            #   'Players to plot',
            #   player_list_f3m,
            #   selected = player_list_f3m,
            #   multiple = TRUE,
            #   selectize = TRUE
            # ),

        fixedRow(column(
          6,
          sliderInput(
            "numGamesOld",
            "Number of games:",
            min = 1,
            max = nrow(singles_games_f3m),
            value = nrow(singles_games_f3m),
            step = 1,
            animate = animationOptions(interval = 250, loop = FALSE)
          )
        ),
        column(4,
               radioButtons(
                 "includePointsOld",
                 "Include Points?",
                 c("Yes" = TRUE, "No" = FALSE)
               ))
        ),
        # width = 2),
        # mainPanel(
        plotlyOutput("rank_plot_initial")
        )
    ),

    #### Games Network  ---------------------------------------------------------
    tabPanel(
      "Games network",
      fluidRow(column(
        8,
        h4("Games network"),
        p("Who's played who?")
      )),
      forceNetworkOutput("force"),
      fluidRow(column(
        8,
        p("Color is arbitrary for win-streaks groups."),
        p("Larger dots and thicker links = more games.")
      ))
    ),

    #### Current games records ------------------------------------------------
    tabPanel(
      "Game records",
      fluidRow(column(
        8,
        h4("Game records"),
        p("Try searching for your foos-nemesis to see how they've been doing.")#,
        # p("Note: Doubles games are omitted.")
      )),
      radioButtons(
        "recordsGameType",
        "Game Type:",
        c('Singles', 'Doubles'),
        selected = 'Singles'
      ),
      DT::dataTableOutput("games_record")
    ),

    #### About page  ---------------------------------------------------------
    tabPanel("About Elo",
             includeMarkdown("files/elo.md")) #,
    # tabPanel(
    #   "Comments",


  ))
