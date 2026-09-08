# In the packages area, install these packages
library(MASS);library(fields);library(readxl)
library(bigmemory);library(imager);library(plyr)
library(clipr)
setwd("aed-marvl/sediment")
sed=NULL; max.con=NULL; lwidthy = 0.1;reso = 200
widthy = 270; heighty = 180; reso=200
desired.depth=40
startdate      = "2019-11-01"
start.time = 2
stop.time  = 20000
subsample = 10
max.con<-matrix(nrow = 1,  ncol = length(zones) )
newglen<-colorRampPalette(colors=c("gray15" # Define a colour ramp
                                   ,"deepskyblue4"
                                   ,"deepskyblue2"
                                   ,"aquamarine"
                                   ,"white"
                                   ,"gold2")
                          ,space="Lab"
                          ,interpolate="spline"
                          ,bias=0.9
)
files<-c( 
           "amm"
          ,"ch4"
          ,"docl"
          ,"docr"
          ,"donl"
          ,"dopl"
          ,"donr"
          ,"dopr"
          ,"feii"
          ,"feoh3a"
          ,"fes"
          ,"h2s"
          ,"feoh3b"
          ,"fes2"
          ,"n2"
          ,"n2o"
          ,"nit"
          ,"no2"
          ,"oxy"
          ,"pocl"
          ,"pocr"
          ,"ponl"
          ,"ponr"
          ,"popl"
          ,"popr"
          ,"pocs"
          ,"pons"
          ,"salinity"
          ,"so4"
          ,"amm"
          ,"ch4"
          )
num<-c("1","2","3","4","5","6","7","8","9","10")
sim<-c("Both","FSalOnly","FSulOnly","Neither")
zones<-c("1","2","3","4")
for(s in 1){#:length(sim)){
for(n in 1:length(num)){
for(z in 1){
for(i in 1:length(files)){
folder<-paste0("results_example/")
print(num[n])
  png(filename=paste0(folder,"../../6P_",files[i],".png")
      ,width=widthy,height=heighty  ,res=reso,units="mm"  )
  tick.master.x = 10;  tick.master.y = 8
  margin.list=c(3,5,5,7) # 1 bottom; 2 left; 3 top; 4 right
  par(mar=margin.list)# 1 bottom; 2 left; 3 top; 4 right
  axis.label.size=0.62;   axis.tick.size=0.9
  the.layout<-layout(mat=matrix(nrow=3,ncol=2
                      ,byrow=TRUE
                      ,c(1,2
                         ,3,4
                         ,5,6
                          ))
                    ,widths = c(1,1)              )
  par(mar=margin.list)# 1 bottom; 2 left; 3 top; 4 right
source("SixPlots-tF.R")
  par(mar=c(2.80,12,5,1))# 1 bottom; 2 left; 3 top; 4 right
source("SixPlots-Poros.R")
  par(mar=margin.list)# 1 bottom; 2 left; 3 top; 4 right
# source("SixPlots-tF.R")
source("SixPlots-tdC.R")
  par(mar=c(2.5,12,5,1))# 1 bottom; 2 left; 3 top; 4 right
source("SixPlots-Biot.R")
  par(mar=margin.list)# 1 bottom; 2 left; 3 top; 4 right
source("SixPlots-tbot2.R")
source("SixPlots-Mass.R")
  par(mar=c(3.0,12,5,1))# 1 bottom; 2 left; 3 top; 4 right
source("SixPlots-CD.R")
  dev.off()
} # end i
} # end z
} # end n
} # end s
dev.off()