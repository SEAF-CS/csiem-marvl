  source("DailyFluxLabels.R") # Call for the label function
  source("DailyFluxLabelsBold.R") # Call for the label function
  source("LabelsBoldNoUnit.R") # Call for the label function
  source("ConcLabels.R")
  print(files[i])
  yy=NA; yydd=NA
  if(nchar(zones[z])==1){fluxsed<-(paste0(folder,"0000",zones[z],"/swi_fluxes.sed"))} # Load sed data}
  if(nchar(zones[z])==2){fluxsed<-(paste0(folder,"000" ,zones[z],"/swi_fluxes.sed"))} # Load sed data}
  if(nchar(zones[z])==3){fluxsed<-(paste0(folder,"00"  ,zones[z],"/swi_fluxes.sed"))}# Load sed data}
  fluxdata<-read.table(file=fluxsed, header=FALSE, skip=2)
  uno  <- as.numeric(as.matrix(fluxdata[3:length(fluxdata[,1]) ,1]) )
  ifelse( max(uno) < start.time ,time.start.index<-which.max(uno), time.start.index<-which.min(abs(uno - start.time)))
  ifelse( max(uno) < stop.time  ,time.stop.index <-which.max(uno)-1, time.stop.index <-which.min(abs(uno - stop.time )))
  times<- uno[time.start.index:time.stop.index]
  
  headings<-as.matrix(fluxdata[1,])
  issolid<-as.matrix(fluxdata[2,])
  fluxcol<-which(headings==files[i])
  chemcol <-as.matrix(fluxdata[ 3:length(fluxdata[,1]) ,fluxcol ])
  chem    <-as.matrix(chemcol[ time.start.index:time.stop.index ])
  chem    <-as.numeric(chem)/1 # /365 to convert from yearly to daily
  # chem    <-as.numeric(chem)/365.35 # /365 to convert from yearly to daily
  yy<-NA
  xx        <-c(min(times),max(times))
  flux.mmol <- chem # mmol m^-2 y^-1  
  flux.mol  <- flux.mmol/1000 # mol m^-2 y^-1  
  flux.g    <- flux.mol*mmass  # g m^-2 y^-1  
  flux.cumul<-NULL;flux.cumul[1:2]=0
  for(fg in 2:length(flux.g)){
    flux.cumul[fg]<-flux.cumul[fg-1]+(flux.g[fg])*(times[fg]-times[fg-1])/365.25
    }
  chemneg=NULL; chempos=NULL
  for (j in 1:length(chem)){
    ifelse(chem[j]<=0
           ,chemneg[j]<-chem[j]
           ,chemneg[j]<-NA)
    ifelse(chem[j]>0
           ,chempos[j]<-chem[j]
           ,chempos[j]<-NA)
  }
  ifelse( abs(max(times,na.rm=T))>1
          ,roundx   <- 10^floor(log10(abs(max(times,na.rm=T))) )/10
          ,roundx   <- 10^floor(log10(abs(min(times,na.rm=T))) )/10
  );roundx
  roundy=1
  ifelse( abs(max(chem,na.rm=T))>1
        ,roundy <- 10^floor(log10(abs(max(chem,na.rm=T))) )/10
        ,roundy <- 10^floor(log10(abs(min(chem,na.rm=T))) )/10
  );roundy
  axis.sequence = round_any(seq(min(times),max(times),length.out=tick.master.x),roundx,f=floor);axis.sequence
  date.axis.sequence.1 = as.Date(axis.sequence,origin = startdate);date.axis.sequence.1
  date.axis.sequence.2 = format(date.axis.sequence.1, sep="/", format = "%b-%Y");date.axis.sequence.2
  ifelse(max(chem,na.rm = T)<0
         ,f.choice<-ceiling
         ,f.choice<-floor
          )
  y.axis.sequence      = round_any(seq(from=min(chem,na.rm = T),to=max(chem,na.rm = T)
                                       ,length.out=tick.master.y)
                                   ,roundy,f=f.choice);y.axis.sequence
  limy                 <-c(min(y.axis.sequence),max(y.axis.sequence))
  
  
  
  plot(times,chem
       ,axes=F
       ,ylab="",xlab=""
       ,pch=20
       ,cex=0.5
       ,col="white"
       ,ylim = limy
       ,xaxs = "i"
       ,xlim = c(min(axis.sequence),max(axis.sequence))
  )
  length(chem)
  lines(times, chem    ,col="purple4"  )
  lines(times, chemneg ,col="navyblue")
  lines(times, chempos ,col="red4"    )
  lines(x=c(min(axis.sequence),max(axis.sequence)),y=c(0,0),lty=2,col="grey80")
  
  box(bty="o")
  axis(3,tck=T,tcl=-0.3,xaxs="i",yaxs="i",line=0,col.axis="white"
       ,at=axis.sequence
  ) # The ticks
  axis(3,cex.axis=axis.tick.size,xaxs="i",yaxs="i",line=-0.50,lwd = 0 
       ,at=axis.sequence
  ) # The labels
  axis(1,tck=T,tcl=-0.3,xaxs="i",yaxs="i",line=0,col.axis="white"
       ,at=axis.sequence
  ) # The ticks
  axis(1,cex.axis=axis.tick.size,xaxs="i",yaxs="i",line=-0.50,lwd = 0 
       ,at=axis.sequence
       ,labels=date.axis.sequence.2 
  ) # The labels
  axis(2,cex.axis=axis.tick.size,cex.lab=1.0,tck=T,tcl=-0.2,line=0,at=y.axis.sequence,las=1)
  # axis(2,cex.axis=0.7,cex.lab=1.0,tck=T,tcl=-0.2,line=0,at=0,las=1)
  mtext(3,text="Time (number of days)",cex=axis.label.size,line=1.5, adj=0.55)
  mtext(1,text="Time (date)",cex=axis.label.size,line=1.5, adj=0.55)
  mtext(3,text=label.bold.nounit,cex=1.0,line=3.0,adj=-0.05)
  mtext(3,text=paste0("Zone ",zones[z]),cex=0.7,line=1.5,adj=0.05)
  mtext(3,text=paste0("Positive = into sediment")  ,cex=axis.label.size,line=2.5,adj=1.5,col="red4")
  mtext(3,text=paste0("Negative = to bottom water"),cex=axis.label.size,line=1.5,adj=1.5,col="navyblue")
  # mtext(2,text="Sediment water flux",cex=axis.label.size,line=4.1)
  # mtext(2,text=expression("(mmol m"^-2*"d"^-1*")"),cex=axis.label.size,line=2.8)
  # mtext(2,text=expression("Sediment water flux (mmol m "^-2*"d "^-1*")"),cex=axis.label.size,line=3.7)
  mtext(2,text=expression("Sediment water flux (mmol m "^-2*"y "^-1*")"),cex=axis.label.size,line=3.7)