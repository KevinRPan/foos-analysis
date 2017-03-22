################################################################################
### Foos Elo
################################################################################

library(pacman)
p_load(dplyr, magrittr, stringr, knitr, lubridate, googlesheets)

source("foos_functions.R")

### Read in games history
# foos <- readxl::read_excel("H:/foos.xlsx")
foos <- gs_read(gs_title("Foos Scores"))

colnames(foos) %<>% make_names

singles_games <- foos %>% filter(type == "Singles") %>%
  select(game_num,
         date,
         t1_p1,
         t1_score,
         t2_p1,
         t2_score) #%>%
  # mutate(date = dm(date))

### Number of games
singles_games %>% group_by(t2_p1) %>%
  summarise(N=n())

### Baseline experience
first_years <- c("Zong",  "Hallie", "Evan",  "Andrea", "Kevin")
second_years <- c("Henna", "Jamie", "Will", "Cody", "David", "Kirby")
third_years <- c("Angela", "Sam", "Dc")

### Create elo table
singles_elo <- singles_games %>%
  select(t1_p1, t2_p1) %>%
  stack %>%
  select(players = values) %>%
  # rbind("Kevin") %>% #, "Dc", "Kirby", "Cody",
  distinct %>%
  arrange(players) %>%
  mutate(elo = 1500 +
           ifelse(players %in% first_years, -300,
           ifelse(players %in% third_years, 300, 100)),
         number_of_games = 0)

singles_elo %>%
  .[[1]] -> player_list


### Run elo calculation loop

elo_tracker <- singles_elo %>% mutate(game_num = 0, score_diff = 0)
for(game_num in seq_len(nrow(singles_games))) {
  p1 <- singles_games[game_num, "t1_p1"] %>% as.character
  p2 <- singles_games[game_num, "t2_p1"] %>% as.character

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


# saveRDS(elo_tracker, "elo_tracker_first_3_months.Rds")
############# Plot ELO #########################################################
library(ggplot2)
old_elo_tracker <- readRDS("../elo_tracker_first_3_months.Rds")


ggp <- ggplot(data=elo_tracker) +
  geom_line(aes(x = game_num, y = elo, col = players, group = players)) +
  geom_point(aes(x = game_num, y = elo, col = players, group = players, size = score_diff),
             alpha = .2) +
  xlab("Game Number") +
  ylab("Elo") +
  theme_minimal()

ggp

# singles_elo

############# Get chances matrix ##############################################
source("foos_chances_matrix.R")

# odds_df <- as.data.frame(player_odds, row.names = player_list)
# names(odds_df) <- player_list
# heatmap(odds_df, Rowv=NA, Colv=NA, col = heat.colors(256), scale="column", margins=c(5,10))

