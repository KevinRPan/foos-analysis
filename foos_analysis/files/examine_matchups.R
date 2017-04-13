
singles_elo_alphabetical <- singles_elo %>%
  filter(number_of_games > min_games) %>%
  arrange(players)

num_players <- nrow(singles_elo_alphabetical)
player_odds <- matrix(vector(), nrow = num_players, ncol = num_players)
player_list <- singles_elo_alphabetical %>% .[[1]]
player_list_all <- singles_elo %>% .[[1]]


map(player_list_all %>% set_names(player_list_all),
    function(p1) {
      map_df(player_list_all %>% set_names(player_list_all),
          function(p2) {
            if (p1 != p2) {
              matchup <- ExamineMatchup(singles_games, p1, p2)
              return(matchup)
            }
          })
    }
) -> matchups

debug(ExamineMatchup)
ExamineMatchup(singles_games, 'Paul')
