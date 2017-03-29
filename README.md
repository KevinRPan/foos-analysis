Foosball Analysis
=================

A totally rad Elo analysis of foosball games at the office.
![totally rad foos banner](https://raw.githubusercontent.com/kevinrpan/foos-analysis/master/img/foos_banner.jpg)

Check out the site here:
https://kevinrpan.shinyapps.io/foos_analysis/

Site built using Shiny and HTML widget libraries. 


***

## About Elo

The [Elo rating system](https://en.wikipedia.org/wiki/Elo_rating_system) is a well-established method system for calculating relative skill of head-to-head competitors. It has been applied to chess, soccer aka football, basketball, American football, video games, Scrabble and more. These numbers are calculated based on some fairly simple rules.

> A player's Elo rating is represented by a number which increases or decreases depending on the outcome of games between rated players. After every game, the winning player takes points from the losing one. The difference between the ratings of the winner and loser determines the total number of points gained or lost after a game. 

> In a series of games between a high-rated player and a low-rated player, the high-rated player is expected to score more wins. If the high-rated player wins, then only a few rating points will be taken from the low-rated player. However, if the lower rated player scores an upset win, many rating points will be transferred. 

> A player whose rating is too low should, in the long run, do better than the rating system predicts, and thus gain rating points until the rating reflects their true playing strength.

***

### Calculation applied here
[The steps to the calculation](https://metinmediamath.wordpress.com/2013/11/27/how-to-calculate-the-elo-rating-including-example/) are modified slightly to account for winning by a margin.

The margin of victory multiplier is based on [Nate Silver's NFL Elo system](http://fivethirtyeight.com/datalab/introducing-nfl-elo-ratings/).

Here we use: MoV Multiplier = ln(abs(PD)) * (2.2/((ELOW-ELOL)*.001+2.2))

Where PD is the point differential in the game, ELOW is the winning player's Elo Rating before the game, and ELOL is the losing player's Elo Rating before the game.

***

## Examples

Interactively track Elo over time!
![elo tracking](https://raw.githubusercontent.com/kevinrpan/foos-analysis/master/img/elo_tracker.png)

See expected win chance in matchups! 
![player expectancy](https://raw.githubusercontent.com/kevinrpan/foos-analysis/master/img/player_expectancy.PNG)
