################################################################################
### Set constants and define functions
################################################################################

############### Constants #####################################################

elo_diff <- 400
k <- 32

# Players below 2100: K-factor of 32 used
# Players between 2100 and 2400: K-factor of 24 used
# Players above 2400: K-factor of 16 used.

############### Functions #####################################################

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

GameUpdate <- function(data, player1, score1, player2, score2,
                       print_progress = FALSE) {

  player1 %<>% FormatName
  player2 %<>% FormatName
  score1  %<>% as.numeric
  score2  %<>% as.numeric

  elo1 <- data[grepl(player1, data$players), "elo"] %>% as.numeric
  elo2 <- data[grepl(player2, data$players), "elo"] %>% as.numeric

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
  data[grepl(player1, data$players), "elo"] <- updated_elo1
  data[grepl(player2, data$players), "elo"] <- updated_elo2

  ## increment games
  data[grepl(player1, data$players), "number_of_games"] <-
    data[grepl(player1, data$players), "number_of_games"] + 1
  data[grepl(player2, data$players), "number_of_games"] <-
    data[grepl(player2, data$players), "number_of_games"] + 1


  return(data)
}