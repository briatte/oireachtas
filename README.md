This repository contains code to build cosponsorship networks from bills passed in the [Irish Parliament](http://www.oireachtas.ie/).

- [interactive demo](http://f.briatte.org/parlviz/oireachtas)
- [static plots](http://f.briatte.org/parlviz/oireachtas/plots.html)
- [more countries](https://github.com/briatte/parlnet)

# HOWTO

Replicate by running `make.r` in R.

The `data.r` script downloads information on bills and sponsors, including their photos (which should all download fine). The `build.r` script then assembles the edge lists and plots the networks, with the help of a few routines coded into `functions.r`. Adjust the `plot`, `gexf` and `mode` parameters to skip the plots or to change the node placement algorithm.

The data are extremely sparse -- given how the Irish legislature works, and given the small number of parliamentarians in both chambers, there are only a handful of cosponsorships per year. As far as legislative cosponsorship goes, the Irish case is best understood as a borderline case that gives the minimal dimensions of a cosponsorship network.

# DATA

## Bills

- `chamber` -- lower (`da`) or upper (`se`)
- `legislature` -- legislature id
- `ref` -- bill id
- `origin` -- private (`PM`) or governmental (`GOV`) bill
- `year` -- date (yyyy-mm-dd)
- `name` -- title
- `url` -- URL
- `authors` -- URL to sponsors list
- `sponsors` -- semicolon-separated integer ids of sponsors
- `n_au` -- total number of sponsors

## Sponsors

The saved version of the `sponsors.csv` dataset contains only `url` (profile URL, shortened to its numeric id), `legislature` and `chamber` (same as for bills). All other variables are collected on the way to plotting the networks:

- `name` -- name (duplicates solved by numbering them)
- `born` -- year of birth (int)
- `photo` -- photo URL, as a filename
- `party` -- party affiliation, abbreviated
- `constituency` -- constituency, stored as the string to its Wikipedia English entry
- `sex` -- gender (F/M), sometimes imputed from first and family names
- `nyears` -- seniority, in intervals of 5 years (computed on the fly)

Note -- chamber chairs (_Cathaoirleach_ and _Ceann Comhairle_) are coded as "parties", even though they are not. Chairs do not show up in the networks.
