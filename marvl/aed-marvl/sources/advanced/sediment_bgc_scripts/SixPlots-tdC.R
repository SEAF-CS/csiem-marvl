  source("ConcLabels.R")
  if(nchar(zones[z])==1){sed<-(paste0(folder,"0000",zones[z],"/",files[i],".sed"))} # Load sed data}
  if(nchar(zones[z])==2){sed<-(paste0(folder,"000" ,zones[z],"/",files[i],".sed"))} # Load sed data}
  if(nchar(zones[z])==3){sed<-(paste0(folder,"00"  ,zones[z],"/",files[i],".sed"))} # Load sed data}
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
  halfdepth <-max(row1)/2
  con <-as.matrix( file [time.start.index+1 :time.stop.index  ,  2:depthindex  ] ) # Concentration matrix
  bw.depth=10; bw.depths= seq(from=(-1*bw.depth), by=1, length.out=bw.depth); bw.mat=matrix(bw.depths);bw.mat
  bw.conc<-0;if(issolid==F){bw.conc=con[,1]}
  bottom.water<-matrix(nrow = dim(con)[1]  , ncol=bw.depth, bw.conc )
  bw.sed.depths<-cbind(t(bw.mat),row1);bw.sed.depths
  timey<-as.vector(t(time)) #  Transpose time #
  if(timey[2]==0){timey[2]<-1e-5}
  time.s<-timey[seq(from=1,to=length(timey),by=subsample)]
  con.s<-as.matrix(con[seq(from=1,to=length(timey),by=subsample),])
  bottom.water.s <- as.matrix(bottom.water[seq(from=1,to=length(timey),by=subsample),])
  con.s.bw       <- cbind(bottom.water.s,con.s)
  dim(con.s)
  datey<-as.Date(time.s,origin = startdate)
  class(datey)
  datex<-format(datey, sep="/", format = "%Y-%b");datex
  # class(datex)
  monthy<-(timey*12) # Use monthly values if necessary
  
  ifelse( abs(max(time,na.rm=T))>1
          ,roundy   <- 10^floor(log10(abs(max(time,na.rm=T))) )/10
          ,roundy   <- 10^floor(log10(abs(min(time,na.rm=T))) )/10
  );roundy
  
  axis.sequence        = round_any(seq(min(time),max(time),length.out=tick.master.x),roundy,f=floor);axis.sequence
  date.axis.sequence.1 = as.Date(axis.sequence,origin = startdate);date.axis.sequence.1
  date.axis.sequence.2 = format(date.axis.sequence.1, sep="/", format = "%b-%Y");date.axis.sequence.2
  y.axis.sequence      = round_any(seq(from=max(bw.sed.depths),to=min(bw.sed.depths)
                                       ,length.out=tick.master.y+1),10,f=floor);y.axis.sequence
  # date.axis.sequence = round_any(seq(min(datey),max(time.s),length.out=5),100,f=floor);date.axis.sequence
  # image.plot(time.s,row1,con.s,cex.lab=0.001
  image.plot(time.s,bw.sed.depths,con.s.bw,cex.lab=0.001
             ,axes=F,ylab="",xlab=""
             ,ylim=c(max(row1),-1*bw.depth)
             # ,zlim=c(0,z.max)
             ,xlim=c(min(axis.sequence),max(axis.sequence))
             ,bigplot=c(0.12,0.83,0.12,0.75)# 1 left; 2 right; 3 bottom; 4 top
             ,smallplot=c(0.85,0.88,0.11,0.77)# 1 left; 2 right; 3 bottom; 4 top
             ,col=newglen(5000)
             ,xaxs = "i"
             ,graphics.reset = F
             ,axis.args=list(cex.axis=axis.tick.size)
             # ,legend.width = 1.10
             
  )
  par(new=T)
  if(issolid==T){
    polygon(x=c(min(axis.sequence),max(axis.sequence),max(axis.sequence),min(axis.sequence))
          ,y=c(-bw.depth,-bw.depth,-0.1,-0.1)
          ,col="gray90")
          # ,col="lightsteelblue1")
  }
  
  par(xpd=TRUE)
  box(bty="o")
  par(mgp=c(1.5,1,0))
  axis(2,cex.axis=axis.tick.size,cex.lab=1.0,tck=T,tcl=-0.2,line=0,at=y.axis.sequence,las=1)
  
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
  
  lines(c(min(axis.sequence),max(axis.sequence)),c(0,0)  ,lty=2,col="white")
  # lines(c(min(axis.sequence),max(axis.sequence)),c(5,5)  ,lty=2,col="white")
  # lines(c(min(axis.sequence),max(axis.sequence)),c(10,10),lty=2,col="white")
  # lines(c(min(axis.sequence),max(axis.sequence)),c(15,15),lty=2,col="white")
    par(mgp=c(1.5,0.2,0))
    # mtext(2,text="Depth",cex=axis.label.size,line=4.0) # 1=bottom, 2=left, 3=top, 4=right
    # mtext(2,text="(cm)",cex=axis.label.size,line=2.8) # 1=bottom, 2=left, 3=top, 4=right
    mtext(2,text="Depth (cm)",cex=axis.label.size,line=3.5) # 1=bottom, 2=left, 3=top, 4=right
    conc.text=expression("(mmol L"^"-1"*")")
    mtext(3,text="Concentration",cex=axis.label.size,line=1.1,adj = 1.3) # 1=bottom, 2=left, 3=top, 4=right
    mtext(3,text=conc.text,cex=axis.label.size,line=-0.1, adj=1.3) # 1=bottom, 2=left, 3=top, 4=right
    mtext(3,text="Time (number of days)",cex=axis.label.size,line=1.5, adj=0.55)
    mtext(1,text="Time (date)",cex=axis.label.size,line=1.5, adj=0.55)