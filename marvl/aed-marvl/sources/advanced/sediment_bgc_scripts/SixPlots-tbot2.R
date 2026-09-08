  source("DailyFluxLabels.R") # Call for the label function
  source("DailyFluxLabelsBold.R") # Call for the label function
  source("LabelsBoldNoUnit.R") # Call for the label function
  source("ConcLabels.R")
  yy=NA; yydd=NA
  
  if(nchar(zones[z])==1){sed<-(paste0(folder,"0000",zones[z],"/",files[i],".sed"));depfi<-(paste0(folder,"0000",zones[z],"/Depths.sed"))} # Load sed data}
  if(nchar(zones[z])==2){sed<-(paste0(folder,"000" ,zones[z],"/",files[i],".sed"));depfi<-(paste0(folder,"000" ,zones[z],"/Depths.sed"))} # Load sed data}
  if(nchar(zones[z])==3){sed<-(paste0(folder,"00"  ,zones[z],"/",files[i],".sed"));depfi<-(paste0(folder,"00"  ,zones[z],"/Depths.sed"))} # Load sed data}
  
  file<-read.table(file=sed, header=FALSE, skip=3)# Load sed data
  nnrows=length(file)-3# Load sed data 
  eins<-file[1,] # First column
  uno <-file[,1]
  ifelse( max(uno) < start.time ,time.start.index<-length(uno) ,time.start.index<-which.min(abs(uno - start.time)))
  ifelse( max(uno) < stop.time  ,time.stop.index<-length(uno)  ,time.stop.index <-which.min(abs(uno - stop.time )))
  # time<-as.matrix(file[1:which.max(file[,1]),1])/1#365.25 # Adjust this to change time unit
  time<-as.matrix(uno[time.start.index:time.stop.index])/1#365.25 # Adjust this to change time unit
  halftime   <-time[length(time)/2]
  ifelse( max(eins) < desired.depth ,depthindex<-length(eins),depthindex<-which.min(abs(eins - desired.depth)))
  row1<-as.matrix(     file[1,1:depthindex  ]    )            #layernum]) # Top row
  con <-as.matrix( file [time.start.index :time.stop.index  , dim(con)[2]   ] ) # Concentration matrix

  chem    <-as.numeric(con)#/365 #to convert from yearly to daily
  # chem    <-as.numeric(chem)/365.35 # /365 to convert from yearly to daily
  conc.mmol <- chem # mmol L^-1   
  conc.mol  <- conc.mmol/1000 # mol L^-1   
  conc.g    <- conc.mol*mmass  # g L^-1     
  conc.m3   <- conc.g*1000  # g m^-3     

  depfile.1<-as.matrix(read.table(file=depfi, header=FALSE, skip=0))
  rownames(depfile.1)<-gsub("&","",depfile.1[,1])
  depfile.2<-data.frame(t(gsub(" ", "",depfile.1[,2:dim(depfile.1)[2]])))
  porewatervolume=as.numeric( depfile.2$Porewater_m3_per_m2[2:dim(depfile.2)[1]])
  solidsvolume   =as.numeric(depfile.2$Solids_m3_per_m2[2:dim(depfile.2)[1]])
  thickness      =as.numeric(depfile.2$Thick_cm[2:dim(depfile.2)[1]])
  thedepths      =as.numeric(depfile.2$Depths[2:dim(depfile.2)[1]])  
  
  if(issolid==F){
          #print("Solute")
          # conc.m2<-sweep(x=conc.m3, MARGIN = 2, STATS = porewatervolume[length(porewatervolume)], FUN="*")
          conc.m2<-conc.m3*porewatervolume[length(porewatervolume)]
        }
  
  if(issolid==T){
          #print("Solid")
          # conc.m2<-sweep(x=con,MARGIN=2,STATS=solidsvolume,FUN="*")
          conc.m2<-conc.m3*solidsvolume[length(solidsvolume)]
        }
  
  bot.cumul<-NULL;bot.cumul[1:2]=0
  for(cg in 2:length(conc.m2)){
    # bot.cumul[cg]<-bot.cumul[cg-1]+(conc.m2[cg]-conc.m2[cg-1])*(time[cg]-time[cg-1])/365.25
    bot.cumul[cg]<-bot.cumul[cg-1]+(conc.m2[cg]-conc.m2[cg-1])#*(time[cg]-time[cg-1])/365.25
  }
  bot.cumul =  bot.cumul*+1 # reverse the negative, to add up the total mass change
  bot.cumul # g m^-2 cumulative
  # plot(bot.cumul)
  