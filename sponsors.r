#
# sponsors
#

if (!file.exists(sponsors)) {

  s = data_frame()

  # Dáil Éireann, 1997-2016
  for (i in 31:28) {

    f = paste0("raw/mp-lists/mps-d-", i, ".html")

    if (!file.exists(f))
      download.file(paste0("http://www.oireachtas.ie/members-hist/default.asp?housetype=0&HouseNum=",
                           i, "&disp=mem"), f, mode = "wb", quiet = TRUE)

    h = htmlParse(f)

    s = rbind(s, data_frame(
      legislature = i,
      chamber = "D",
      url = xpathSApply(h, "//a[contains(@href, 'MemberID=')]/@href")
    ))

  }

  # Seanad Éireann, 1997-2016
  for (i in 24:21) {

    f = paste0("raw/mp-lists/mps-s-", i, ".html")

    if (!file.exists(f))
      download.file(paste0("http://www.oireachtas.ie/members-hist/default.asp?housetype=1&HouseNum=",
                           i, "&disp=mem"), f, mode = "wb", quiet = TRUE)

    h = htmlParse(f)

    s = rbind(s, data_frame(
      legislature = i,
      chamber = "S",
      url = xpathSApply(h, "//a[contains(@href, 'MemberID=')]/@href")
    ))

  }

  write.csv(s, sponsors, row.names = FALSE)

}

s = read.csv(sponsors, stringsAsFactors = FALSE)

y = str_extract(s$url, "MemberID=\\d+") %>% unique
cat("Parsing", length(y), "sponsors\n")

s = data_frame()

for (i in y) {

  f = paste0(gsub("MemberID=", "raw/mp-pages/mp-", i), ".html")

  if (!file.exists(f))
    download.file(paste0("http://www.oireachtas.ie/members-hist/default.asp?", i),
                  f, mode = "wb", quiet = TRUE)

  if (file.exists(f)) {

    h = htmlParse(f, encoding = "UTF-8")

    photo = xpathSApply(h, "//div[@class='memberdetails']/img/@src")
    name = xpathSApply(h, "//div[@class='memberdetails']/h3", xmlValue)
    born = xpathSApply(h, "//div[@class='memberdetails']/p[1]", xmlValue)
    party1 = xpathSApply(h, "//div[@class='memberdetails']//a[contains(@href, 'Party')]", xmlValue)
    party1 = ifelse(!length(party1), NA, party1)

    mandate = xpathSApply(h, "//li[@class='housenbr']", xmlValue)
    constituency = xpathSApply(h, "//div[@class='memberdetails']//a[contains(@href, 'ConstID')]",
                               xmlValue)
    party = xpathSApply(h, "//li[@class='housenbr']//following-sibling::li[3]", xmlValue)

    if (!length(party))
        party = NA

    s = rbind(s, data_frame(
      uid = gsub("\\D", "", i),
      name, born, mandate, constituency, party1, party,
      photo = ifelse(is.null(photo), NA, photo)
    ))

  }

}

#
# finalize sponsor variables
#

s$born = str_extract(s$born, "\\d{4}") %>% as.integer

# note: chairs do not show up in the networks, so imputation is alright
s$party[ grepl("Office|Cathaoirleach", s$party) ] = NA
s$party[ is.na(s$party) ] = s$party1[ is.na(s$party) ]

s$party = gsub("Party:\\s|\\(2011\\)|\\smembers(.*)", "", s$party)
s$party = str_clean(s$party)

s$sex = s$name
s$sex[ grepl("Mr\\.", s$sex) ] = "M"
s$sex[ grepl("M(r)?s\\.", s$sex) ] = "F"
s$sex[ grepl("(Dermot|Edward|James|Jerry|John|Liam|Leo|Martin|Maurice|Michael|Pat|Rory|Tom)\\s", s$sex) ] = "M"
s$sex[ grepl("(Katherine|Máirín|Marian|Mary)\\s", s$sex) ] = "F"

s$name = gsub("Professor\\s|\\s(\\()?(Deceased|Resigned)(\\))?", "", s$name)
s$name = gsub("(M|D)(r|s|rs)\\.\\s|\\.", "", s$name) %>% str_trim

# duplicates
s$name[ s$uid == 107 ] = "John Browne-1" # matched in sponsors lists
# s$name[ s$uid == 108 ] = "John Browne-2" # matched in sponsors lists

a = strsplit(b$authors, ";") %>% unlist
stopifnot(a %in% s$name)

s$legislature = str_extract(s$mandate, "\\d{2}") %>% as.integer
s$chamber = ifelse(grepl("Dáil", s$mandate), "da", "se")
table(s$chamber, s$legislature, exclude = NULL)

s$party = str_clean(s$party)
s$party[ grepl("Ceann Comhairle|Cathaoirleach", s$party) ] = "CHAIR" # chamber chairs, not used
s$party[ grepl("The Workers' Party", s$party) ] = "WP" # not used
s$party[ grepl("Democratic Left", s$party) ] = "DL"
s$party[ grepl("Anti Austerity Alliance", s$party) ] = "AAA"
s$party[ grepl("Fianna Fáil", s$party) ] = "FF"
s$party[ grepl("Fine Gael", s$party) ] = "FG"
s$party[ grepl("Sinn Féin", s$party) ] = "SF"
s$party[ grepl("Labour", s$party) ] = "LAB"
s$party[ grepl("Green Party", s$party) ] = "GP"
s$party[ grepl("Progressive Democrats", s$party) ] = "PD"
s$party[ grepl("Socialist Party", s$party) ] = "SOC"
s$party[ grepl("RENUA Ireland", s$party) ] = "RENUA"

# last two residuals are not used in the networks
s$party[ grepl("Independent|Other|People Before Profit|Unemployed", s$party) ] = "IND"

s$party[ s$uid == 1955 & s$legislature == 14 ] = "FF"
s$party[ s$uid == 2150 & s$legislature == 21 ] = "IND"
table(s$party, s$legislature, exclude = NULL)

#
# sponsor photos
#

cat("Downloading", n_distinct(na.omit(s$photo)), "photos\n")
for (i in na.omit(s$photo)) {

  f = paste0("photos/", basename(i))

  if (!file.exists(f))
    download.file(paste0(root, i), f, mode = "wb", quiet = TRUE)

  if (file.exists(f))
    s$photo[ s$photo == i ] = f
  else
    s$photo[ s$photo == i ] = NA

}

# ==============================================================================
# CHECK CONSTITUENCIES
# ==============================================================================

# note: matches are not perfect, but should work fine for modern legislatures

stopifnot(!is.na(s$constituency))
s$constituency[ s$constituency == "Longford -Westmeath" ] = "Longford-Westmeath"
s$constituency[ s$constituency == "Sligo Leitrim North" ] = "Sligo-Leitrim"
s$constituency[ s$constituency == "Roscommon Leitrim South" ] = "Roscommon-South Leitrim"
s$constituency[ s$constituency == "Kerry North Limerick West" ] = "Kerry North West Limerick"

s$constituency = gsub("\\(|\\)", "", s$constituency)
s$constituency = ifelse(grepl("Panel", s$constituency), s$constituency,
                        paste(s$constituency, "(Dáil Éireann constituency)"))
s$constituency = gsub("-", "–", s$constituency)
s$constituency = gsub("\\s", "_", s$constituency)

cat("Checking constituencies,", sum(is.na(s$constituency)), "missing...\n")
for (i in s$constituency %>% unique %>% na.omit) {

  g = GET(paste0("https://en.wikipedia.org/wiki/", i))

  if (status_code(g) != 200)
    cat("Missing Wikipedia entry:", i, "\n")

  g = xpathSApply(htmlParse(g), "//title", xmlValue)
  g = gsub("(.*) - Wikipedia(.*)", "\\1", g)

  if (gsub("\\s", "_", g) != i)
    cat("Discrepancy:", g, "(WP) !=", i ,"(data)\n")

}

# ============================================================================
# QUALITY CONTROL
# ============================================================================

# - might be missing: born (int of length 4), constituency (chr),
#   photo (chr, folder/file.ext)
# - never missing: sex (chr, F/M), nyears (int), url (chr, URL),
#   party (chr, mapped to colors)

cat("Missing", sum(is.na(s$born)), "years of birth\n")
stopifnot(is.integer(s$born) & nchar(s$born) == 4 | is.na(s$born))

cat("Missing", sum(is.na(s$constituency)), "constituencies\n")
stopifnot(is.character(s$constituency))

cat("Missing", sum(is.na(s$photo)), "photos\n")
stopifnot(is.character(s$photo) & grepl("^photos(_\\w{2})?/(.*)\\.\\w{3}", s$photo) | is.na(s$photo))

stopifnot(!is.na(s$sex) & s$sex %in% c("F", "M"))
# stopifnot(!is.na(s$nyears) & is.integer(s$nyears)) ## computed on the fly
# stopifnot(!is.na(s$url) & grepl("^http(s)?://(.*)", s$url)) ## used as uids
stopifnot(s$party %in% names(colors))
