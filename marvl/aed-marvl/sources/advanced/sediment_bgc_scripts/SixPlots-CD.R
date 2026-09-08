
desired.depths = c(5,10)

source("../3Plot/ThreePlots-ConcLabels.R")
if(nchar(zones[z])==1){sed<-(paste0(folder,"0000",zones[z],"/",files[i],".sed"));depfi<-(paste0(folder,"0000",zones[z],"/Depths.sed"))} # Load sed data}
if(nchar(zones[z])==2){sed<-(paste0(folder,"000" ,zones[z],"/",files[i],".sed"));depfi<-(paste0(folder,"000" ,zones[z],"/Depths.sed"))} # Load sed data}
if(nchar(zones[z])==3){sed<-(paste0(folder,"00"  ,zones[z],"/",files[i],".sed"));depfi<-(paste0(folder,"00"  ,zones[z],"/Depths.sed"))} # Load sed data}
file    <-read.table(file=sed, header=FALSE, skip=3)# Load sed data
depfile.1<-as.matrix(read.table(file=depfi, header=FALSE, skip=0))
rownames(depfile.1)<-gsub("&","",depfile.1[,1])
depfile.2<-data.frame(t(depfile.1[,2:dim(depfile.1)[2]]))

nnrows=length(file)-3# Load sed data 
eins<-file[1,] # First column
uno <-file[,1]
ifelse( max(uno) < start.time ,time.start.index<-which.max(uno) ,time.start.index<-which.min(abs(uno - start.time)))
time<-as.matrix(uno[time.start.index:time.stop.index])/1#365.25 # Adjust this to change time unit

ifelse( max(eins) < desired.depth ,depthindex<-length(eins)-1,depthindex<-which.min(abs(eins - desired.depth)))
ifelse( max(eins) < desired.depths[1] ,depthindex.1<-length(eins),depthindex.1<-which.min(abs(eins - desired.depths[1])))
ifelse( max(eins) < desired.depths[2] ,depthindex.2<-length(eins),depthindex.2<-which.min(abs(eins - desired.depths[2])))
                                       depthindex.3<-length(eins)

row1<-as.matrix(     file[1,1:depthindex  ]    )            #layernum]) # Top row
rowt<-as.matrix(     file[dim(file)[1]-1,2:depthindex  ]    )            #layernum]) # Top row 
                 # Minus 1 here because if the run gets cut off, the last row can be cut short
the.depths<-rev(row1[2:length(row1)])

y.axis.sequence      = round_any(seq(from=0,to=max(mas.sum),length.out=tick.master.y),roundy,f=floor);y.axis.sequence
y.axis.sequence.2    = round_any(seq(from = min(flux.cumul[3:length(flux.cumul)],
                                                bot.cumul, na.rm = T)
                                     ,to  = max(flux.cumul[3:length(flux.cumul)],
                                                bot.cumul, na.rm = T)
                                     ,length.out=tick.master.y)
                                 ,roundy.2,f=floor);y.axis.sequence.2
if(anyNA(y.axis.sequence.2)){y.axis.sequence.2=0}

plot(rowt, the.depths
     ,axes=F
     ,ylab="",xlab=""
     ,col = "white"
     # ,xaxs="i" 
     ,ylim=c(max(the.depths),min(the.depths))
     # ,xlim=c(min(axis.sequence),max(axis.sequence))
     ,xlim=c(0 ,max(rowt))
     ,xpd=F
     )

lines(rowt, row1[2:length(row1)],col="navy")
axis(2,cex=axis.label.size)
axis(3,cex=axis.label.size, line = 1, lwd= 0, tck=F) # The labels
axis(3     ,tck=T     ,tcl=-0.5     ,line = 0
     ,col.axis="white"     ,cex.axis=1     ,cex=0.1     ) # The ticks
threetext<-expression("Concentration at final time (mmol L "^-1*")")
mtext(3,text=threetext,cex=axis.label.size,line=2,col="navy")
par(xpd=F)
box(bty="o")

left.axis.text<-expression("Depth (cm)")
mtext(2,text=left.axis.text,cex=axis.label.size,line=2) # 1=bottom, 2=left, 3=top, 4=right
