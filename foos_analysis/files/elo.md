---
title: "Foosball Performance Analysis"
author: "SF Office - KP"
date: "November 1, 2016"
output: 
  html_document:
    theme: lumen
---


***
# About Elo

The [Elo rating system](https://en.wikipedia.org/wiki/Elo_rating_system) is a well-established method system for calculating relative skill of head-to-head competitors. It has been applied to chess, soccer aka football, basketball, American football, video games, Scrabble and more. These numbers are calculated based on some fairly simple rules.

> A player's Elo rating is represented by a number which increases or decreases depending on the outcome of games between rated players. After every game, the winning player takes points from the losing one. The difference between the ratings of the winner and loser determines the total number of points gained or lost after a game. 

> In a series of games between a high-rated player and a low-rated player, the high-rated player is expected to score more wins. If the high-rated player wins, then only a few rating points will be taken from the low-rated player. However, if the lower rated player scores an upset win, many rating points will be transferred. 

> A player whose rating is too low should, in the long run, do better than the rating system predicts, and thus gain rating points until the rating reflects their true playing strength.

# Calculation applied here
[The steps to the calculation](https://metinmediamath.wordpress.com/2013/11/27/how-to-calculate-the-elo-rating-including-example/) are modified slightly to account for winning by a margin.

The margin of victory multiplier is based on [Nate Silver's NFL Elo system](http://fivethirtyeight.com/datalab/introducing-nfl-elo-ratings/).

Here we use: MoV Multiplier = ln(abs(PD)) * (2.2/((ELOW-ELOL)*.001+2.2))

Where PD is the point differential in the game, ELOW is the winning player's Elo Rating before the game, and ELOL is the losing player's Elo Rating before the game.

## Application to European Soccer Teams

Check out an identical app that analyzes Euro Soccer teams here: [Euro Soccer analysis](https://kevinrpan.shinyapps.io/euro_soccer_analysis/)

## Notes

* Players have been arbitrarily assigned initial ratings based on years of experience. These may not be accurate, but game data should correct for this. 

## Pitfalls

* Check out [this page](http://andr3w321.com/elo-ratings-part-2-margin-of-victory-adjustments/) that describes some ways to adjust Margin of victory and account for some disadvantages of the system. 
