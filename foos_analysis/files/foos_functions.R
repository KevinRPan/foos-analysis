##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Set constants and define functions
##      Note: run from foos_elo.R for libraries
##
##      This file defines functions used in the calculation of elo,
##        as well as the plots that show up in the app.
##
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#### Constants ============================================================

elo_diff <- 400
k <- 32
base_elo <- 1200
min_games <- 5

# Elo standards
# Players below 2100: K-factor of 32 used
# Players between 2100 and 2400: K-factor of 24 used
# Players above 2400: K-factor of 16 used.

#### Functions ============================================================

make_names <-
  # Function to clean up column names
  . %>%
  str_trim %>%
  make.names %>%
  str_replace_all('[.]', '_') %>%
  tolower %>%
  str_replace_all('__{1,4}', '_') %>%
  str_replace_all('_$', '')


FormatName <- function(name){
  paste0(toupper(substr(name, 1, 1)), substr(name, 2, nchar(name)))
}

CalculateChance <- function(p1_elo, p2_elo){
  Q1 <- 10^(p1_elo/elo_diff)
  Q2 <- 10^(p2_elo/elo_diff)
  expected_p1 <- Q1/(Q1+Q2)
  return(expected_p1)
}

GameUpdate <- function(df, player1, score1, player2, score2,
                       print_progress = FALSE) {

  player1 %<>% FormatName
  player2 %<>% FormatName
  score1  %<>% as.numeric
  score2  %<>% as.numeric

  elo1 <- df[grepl(player1, df$players), "elo"] %>% as.numeric
  elo2 <- df[grepl(player2, df$players), "elo"] %>% as.numeric

  expected1 <- CalculateChance(elo1, elo2)
  expected2 <- 1 - expected1

  point_diff <- score1 - score2

  margin_of_victory <- log(abs(point_diff))*(2.2/((
    ifelse(score1 > score2, elo1-elo2, elo2-elo1))*.001+2.2))

  k_adj <- k * margin_of_victory

  p1_res <- ifelse(score1 > score2, 1, 0)
  p2_res <- ifelse(score1 > score2, 0, 1)

  updated_elo1 <- elo1 + k_adj*(p1_res - expected1)
  updated_elo2 <- elo2 + k_adj*(p2_res - expected2)

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

PlotElo <- function(elo_tracker, plot_points = TRUE, plot_lines = TRUE) {
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

  ggp <- elo_rename %>%
    ggplot(aes(x = Game_Num, y = Elo,
               col = Player))+ #,group = Player)) +
    xlab("Game Number") +
    ylab("Elo") +
    theme_minimal()
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

  return(ggplotly(ggp, tooltip = c('Elo', 'Player', 'Score_Difference')))
}

PlotCoWMatrix <- function(singles_elo) {
  # Calculate player chance of winning matrix
  # Return a plot of chance of winning

  # readRDS('singles_elo_2016.Rds')

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

  return(d3heatmap(player_odds_df, Rowv = NULL, Colv = 'Rowv'))
}

CreateRankTable <- function(singles_elo) {
  ## Format a table to show:
  ##  Elo, Streaks, Wins, Losses, Total Games
  ##  Add bars for streaks and games
  ##  Add buttons and flexibility for columns
  rank_table <- datatable(
    singles_elo %>%
      mutate(elo = round(elo)) %>%
      select(
        Players = players,
        Elo = elo,
        "Current win streak" = streak,
        "Max win streak" = max_streak,
        Wins = wins,
        Losses = losses,
        "Number of Games" = number_of_games
      ),

    fillContainer = FALSE,
    extensions = c('ColReorder', 'Buttons'),
    options = list(
      paging = FALSE,
      dom = 'Bfrtip',
      buttons = I('colvis'),
      colReorder = TRUE
    )
  ) %>%
    formatStyle(c('Players', 'Elo'), fontWeight = 'Bold') %>%
    formatStyle(
      c('Current win streak',
        'Max win streak'),
      background = styleColorBar(range(singles_elo$max_streak),
                                 'firebrick'),
      backgroundSize = '75% 80%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    ) %>%
    formatStyle(
      c('Wins',
        'Losses',
        'Number of Games'),
      background = styleColorBar(range(singles_elo$number_of_games),
                                 'steelblue'),
      backgroundSize = '75% 80%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'right'
    )
  return(rank_table)
}
