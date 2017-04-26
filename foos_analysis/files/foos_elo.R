##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##    Foos Elo
##
##      This file runs through the calculation of Elo.
##      1) Read in games
##      2) Create elo table
##      3) Run elo calculation loop
##
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# if (!require("pacman")) install.packages("pacman")
# pacman::p_install(dplyr, magrittr, stringr, knitr, googlesheets, ggplot2)


source("files/elo_functions.R")

#### 1) Read in games history ------------------------------------------------------
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

## Currently live data
foos <- gs_read(gs_url(sheet_link), ws = 'All Matches') %>%
  set_colnames(make_names(names(.)))

# foos <- gs_read(gs_url(sheet_link), ws = 'Matches 2016')

# colnames(foos) %<>% make_names

# doubles_games <- foos %>%
#   filter(type == 'Doubles')

singles_games <- foos %>%
  filter(type == "Singles") %>%
  select(game_num,
         date,
         t1 = t1_p1,
         t1_score,
         t2 = t2_p1,
         t2_score,
         winner_1,
         comments,
         office) %>%
  mutate_at(vars(t1, t2, winner_1),
            funs(str_extract(., '\\w+') %>% str_to_title))

doubles_games <- foos %>%
  filter(type == 'Doubles')
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


#### 2) Run elo calculation loop =============================================
## Singles Games to Singles Elo


singles_elo_results <- singles_games %>%
  split(.$office) %>%
  map(RunCalculationLoop)
# elo_results <- RunCalculationLoop(singles_games)
# singles_elo <- elo_results$singles_elo
# elo_tracker <- elo_results$elo_tracker
player_list_all <- singles_games %>%
  select(t1, t2) %>%
  stack %>%
  distinct(values) %>%
  .[[1]]

## Doubles Games to Dubs Elo
dubs_elo_results <- doubles_games %>%
  split(.$office) %>%
  map(DoublesCalculationLoop)
# dubs_elo_results <- DoublesCalculationLoop(doubles_games)
# dubs_elo <- dubs_elo_results$dubs_elo
# dubs_elo_tracker <- dubs_elo_results$dubs_elo_tracker

# c(elo_results, dubs_elo_results)[['DC']] %>% glimpse
elo_results <- Map(c, singles_elo_results, dubs_elo_results)
#### Optional code for debugging ==============================================

# singles_elo %>% saveRDS('singles_elo_2016.Rds')
# saveRDS(elo_tracker, "elo_tracker_first_3_months.Rds")
# saveRDS(elo_tracker, "elo_tracker_2016.Rds")

## Plot ELO -----------------------------------------------------------------

# elo_plot_first_3_mo <- "elo_tracker_first_3_months.Rds" %>% readRDS %>% PlotElo
# elo_plot_2016 <- "elo_tracker_2016.Rds" %>% readRDS %>% PlotElo

## Get chances matrix -------------------------------------------------------
## Requires singles_elo
## Returns a d3 matrix
# d3_chance_winning <- PlotCoWMatrix(singles_elo)

