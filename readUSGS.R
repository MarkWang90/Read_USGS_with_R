# install.packages("dataRetrieval")
library(dataRetrieval)
library(glue)

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
    msg = glue("   Attention -- well site {i} could not be retrieived")
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
    msg = glue("   Attention -- well site {i} could not be retrieived")
    cat(msg,file = log2)
    print(msg)
  }
}
