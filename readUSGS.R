# install.packages("dataRetrieval")
# install.packages("glue")
# install.packages("sqldf")
library(dataRetrieval)
library(glue)
library(sqldf)

#### retrive site information for Texas wells ####

## selection criterier on the website:
# https://waterservices.usgs.gov/rest/Site-Test-Tool.html

# Major filters: State or Territory
# State or Territory: Texas
# Dates: 2015-01-01 to 2018-04-01
# Sites with These site types: Well
# Show only sites serving these data types: Groundwater levels
# Show period of record information about these data types: Groundwater levels

## output generated "wellsites.txt"
###

#### read in sites information ####
sites = read.csv("wellsites.txt",header = TRUE, skip = 29, sep="\t")
sites = sites[-1,] #remove first row

sitesID = unique(sites$site_no)
totalsites = length(sitesID)


#### get ground water level for all sites ####
columnstokeep = c('site_no','lev_dt','lev_va')
log = file('getgwl.log')
gwl_data = data.frame(matrix(ncol=length(columnstokeep), nrow=0))
for (i in 1:totalsites) {
  if (i %% 100 == 0) {
    print(glue("Working on {i} out of {totalsites} sites"))
  }
  temp=try(readNWISgwl(sitesID[i])[columnstokeep],TRUE)
  if(class(temp) != "try-error"){
    gwl_data = rbind(gwl_data,temp)
  } else{
    msg = glue("   Attention -- well site {i} could not be retrieived",append = TRUE)
    cat(msg,file = log)
    print(msg)
  }
}

print(head(gwl_data))

#### get site location, well depth information ####
# test=readNWISsite(sitesID[i])
columnstokeep = c("site_no", "station_nm", "dec_lat_va", "dec_long_va", 
                  "state_cd", "county_cd", "well_depth_va")
sitedata = data.frame(matrix(ncol=length(columnstokeep), nrow=0))
log2 = file('getsite.log')
for (i in 1:totalsites){
  if (i %% 100 == 0) {
    print(glue("Working on {i} out of {totalsites} sites"))
  }
  temp=try(readNWISsite(sitesID[i])[columnstokeep],TRUE)
  if(class(temp) != "try-error"){
    sitedata = rbind(sitedata,temp)
  } else{
    msg = glue("   Attention -- well site {i} could not be retrieived",append = TRUE)
    cat(msg,file = log2)
    print(msg)
  }
}


#### merge site info with ground level data ####
print(head(gwl_data))
print(head(sitedata))

gwl_site = merge(gwl_data,sitedata,by="site_no",all.x = TRUE)

#### few cleanups ####

## remove na data
gwl_site = na.omit(gwl_site)

## remove observations before 2010
cutoffdate = '2010-01-01'
gwl_site = gwl_site[gwl_site$lev_dt>cutoffdate,]

## select most 5 (if avaialble) recent observation for each site
selected = sqldf("select * from gwl_site as g1
              where 5 > (select count(distinct(g2.lev_dt))
                          from gwl_site as g2
                          where g2.lev_dt > g1.lev_dt
                          and g2.site_no = g1.site_no
                 )")

# generate the 5-year mean for each site
gwl_avg = sqldf(" select *, avg(lev_va) as avg_gwl
                  from selected 
                  group by site_no
                ")

columnstokeep = colnames(gwl_avg)[-2]
gwl_avg = gwl_avg[columnstokeep]
