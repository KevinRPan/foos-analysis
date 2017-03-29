##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Server
##
##    This file describes what objects are being rendered.
##    For example, there are formatting options for the tables.
##
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(shiny)
library(DT)

shinyServer(function(input, output) {

  #### Rank table ------------------------------------------------------------

  output$rank_table <- renderDataTable({
    singles_elo %>% CreateRankTable
  })

  #### Player expectancy ------------------------------------------------------

  output$player_expectancy <- renderD3heatmap({
    singles_elo %>% PlotCoWMatrix
  })

  # renderTable(player_odds_df %>% round(3) * 100,
  #             rownames = TRUE,
  #             digits = 1
  # )

  #### Games table ------------------------------------------------------------

  output$games_record <- DT::renderDataTable({
    DT::datatable(singles_games %>%
                    select("Game Number" = game_num,
                           Date = date,
                           "Player 1" = t1_p1,
                           "Player 1 Score" = t1_score,
                           "Player 2" = t2_p1,
                           "Player 2 Score" = t2_score,
                           'Winner' = winner_1)
    )
  })

  #### 2017 Rank plot --------------------------------------------------
  output$rank_plot_2017 <- renderPlotly({
    elo_tracker %>%
      PlotElo(input$includePointsNew, input$includeLinesNew)
  })
  #### 2016 Rank plot --------------------------------------------------
  output$rank_plot_2016 <- renderPlotly({
    "files/elo_tracker_2016.Rds" %>% readRDS %>%
      PlotElo(input$includePoints2016, input$includeLines2016)
  })
  #### Old Rank plot --------------------------------------------------
  output$rank_plot_initial <- renderPlotly({

    elo_rename_f3m <- elo_tracker_f3m %>%
      select(Game_Num = game_num,
             Elo = elo,
             Player = players,
             Score_Difference = score_diff)

    ggp <- elo_rename_f3m %>%
      slice(1:(length(player_list_f3m)*(input$numGamesOld+1))) %>%
      # filter(Player %in% input$playersToShowOld) %>%
      ggplot(aes(x = Game_Num, y = Elo,
                 col = Player)) +
      geom_line(alpha = .8) +
      xlab("Game Number") +
      ylab("Elo") +
      theme_minimal()

    if(input$includePointsOld) {
      ggp <- ggp +
        geom_point(aes(size = Score_Difference),
                   data = elo_rename_f3m %>%
                     # filter(Player %in% input$playersToShowOld %>%
                     filter(Score_Difference > 0),
                   alpha = .2)
    }
    ggp
  })
})
