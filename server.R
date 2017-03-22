

library(shiny)

shinyServer(function(input, output) {

  ############# Rank table #####################################
  output$rank_table <- DT::renderDataTable({
    DT::datatable(singles_elo %>% mutate(elo = round(elo)), options = list(paging = FALSE), fillContainer = FALSE)
  })

  ############# Player expectancy #####################################
  output$player_expectancy <- renderTable(
    player_odds_df %>% round(3) * 100,
    rownames = TRUE,
    digits = 1
  )

  ############# Games table #####################################
  output$games_record <- DT::renderDataTable({
    DT::datatable(singles_games)
  })

  ############# New Rank plot #####################################
  output$rank_plot <- renderPlot({
    players_to_show <- input$playerlist

    ggp <- elo_tracker %>%
      slice(1:(num_players*(input$games+1))) %>%
      filter(players %in% players_to_show) %>%
      ggplot() +
      geom_line(aes(x = game_num, y = elo, col = players, group = players)) +
      xlab("Game Number") +
      ylab("Elo") +
      theme_minimal()

    if(input$includePoints) {
      ggp <- ggp +
        geom_point(aes(x = game_num, y = elo, col = players,
                       group = players, size = score_diff), alpha = .2)
    }
    ggp
  })
  ############# Old Rank plot #####################################
  output$old_rank_plot <- renderPlot({

    ### Get previous data
    old_elo_tracker <- readRDS("../elo_tracker_first_3_months.Rds")
    old_player_list <- old_elo_tracker %>%
      select(players) %>%
      distinct %>%
      arrange(players) %>%
      .[[1]]

    ### Plot it
    ggp <- old_elo_tracker %>%
      slice(1:(length(old_player_list)*(input$numGamesOld+1))) %>%
      filter(players %in% input$playersToShowOld) %>%
      ggplot() +
      geom_line(aes(x = game_num, y = elo, col = players, group = players)) +
      xlab("Game Number") +
      ylab("Elo") +
      theme_minimal()

    if(input$includePointsOld) {
      ggp <- ggp +
        geom_point(aes(x = game_num, y = elo, col = players,
                       group = players, size = score_diff), alpha = .2)
    }
    ggp
  })

})
