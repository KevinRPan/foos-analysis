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

  output$rank_table <- DT::renderDataTable({
    elo_results[[input$rankingsOffice]][[input$rankingsGameType]] %>%
      CreateRankTable
  })

  #### Player expectancy ------------------------------------------------------

  ## Wrapper for heatmap
  output$ui_player_expectancy <- renderUI({
    d3heatmapOutput('player_expectancy')
  })
  output$player_expectancy <- renderD3heatmap({
    elo_results[[input$matchupsOffice]][[input$matchupsGameType]] %>%
      PlotCoWMatrix
  })

  output$player_expectancy_ggp <- renderPlotly({
    elo_results[[input$matchupsOffice]][[input$matchupsGameType]] %>%
      PlotCoWMatrix(use_d3 = FALSE)
  })

  # renderTable(player_odds_df %>% round(3) * 100,
  #             rownames = TRUE,
  #             digits = 1
  # )

  #### Games table ------------------------------------------------------------

  output$games_record <- DT::renderDataTable({
    CreateGamesTable(foos, input$recordsGameType)
  })



  #### Scores table ------------------------------------------------------------

  output$scores_record <- DT::renderDataTable({
    singles_games %>%
      filter(office %in% input$scoresOffice) %>%
      ExamineScores
  })



  #### Games Network --------------------------------------------------

  output$force <- renderForceNetwork({
    PlotGamesNetwork(
      singles_elo = rbind(
        elo_results[['SF']][['singles_elo']],
        elo_results[['DC']][['singles_elo']]),
      singles_games = singles_games)
  })

  #### Matchups  ------------------------------------------------------------

  output$matchup_table <- DT::renderDataTable({
    ExamineMatchup(singles_games, input$matchupPlayer) %>%
      DT::datatable() %>%
      formatRound(columns = c("Avg pts scored","Avg pts given", "Point Diff"))
  })


  #### 2017 Rank plot --------------------------------------------------
  output$rank_plot_2017 <- renderPlotly({
    elo_results[[input$graphsOffice]][[input$graphsElo]] %>%
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
