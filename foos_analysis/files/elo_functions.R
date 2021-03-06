##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Set constants and define functions
##      Note: run from foos_elo.R for libraries
##
##      This file defines functions used in the calculation of elo,
##        as well as the plots that show up in the app.
##
##        TODO:: Provisional rankings
##
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Libraries  ============================================================
library(tidyverse)
library(magrittr)
library(stringr)
library(knitr)
library(googlesheets)
library(ggplot2)
library(ggthemes)
library(plotly)
library(d3heatmap)
library(networkD3)
library(viridis)
library(DT)

#### Constants ============================================================

elo_diff <- 400
min_games <- 5
base_elo <- 1200
reduce_k <- 200 # when over base elo to reduce k1 to k2

## Almighty k
k1 <- 32
k2 <- 32

# Elo standards
# Players below 2100: K-factor of 32 used
# Players between 2100 and 2400: K-factor of 24 used
# Players above 2400: K-factor of 16 used.
# Here, going up 200 is significant
#   so we reduce k to 24 when above 1400

#### Elo calculation functions =============================================

make_names <-
  # Function to clean up column names
  . %>%
  str_trim %>%
  make.names %>%
  str_replace_all("[.]", "_") %>%
  tolower %>%
  str_replace_all("__{1,4}", "_") %>%
  str_replace_all("_$", "")


FormatName <- function(name, use_full_name = FALSE){
  ## use_full_name can be TRUE, FALSE, or "none"

  if(use_full_name == TRUE) {
      name %<>% str_to_title
  } else if(use_full_name == FALSE) {
    name %<>% str_extract("\\w+") %>% str_to_title
  }
  return(name)
}

CalculateChance <- function(p1_elo, p2_elo){
  Q1 <- 10^(p1_elo/elo_diff)
  Q2 <- 10^(p2_elo/elo_diff)
  expected_p1 <- Q1/(Q1+Q2)
  return(expected_p1)
}

RunCalculationLoop <- function(singles_games, weighted_entry = FALSE, use_full_name = FALSE) {
  ## Requires variables (
  ## Create elo table ========================================================

  singles_elo <- singles_games %>%
    select(t1, t2) %>%
    stack %>%
    select(players = values) %>%
    mutate(players = players %<>% FormatName(use_full_name)) %>%
    distinct %>%
    arrange(players) %>%
    mutate(elo = base_elo +
             ifelse(weighted_entry,
                    ifelse(players %in% first_years, -250,
                    ifelse(players %in% third_years, 200, 50)),
                    0),
           wins            = 0,
           losses          = 0,
           number_of_games = 0,
           streak          = 0,
           max_streak      = 0)

  player_list <- singles_elo %>% .[[1]]

  elo_tracker <- singles_elo %>% mutate(game_num = 0, score_diff = 0)

  ## Run elo calculation loop =================================================

  for(game_num in seq_len(nrow(singles_games))) {
    p1 <- singles_games[game_num, "t1"] %>% as.character
    p2 <- singles_games[game_num, "t2"] %>% as.character

    score1 <- singles_games[game_num, "t1_score"] %>% as.numeric
    score2 <- singles_games[game_num, "t2_score"] %>% as.numeric

    singles_elo %<>%
      GameUpdate(p1,
                 score1,
                 p2,
                 score2,
                 print_progress = FALSE)
    elo_tracker %<>%
      rbind(
        singles_elo %>%
          mutate(
            game_num = game_num,
            score_diff = ifelse(
              players %in% c(p1, p2),
              abs(score1 - score2),
              0)
          )
      )
  }

  singles_elo %<>% arrange(desc(elo))
  return(list("singles_elo" = singles_elo, "elo_tracker" = elo_tracker))
}

DoublesCalculationLoop <- function(doubles_games,
                                   weighted_entry = FALSE,
                                   use_full_name = FALSE) {
  ## Create elo table ========================================================
  dubs_elo <- doubles_games %>%
    select(t1_p1, t1_p2, t2_p1, t2_p2) %>%
    stack %>%
    select(players = values) %>%
    mutate(players = players %<>% FormatName(use_full_name = FALSE)) %>%
    distinct %>%
    arrange(players) %>%
    mutate(elo = base_elo +
             ifelse(weighted_entry,
                    ifelse(players %in% first_years, -250,
                           ifelse(players %in% third_years, 200, 50)),
                    0),
           wins            = 0,
           losses          = 0,
           number_of_games = 0,
           streak          = 0,
           max_streak      = 0)

  dubs_player_list <- dubs_elo %>% .[[1]]

  dubs_elo_tracker <- dubs_elo %>% mutate(game_num = 0, score_diff = 0)

  ## Run elo calculation loop =================================================

  for(game_num in seq_len(nrow(doubles_games))) {
    t1_p1 <- doubles_games[game_num, "t1_p1"] %>% as.character
    t1_p2 <- doubles_games[game_num, "t1_p2"] %>% as.character
    t2_p1 <- doubles_games[game_num, "t2_p1"] %>% as.character
    t2_p2 <- doubles_games[game_num, "t2_p2"] %>% as.character

    score1 <- doubles_games[game_num, "t1_score"] %>% as.numeric
    score2 <- doubles_games[game_num, "t2_score"] %>% as.numeric

    dubs_elo %<>%
      DoublesGameUpdate(t1_p1,
                        t1_p2,
                        score1,
                        t2_p1,
                        t2_p2,
                        score2,
                        print_progress = FALSE)
    dubs_elo_tracker %<>%
      rbind(
        dubs_elo %>%
          mutate(
            game_num = game_num,
            score_diff = ifelse(
              players %in% c(t1_p1, t1_p2, t2_p1, t2_p2),
              abs(score1 - score2),
              0)
          )
      )
  }

  dubs_elo %<>% arrange(desc(elo))
  return(list("dubs_elo" = dubs_elo, "dubs_elo_tracker" = dubs_elo_tracker))
}

ExamineScores <- function(singles_games) {
  ## Get score stats per player
  scores <- map_df(player_list_all %>% set_names(player_list_all),
         function(p1) {
           hth_games <- singles_games %>%
             filter(t1 == p1 | t2 == p1)

           if (nrow(hth_games) > min_games) {
             player_games <-
               bind_rows(
                 hth_games %>% dplyr::select(player = t1, score = t1_score),
                 hth_games %>% dplyr::select(player = t2, score = t2_score)
               )

             player_games %>%
               mutate(player_goals = ifelse(player == p1, "Scored", "Given")) %>%
               group_by(player_goals) %>%
               summarise(total_scored = sum(score)) %>%
               spread(player_goals, total_scored) %>%
               mutate(Player = p1) %>%
               mutate(
                 avg_score_diff = (Scored - Given) / (nrow(player_games) / 2),
                 score_ratio = Scored / Given
               )
           }
         }) %>%
    arrange(desc(avg_score_diff))

  scores %>%
    select(
      Player,
      Scored,
      Given,
      "Avg Score Diff" = avg_score_diff,
      "Score Ratio" = score_ratio
    ) %>%
    datatable(
      fillContainer = FALSE,
      extensions = c("ColReorder", "Buttons"),
      options = list(
        dom = "Bfrtip",
        buttons = I("colvis"),
        colReorder = TRUE
    )
  ) %>%
    formatStyle(c("Player", "Avg Score Diff"), fontWeight = "Bold") %>%
    formatStyle(
      c("Avg Score Diff"),
      background = styleColorBar(range(scores$avg_score_diff),
                                 "steelblue"),
      backgroundSize = "75% 80%",
      backgroundRepeat = "no-repeat",
      backgroundPosition = "right"
    ) %>%
    formatStyle(
      c("Score Ratio"),
      background = styleColorBar(range(scores$score_ratio),
                                 "steelblue"),
      backgroundSize = "75% 80%",
      backgroundRepeat = "no-repeat",
      backgroundPosition = "right"
    ) %>%
    formatRound(columns = c("Avg Score Diff","Score Ratio")) %>%
    return
}

ExamineMatchup <- function(singles_games, p1, p2 = NULL) {
  ## Input games and players to compare
  ## Quick stats on matchup wins and scores

  if (is.null(p2) || p1 == p2) {
    ## No player specified, or player was specified against him/herself
    player_list_all <- singles_games %>%
      select(t1, t2) %>%
      stack %>%
      distinct(values) %>%
      .[[1]]

    player_matchups <-
      map_df(player_list_all %>% set_names(player_list_all),
             function(p2) {
               if (p1 != p2) {
                 matchup <- ExamineMatchup(singles_games, p1, p2)
                 return(matchup)
               }
             }
      ) %>% arrange(`Point Diff`)
    return(player_matchups)
  } else {
    ## Actual function
    hth_games <- singles_games %>%
      filter(t1 == p1 | t2 == p1) %>%
      filter(t1 == p2 | t2 == p2)

    matchup <- tibble()
    if(nrow(hth_games) > 0) {

      compare <- full_join(
        hth_games %>%
          group_by(player = winner_1) %>%
          summarise(wins = n()),
        bind_rows(hth_games %>% dplyr::select(player = t1, score = t1_score),
                  hth_games %>% dplyr::select(player = t2, score = t2_score)) %>%
          group_by(player) %>%
          summarise(avg_score = mean(score)),
        by = "player"
      ) %>%
        mutate(wins = ifelse(is.na(wins), 0, wins))

      matchup <-
        tibble(
          "Player" = p1,
          "Matchup" = p2,
          "Wins against" = compare %>%
            filter(player == p1) %>%
            select(wins) %>%
            .[[1]],
          "Losses against" = compare %>%
            filter(player == p2) %>%
            select(wins) %>%
            .[[1]],
          "Avg pts scored" = compare %>%
            filter(player == p1) %>%
            select(avg_score) %>%
            .[[1]],
          "Avg pts given" = compare %>%
            filter(player == p2) %>%
            select(avg_score) %>%
            .[[1]],
          "Point Diff" =
            compare %>%
            filter(player == p1) %>%
            select(avg_score) %>%
            .[[1]] -
            compare %>%
            filter(player == p2) %>%
            select(avg_score) %>%
            .[[1]]
        )
    }
  }
  return(matchup)
}


GameUpdate <- function(df, player1, score1, player2, score2,
                       print_progress = FALSE) {

  # player1 %<>% FormatName
  # player2 %<>% FormatName
  score1  %<>% as.numeric
  score2  %<>% as.numeric

  elo1 <- df[grepl(player1, df$players), "elo"] %>% as.numeric
  elo2 <- df[grepl(player2, df$players), "elo"] %>% as.numeric

  expected1 <- CalculateChance(elo1, elo2)
  expected2 <- 1 - expected1

  point_diff <- score1 - score2

  margin_of_victory <- log(abs(point_diff))*(2.2/((
    ifelse(score1 > score2, elo1-elo2, elo2-elo1))*.001+2.2))

  k_adj1 <- ifelse(elo1 > base_elo + reduce_k, k1, k2) * margin_of_victory
  k_adj2 <- ifelse(elo2 > base_elo + reduce_k, k1, k2) * margin_of_victory

  p1_res <- ifelse(score1 > score2, 1, 0)
  p2_res <- ifelse(score1 > score2, 0, 1)

  updated_elo1 <- elo1 + k_adj1*(p1_res - expected1)
  updated_elo2 <- elo2 + k_adj2*(p2_res - expected2)

  ## optional progress printing
  if(print_progress){
    cat(player1, "P1:", elo1, "->", updated_elo1, "\t|",
        player2, "P2:", elo2, "->", updated_elo2, "\n")
  }

  ## update elo
  df[grepl(player1, df$players), "elo"] <- updated_elo1
  df[grepl(player2, df$players), "elo"] <- updated_elo2

  ## increment games
  df[grepl(player1, df$players), "number_of_games"] <-
    df[grepl(player1, df$players), "number_of_games"] + 1
  df[grepl(player2, df$players), "number_of_games"] <-
    df[grepl(player2, df$players), "number_of_games"] + 1

  winner <- ifelse(score1 > score2, player1, player2)
  loser <- ifelse(score1 > score2, player2, player1)

  ## increment wins
  df[grepl(winner, df$players), "wins"] <-
    df[grepl(winner, df$players), "wins"] + 1
  df[grepl(loser, df$players), "losses"] <-
    df[grepl(loser, df$players), "losses"] + 1

  ## increment hot streak
  df[grepl(winner, df$players), "streak"] <-
    df[grepl(winner, df$players), "streak"] + 1
  df[grepl(loser, df$players), "streak"] <- 0


  df[grepl(winner, df$players), "max_streak"] <-
    max(df[grepl(winner, df$players), "streak"],
        df[grepl(winner, df$players), "max_streak"])

  return(df)
}

DoublesGameUpdate <- function(df, t1_p1, t1_p2, score1, t2_p1, t2_p2, score2,
                              print_progress = FALSE) {

  t1_p1 %<>% FormatName(use_full_name = FALSE)
  t1_p2 %<>% FormatName(use_full_name = FALSE)
  t2_p1 %<>% FormatName(use_full_name = FALSE)
  t2_p2 %<>% FormatName(use_full_name = FALSE)

  t1 <- c(t1_p1, t1_p2)
  t2 <- c(t2_p1, t2_p2)
  players <- c(t1, t2)
  score1  %<>% as.numeric
  score2  %<>% as.numeric

  elo_t1p1 <- df[grepl(t1_p1, df$players), "elo"] %>% as.numeric
  elo_t1p2 <- df[grepl(t1_p2, df$players), "elo"] %>% as.numeric
  elo_t2p1 <- df[grepl(t2_p1, df$players), "elo"] %>% as.numeric
  elo_t2p2 <- df[grepl(t2_p2, df$players), "elo"] %>% as.numeric

  elo1 <- mean(c(elo_t1p1, elo_t1p2))
  elo2 <- mean(c(elo_t2p1, elo_t2p2))

  expected1 <- CalculateChance(elo1, elo2)
  expected2 <- 1 - expected1

  point_diff <- score1 - score2

  margin_of_victory <- log(abs(point_diff))*(2.2/((
    ifelse(score1 > score2, elo1-elo2, elo2-elo1))*.001+2.2))

  k_adj1 <- ifelse(elo1 > base_elo + reduce_k, k1, k2) * margin_of_victory
  k_adj2 <- ifelse(elo2 > base_elo + reduce_k, k1, k2) * margin_of_victory

  t1_res <- ifelse(score1 > score2, 1, 0)
  t2_res <- ifelse(score1 > score2, 0, 1)

  delta_elo1 <- k_adj1*(t1_res - expected1)
  delta_elo2 <- k_adj2*(t2_res - expected2)

  updated_elo_t1p1 <- elo_t1p1 + delta_elo1
  updated_elo_t1p2 <- elo_t1p2 + delta_elo1
  updated_elo_t2p1 <- elo_t2p1 + delta_elo2
  updated_elo_t2p2 <- elo_t2p2 + delta_elo2

  ## optional progress printing
  if(print_progress){
    cat(
      t1_p1, "T1P1:", elo_t1p1, "->", updated_elo_t1p1, "\t|",
      t1_p2, "T1P2:", elo_t1p2, "->", updated_elo_t1p2, "\t|",
      t2_p1, "T2P1:", elo_t2p1, "->", updated_elo_t2p1, "\t|",
      t2_p2, "T2P2:", elo_t2p2, "->", updated_elo_t2p2, "\n")
  }

  ## update elo
  df[grepl(t1_p1, df$players), "elo"] <- updated_elo_t1p1
  df[grepl(t1_p2, df$players), "elo"] <- updated_elo_t1p2
  df[grepl(t2_p1, df$players), "elo"] <- updated_elo_t2p1
  df[grepl(t2_p2, df$players), "elo"] <- updated_elo_t2p2

  ## increment games
  incrementX <- function(player, field) {
    df[grepl(player, df$players), field] <-
      df[grepl(player, df$players), field] + 1
    return(df)
  }

  setStreakLoss <- function(loser){
    df[grepl(loser, df$players), "streak"] <- 0
    return(df)
  }

  setStreakMax <- function(winner){
    df[grepl(winner, df$players), "max_streak"] <<-
      max(df[grepl(winner, df$players), "streak"],
          df[grepl(winner, df$players), "max_streak"])
    return(df)
  }

  winners <- if(score1 > score2) t1 else t2
  losers  <- if(score1 > score2) t2 else t1

  for(p in players) {
    df <- incrementX(p, "number_of_games")
  }

  for(p in winners) {
    df <- incrementX(p, "wins")
    df <- incrementX(p, "streak")
    df <- setStreakMax(p)
  }

  for(p in losers) {
    df <- incrementX(p, "losses")
    df <- setStreakLoss(p)
  }

  return(df)
}


#### Plotting functions ====================================================

PlotElo <- function(elo_tracker, plot_points = TRUE, plot_lines = TRUE,
                    use_plotly = FALSE) {
  ## Create a plot of elo over the number of games
  ## Optionally add points to graph
  ##  that denote the difference in score for a game.

  player_game_min <- elo_tracker %>%
    group_by(players) %>%
    summarise(number_of_games = max(number_of_games)) %>%
    filter(number_of_games > min_games) %>%
    select(players) %>%
    .[[1]]


  elo_rename <- elo_tracker %>%
    select(Game_Num = game_num,
           Elo = elo,
           Player = players,
           Score_Difference = score_diff) %>%
    filter(Player %in% player_game_min)

  if(use_plotly) {
    pal <- viridis(length(player_game_min))
    plt <- elo_rename %>%
      plot_ly(x = ~Game_Num,
              y = ~Elo,
              type = "scatter",
              mode = "lines",
              text = ~paste("Player:", Player,
                            "<br>Elo:", Elo %>% round),
              color = ~Player,
              colors = pal) %>%
      add_trace(y = ~Elo,
                mode = "markers",
                text = ~paste("Player:", Player,
                              "<br>Elo:", Elo %>% round,
                              "<br>Score Difference:", Score_Difference),
                size = ~Score_Difference,
                color = ~Player,
                colors = pal,
                data = elo_rename %>%
                  filter(Score_Difference > 0),
                alpha = .4)



  } else {
    ggp <- elo_rename %>%
      ggplot(aes(x = Game_Num, y = Elo,
                 col = Player))+ #,group = Player)) +
      xlab("Game Number") +
      ylab("Elo") +
      theme_minimal() +
      scale_color_viridis(discrete = TRUE)
      # scale_color_fivethirtyeight() +
      # theme_fivethirtyeight()

    if(plot_points) {
      ggp <- ggp +
        geom_point(aes(size = Score_Difference),
                 data = elo_rename %>%
                   filter(Score_Difference > 0),
                 alpha = .2)
    }

    if(plot_lines) {
      ggp <- ggp + geom_line(alpha = .8)
    }
    plt <- ggplotly(ggp, tooltip = c("Elo", "Player", "Score_Difference"))
  }

  return(plt)
}

CreateGamesTable <- function(games, game_type = "Singles") {
  ## Input is all games, and game type

  if(game_type == "Singles") {
    singles_games <- games %>%
      filter(type == "Singles") %>%
      select(game_num,
             date,
             t1 = t1_p1,
             t1_score,
             t2 = t2_p1,
             t2_score,
             winner_1,
             comments) %>%
      mutate_at(vars(t1, t2, winner_1),
                funs(str_extract(., "\\w+") %>% str_to_title))

    DT::datatable(singles_games %>%
                    arrange(desc(game_num)) %>%
                    select("Game Number" = game_num,
                           Date = date,
                           "Player 1" = t1,
                           "Player 1 Score" = t1_score,
                           "Player 2" = t2,
                           "Player 2 Score" = t2_score,
                           "Winner" = winner_1,
                           "Comment" = comments)
    ) %>%
      formatStyle(c("Winner"), fontWeight = "Bold")
  } else {
    dubs_games <- games %>%
      filter(type == game_type) %>%
      arrange(desc(game_num)) %>%
      select("Game Number" = game_num,
             Date = date,
             "Team B P1" = t1_p1,
             "Team B P2" = t1_p2,
             "Team B Score" = t1_score,
             "Team Y P1" = t2_p1,
             "Team Y P2" = t2_p2,
             "Team Y Score" = t2_score,
             "Winner P1" = winner_1,
             "Winner P2" = winner_2,
             "Comment" = comments) %>%
      datatable %>%
      formatStyle(c("Winner P1", "Winner P2"), fontWeight = "Bold")


  }


}

PlotGamesNetwork <- function(singles_elo, singles_games) {
  ## Convert elo and games to a network visualization

  # Double the links both ways to cover people who may only show up on one side

  game_links <- singles_games %>%
    select(t1, t2) %>%
    bind_rows(singles_games %>%
                select(t2 = t1, t1 = t2)) %>%
    mutate(
      p1 = (as.factor(t1) %>% as.integer) - 1,
      p2 = (as.factor(t2) %>% as.integer) - 1
    ) %>%
    group_by(p1, p2) %>%
    summarise(num_games=n()) %>%
    arrange(p1, p2)

  games_network <- forceNetwork(
    Links = game_links,
    Nodes = singles_elo %>%
      distinct(players, .keep_all = TRUE) %>%
      arrange(players),
    Source = "p1",
    Target = "p2",
    NodeID = "players",
    Nodesize = "number_of_games",
    Group = "max_streak",
    Value = "num_games",
    charge = -50,
    linkDistance = 75,
    # zoom = TRUE,
    colourScale = JS("d3.scaleOrdinal(d3.schemeCategory20c);"),
                     ##viridis(max(singles_elo$max_streak)),
    fontSize = 12,
    opacityNoHover = .75,
    opacity = .9
  )

  return(games_network)
}

PlotCoWMatrix <- function(singles_elo, use_d3 = TRUE) {
  # Calculate player chance of winning matrix
  # Return a plot of chance of winning

  # readRDS("singles_elo_2016.Rds")
  singles_elo_alphabetical <- singles_elo %>%
    filter(number_of_games > min_games) %>%
    arrange(players)

  num_players <- nrow(singles_elo_alphabetical)
  player_odds <- matrix(vector(), nrow = num_players, ncol = num_players)
  player_list <- singles_elo_alphabetical %>% .[[1]]

  ## Calculate the matrix of odds -----------------------------------------------

  for (i in seq_len(num_players)) {
    for (j in seq_len(num_players)) {
      if (j != i) {
        elo1 <- singles_elo_alphabetical[i, "elo"]
        elo2 <- singles_elo_alphabetical[j, "elo"]

        player_odds[i, j] <- CalculateChance(elo1, elo2)
        player_odds[j, i] <- CalculateChance(elo2, elo1)
      }
    }
  }

  ## Relabel matrix
  player_odds_df <- as.data.frame(player_odds)
  row.names(player_odds_df) <- player_list
  colnames(player_odds_df) <- player_list
  rownames(player_odds) <- player_list
  colnames(player_odds) <- player_list


  if(use_d3) {
    return(d3heatmap(player_odds_df, Rowv = NULL, Colv = "Rowv"))
  } else {
    player_odds_ggp <- player_odds %>%
      reshape2::melt() %>%
      mutate(P1_CoW = 1-value) %>%
      select(P1 = Var2, P2 = Var1, P1_CoW) %>%
      ggplot(aes(x=P1, y = P2, fill = P1_CoW)) +
      geom_raster() +
      # coord_flip() +
      scale_fill_gradient2(low = "firebrick", high = "steelblue", mid = "white",
                           midpoint = .5, limit = c(0,1), space = "Lab",
                           name="Chance of winning") +
      theme_minimal() +
      theme(axis.text.y = element_text(hjust = 1.5),
            #axis.text.x = element_text(angle = 45),
            # vjust = 1.5,
            # hjust = 1),
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            panel.grid.major = element_blank(),
            panel.border = element_blank(),
            panel.background = element_blank(),
            axis.ticks = element_blank()) +
      scale_x_discrete(position = "top") +
      scale_y_discrete(position = "right") #,
            # legend.position = "bottom",
            # legend.direction = "horizontal") #+
      # guides(fill = guide_colorbar(barwidth = 10, barheight = .5,
                                   # title.position = "bottom", title.hjust = 0.5))
      # geom_text(aes(Var2, Var1),
                    # label = ifelse(!is.na(value),paste0(round(value,2)*100,"%"),NA)),
                # color = "black", size = 4)
    return(player_odds_ggp)
  }
}

CreateRankTable <- function(singles_elo, use_paging = FALSE) {
  ## Format a table to show:
  ##  Elo, Streaks, Wins, Losses, Total Games
  ##  Add bars for streaks and games
  ##  Add buttons and flexibility for columns
  rank_table <- datatable(
    singles_elo %>%
      filter(number_of_games > min_games) %>%
      mutate(elo = round(elo)) %>%
      mutate(win_pct = wins/(wins+losses)) %>%
      select(
        Players = players,
        Elo = elo,
        "Current win streak" = streak,
        "Max win streak" = max_streak,
        Wins = wins,
        Losses = losses,
        "Win Percent" = win_pct
        # "Number of Games" = number_of_games
      ),

    fillContainer = FALSE,
    extensions = c("ColReorder", "Buttons"),
    options = list(
      paging = use_paging,
      dom = "Bfrtip",
      buttons = I("colvis"),
      colReorder = TRUE
    )
  ) %>%
    formatStyle(c("Players", "Elo"), fontWeight = "Bold") %>%
    formatStyle(
      c("Current win streak",
        "Max win streak"),
      background = styleColorBar(range(singles_elo$max_streak),
                                 "firebrick"),
      backgroundSize = "75% 80%",
      backgroundRepeat = "no-repeat",
      backgroundPosition = "right"
    ) %>%
    formatStyle(
      c("Wins",
        "Losses"),
      background = styleColorBar(range(singles_elo$number_of_games),
                                 "steelblue"),
      backgroundSize = "75% 80%",
      backgroundRepeat = "no-repeat",
      backgroundPosition = "right"
    ) %>%
    formatStyle(
      c("Win Percent"),
      background = styleColorBar(c(0,1),
                                 "steelblue"),
      backgroundSize = "75% 80%",
      backgroundRepeat = "no-repeat",
      backgroundPosition = "right"
    ) %>%
    formatPercentage("Win Percent")
  return(rank_table)
}
