##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Calculate player chance of winning matrix
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(d3heatmap)

# readRDS('singles_elo_2016.Rds')
num_players <- nrow(singles_elo)

player_odds <- matrix(vector(), nrow = num_players, ncol = num_players)

singles_elo_alphabetical <- singles_elo %>% arrange(players)

## Calculate the matrix of odds -----------------------------------------------

for(i in seq_len(num_players)){
  for(j in seq_len(num_players)){
    if(j != i) {
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

# melted_odds <- player_odds %>% reshape2::melt()

## Create ggplot matrix -------------------------------------------------------
player_odds_ggp <- player_odds %>%
  reshape2::melt() %>%
  ggplot(aes(x=Var1, y = Var2, fill = 1-value)) +
  # geom_tile() +
  geom_raster() +
  scale_fill_gradient2(low = "firebrick", high = "steelblue", mid = "white",
                       midpoint = .5, limit = c(0,1), space = "Lab",
                       name="Chance of winning") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45,
                                   vjust = 1.5,
                                   hjust = 1),
        axis.text.y = element_text(hjust = 1.5),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.grid.major = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "bottom",
        legend.direction = "horizontal") +
  guides(fill = guide_colorbar(barwidth = 10, barheight = .5,
                               title.position = "bottom", title.hjust = 0.5)) +
  geom_text(aes(Var2, Var1,
                label = ifelse(!is.na(value),paste0(round(value,2)*100,"%"),NA)),
            color = "black", size = 4)

# player_odds_ggp
# player_odds_df
