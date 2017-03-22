##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Foos Elo
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# if (!require("pacman")) install.packages("pacman")
# pacman::p_install(dplyr, magrittr, stringr, knitr, googlesheets, ggplot2)
library(dplyr)
library(magrittr)
library(stringr)
library(knitr)
library(googlesheets)
library(ggplot2)
library(plotly)
library(d3heatmap)

source("files/foos_functions.R")

#### Read in games history ------------------------------------------------------
## Load historic data
elo_tracker_f3m <- readRDS("files/elo_tracker_first_3_months.Rds")
singles_games_f3m <- readRDS("files/singles_games_f3m.Rds")
player_list_f3m <- elo_tracker_f3m %>%
  distinct(players) %>%
  arrange(players) %>%
  .[[1]]

elo_tracker_2016 <- readRDS('files/elo_tracker_2016.Rds')
singles_elo_2016 <- readRDS('files/singles_elo_2016.Rds')
singles_games_2016 <- readRDS('files/singles_games_2016.rds')

# foos <- readxl::read_excel("H:/foos.xlsx")
# foos <- gs_read(gs_title("Foos Scores"))

## Load current data
sheet_link <- "https://docs.google.com/spreadsheets/d/1Zjyp6lVjJ1ADfRsK4u8OV9W9kSD7IrDHkwcy_E1iZ5I/edit?usp=sharing"

## Currently demo 2016 matches
foos <- gs_read(gs_url(sheet_link), ws = 'Matches 2016')
# foos <- gs_read(gs_url(sheet_link))

colnames(foos) %<>% make_names

singles_games <- foos %>% filter(type == "Singles") %>%
  select(game_num,
         date,
         t1_p1,
         t1_score,
         t2_p1,
         t2_score)

# singles_games %>% saveRDS('files/singles_games_2016.rds')
# singles_games %>% saveRDS('files/singles_games_f3m.Rds')

## Baseline experience for SF office, optional
if(year_variation <- FALSE) {
  first_years <- c("Zong",  "Hallie", "Evan",  "Andrea")
  second_years <- c("Henna", "Jamie", "Will", "Cody","Kevin", "David", "Kirby")
  third_years <- c("Angela", "Sam", "Dc")
} else {
  first_years <- ''
  third_years <- ''
}

## Create elo table ------------------------------------------------------------
singles_elo <- singles_games %>%
  select(t1_p1, t2_p1) %>%
  stack %>%
  select(players = values) %>%
  distinct %>%
  arrange(players) %>%
  mutate(elo = base_elo +
           ifelse(players %in% first_years, -250,
           ifelse(players %in% third_years, 200, 50)),
         wins            = 0,
         losses          = 0,
         number_of_games = 0,
         streak          = 0,
         max_streak      = 0)

player_list <- singles_elo %>% .[[1]]

elo_tracker <- singles_elo %>% mutate(game_num = 0, score_diff = 0)

## Run elo calculation loop --------------------------------------------------
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

singles_elo %<>% arrange(desc(elo))

# singles_elo %>% saveRDS('singles_elo_2016.Rds')
# saveRDS(elo_tracker, "elo_tracker_first_3_months.Rds")
# saveRDS(elo_tracker, "elo_tracker_2016.Rds")

#### Plot ELO -----------------------------------------------------------------

# elo_plot_first_3_mo <- "elo_tracker_first_3_months.Rds" %>% readRDS %>% PlotElo
# elo_plot_2016 <- "elo_tracker_2016.Rds" %>% readRDS %>% PlotElo

#### Get chances matrix -------------------------------------------------------
## Requires singles_elo
## Returns a d3 matrix
# d3_chance_winning <- PlotCoWMatrix(singles_elo)

