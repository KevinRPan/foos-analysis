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

These numbers are calculated based on the [Elo rating system](https://en.wikipedia.org/wiki/Elo_rating_system).

> A player's Elo rating is represented by a number which increases or decreases depending on the outcome of games between rated players. After every game, the winning player takes points from the losing one. The difference between the ratings of the winner and loser determines the total number of points gained or lost after a game. 

> In a series of games between a high-rated player and a low-rated player, the high-rated player is expected to score more wins. If the high-rated player wins, then only a few rating points will be taken from the low-rated player. However, if the lower rated player scores an upset win, many rating points will be transferred. 

> A player whose rating is too low should, in the long run, do better than the rating system predicts, and thus gain rating points until the rating reflects their true playing strength.

The margin of victory multiplier is based on [Nate Silver's NFL Elo system](http://fivethirtyeight.com/datalab/introducing-nfl-elo-ratings/).

Here we use: $MoV Multiplier = \ln(abs(PD)) * (2.2/((ELOW-ELOL)*.001+2.2))$

Where PD is the point differential in the game, ELOW is the winning player's Elo Rating before the game, and ELOL is the losing player's Elo Rating before the game.

## Notes

* Players have been arbitrarily assigned initial ratings based on years of experience. These may not be accurate, but game data should correct for this. 

## Pitfalls

* Low (or 0), and uneven, game counts for many players, let's add some data!
* No decay for inactive players, so challenge people to make sure their rankings are honest! 
