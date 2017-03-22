################################################################################
### Calculate player chance of winning matrix
################################################################################

num_players <- nrow(singles_elo)

player_odds <- matrix(vector(), nrow = num_players, ncol = num_players)

for(i in seq_len(num_players)){
  for(j in seq_len(num_players)){
    if(j != i) {
      elo1 <- singles_elo[i, "elo"]
      elo2 <- singles_elo[j, "elo"]

      player_odds[i, j] <- CalculateChance(elo1, elo2)
      player_odds[j, i] <- CalculateChance(elo2, elo1)
    }
  }
}

player_odds_df <- as.data.frame(player_odds)
row.names(player_odds_df) <- player_list
colnames(player_odds_df) <- player_list

# player_odds_df
