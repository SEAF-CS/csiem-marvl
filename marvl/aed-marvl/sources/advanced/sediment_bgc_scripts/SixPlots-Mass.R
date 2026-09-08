desired.depths = c(5,10)
source("ConcLabels.R")
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

# Keep this.
ifelse( max(uno) < start.time ,time.start.index<-which.max(uno) ,time.start.index<-which.min(abs(uno - start.time)))
# Comment this out to keep the `time.stop.index` the same as in the tF script #
# ifelse( max(uno) < stop.time  ,time.stop.index <-which.max(uno)  ,time.stop.index <-which.min(abs(uno - stop.time )))
# Comment this out to keep the `time.stop.index` the same as in the tF script #


# time<-as.matrix(file[1:which.max(file[,1]),1])/1#365.25 # Adjust this to change time unit
time<-as.matrix(uno[time.start.index:time.stop.index])/1#365.25 # Adjust this to change time unit

ifelse( max(eins) < desired.depth ,depthindex<-length(eins)-1,depthindex<-which.min(abs(eins - desired.depth)))
ifelse( max(eins) < desired.depths[1] ,depthindex.1<-length(eins),depthindex.1<-which.min(abs(eins - desired.depths[1])))
ifelse( max(eins) < desired.depths[2] ,depthindex.2<-length(eins),depthindex.2<-which.min(abs(eins - desired.depths[2])))
                                       depthindex.3<-length(eins)

row1<-as.matrix(     file[1,1:depthindex  ]    )            #layernum]) # Top row
con <-as.matrix( file [1+time.start.index :time.stop.index  ,  2:depthindex  ] ) # Concentration matrix
# mol<-con*as.numeric((depfile.2$Porewater_m3_per_m2[2:depthindex]))*1000 # mmol/L × m3 × 1000 matrix 
# mol<-con*as.numeric(as.matrix(depfile.2$Porewater_m3_per_m2[2:depthindex]))*1000 # mmol/L × m3 × 1000 matrix 
# porewatervolume=(as.matrix(as.numeric(depfile.2$Porewater_m3_per_m2[2:depthindex])))
porewatervolume=as.numeric(depfile.2$Porewater_m3_per_m2[2:depthindex])
solidsvolume   =as.numeric(depfile.2$Solids_m3_per_m2[2:depthindex])
thickness      =as.numeric(depfile.2$Thick_cm[2:depthindex])
thedepths      =as.numeric(depfile.2$Depths[2:depthindex])
      
# mol<-con*as.numeric((depfile.2$Porewater_m3_per_m2[2:depthindex]))*1000 # mmol/L × m3 × 1000 matrix 

dim(con)
dim(porewatervolume)
length(porewatervolume)
# mol<-con*porewatervolume #
if(issolid==F){
  # print("Solute")
mmol<-sweep(x=con, MARGIN = 2, STATS = porewatervolume, FUN="*")*1000 # mmol [ ] / L × m3 water / m2 space
}
# mmol in mmol [] / m2

# if(issolid==T){mol<-con*as.numeric(depfile.2$Solids_m3_per_m2[2:depthindex])*1000} # mol solids
if(issolid==T){
  # print("Solid")
  mmol<-sweep(x=con,MARGIN=2,STATS=solidsvolume,FUN="*")*1000
                mol<-mmol/1000} # mmol solids / m2
mol<-mmol/1000 # mol / m2

mas<-mol*mmass # g / m2
mas.top<-as.matrix( mas [,  2  ] )*0.5 # Concentration matrix
# matt.top = as.matrix( mas [,  2:3  ] )*0.5*(as.numeric(depfile.2$Depths[3])-as.numeric(depfile.2$Depths[2] ))
mas.1  <-as.matrix( mas [,  1:depthindex.1  ] ) # Concentration matrix
mas.2  <-as.matrix( mas [,  (depthindex.1 + 1):depthindex.2 ] ) # Concentration matrix
mas.3  <-as.matrix( mas [,  (depthindex.2 + 1):dim(mas)[2]  ] ) # Concentration matrix

timey<-as.vector(t(time)) #  Transpose time #
time.s<-timey[seq(from=1,to=length(timey),by=subsample)]
datey<-as.Date(time.s,origin = startdate)

mas.1.sum<-rowSums(x=mas.1,na.rm = T)
mas.2.sum<-rowSums(x=mas.2,na.rm = T)
mas.3.sum<-rowSums(x=mas.3,na.rm = T)
mas.sum  <-rowSums(x=mas  ,na.rm = T)
ifelse( abs(max(timey,na.rm=T))>1
        ,roundx   <- 10^floor(log10(abs(max(timey,na.rm=T))) )/10
        ,roundx   <- 10^floor(log10(abs(min(timey,na.rm=T))) )/10
);roundx
ifelse( abs(max(mas.1.sum,na.rm=T))>0
        ,roundy   <- 10^floor(log10(abs(max(mas.1.sum,na.rm=T))) )/10
        ,roundy   <- 10^floor(log10(abs(min(mas.1.sum,na.rm=T))) )/10
);roundy
ifelse( abs(max(flux.cumul,na.rm=T))>1
        ,roundy.2 <- 10^floor(log10(abs(max(flux.cumul[3:length(flux.cumul)],na.rm=T))) )/10
        ,roundy.2 <- 10^floor(log10(abs(min(flux.cumul[3:length(flux.cumul)],na.rm=T))) )/10
);roundy.2

axis.sequence        = round_any(seq(min(timey,na.rm = T),max(timey,na.rm = T)
                                     ,length.out=tick.master.x),roundx,f=floor);axis.sequence
date.axis.sequence.1 = as.Date(axis.sequence,origin = startdate);date.axis.sequence.1
date.axis.sequence.2 = format(date.axis.sequence.1, sep="/", format = "%b-%Y");date.axis.sequence.2
# y.axis.sequence      = round_any(seq(from=0,to=max(mas.sum),length.out=tick.master.y),roundy,f=floor);y.axis.sequence
y.axis.sequence      = round_any(seq(from=0,to=max(mas.sum, na.rm = T),length.out=tick.master.y),roundy,f=floor);y.axis.sequence
# y.axis.sequence.2    = round_any(seq(from = min(flux.cumul[3:length(flux.cumul)])
y.axis.sequence.2    = round_any(seq(from = min(flux.cumul[3:length(flux.cumul)],
                                                bot.cumul, na.rm = T)
                                     ,to  = max(flux.cumul[3:length(flux.cumul)],
                                                bot.cumul, na.rm = T)
                                     ,length.out=tick.master.y)
                                 ,roundy.2,f=floor);y.axis.sequence.2
if(anyNA(y.axis.sequence.2)){y.axis.sequence.2=0}

plot(timey, mas.1.sum
     ,axes=F
     ,ylab="",xlab=""
     ,col = "white"
     # ,type = "h"
     # ,ylim=c(0,max(mas.1.sum))
     ,ylim=c(0,max(mas.sum))
     ,xaxs="i" 
     # ,yaxs="i"
     ,xlim=c(min(axis.sequence),max(axis.sequence))
     ,xpd=F
     )
mass.colours  <-c("antiquewhite","wheat","burlywood4","grey40")
legend.text <-c(
                paste0("SWI to ",desired.depths[1]," cm")
                ,paste0(desired.depths[1]," cm to ",desired.depths[2]," cm")
                ,paste0(desired.depths[2]," cm to bottom")
                )
par(xpd=F)
 points(timey, mas.sum                     ,type="h",col=mass.colours[1]
         ,lwd=10,lend="butt"
 )

 points(timey,(mas.1.sum+mas.2.sum+mas.3.sum),type="h",xaxs="i",col=mass.colours[2]
         ,lwd=2,lend="butt"
 )
          # points(timey,(mas.1.sum),type="h",xaxs="i"
          #        ,col=mass.colours[2]
          #         ,lwd=2,lend="butt"
          # )
 points(timey,(mas.2.sum+mas.3.sum)          ,type="h",col=mass.colours[3]
       # points(timey,(mas.2.sum)          ,type="h",col=mass.colours[3]
         ,lwd=10,lend="butt"
 )
 points(timey, mas.3.sum                     ,type="h",col=mass.colours[4]
         ,lwd=10,lend="butt"
 )
box(bty="o")
left.axis.text<-expression("Mass (g m "^-2*")")
mtext(2,text=left.axis.text,cex=axis.label.size,line=3.7) # 1=bottom, 2=left, 3=top, 4=right
axis(2,cex.axis=0.7,cex.lab=1.0,tck=T,tcl=-0.2,line=0,tck=T,tcl=-0.3,col.axis="white",at=y.axis.sequence)# Ticks
axis(2,cex.axis=axis.tick.size,cex.lab=1.0,tck=F,tcl=-0.2,line=0.5,lwd=0,at=y.axis.sequence,las=1)# Labels

axis(3,tck=T,tcl=-0.3,xaxs="i",yaxs="i",line=0,col.axis="white"
     ,at=axis.sequence
) # The ticks
axis(3,cex.axis=axis.tick.size,xaxs="i",yaxs="i",line=0.5,lwd = 0 
     ,at=axis.sequence
) # The labels

axis(1,tck=T,tcl=-0.3,xaxs="i",yaxs="i",line=0,col.axis="white"
     ,at=axis.sequence
) # The ticks
axis(1,cex.axis=axis.tick.size,xaxs="i",yaxs="i",line=0.50,lwd = 0 
     ,at=axis.sequence
     ,labels=date.axis.sequence.2 
) # The labels

# # # # # # # # # # # # # # # # # # # # # # # # # # 
# Cumulative plot. Turn it on or off VVV

      # par(new=T)
      # 
      # plot(times, flux.cumul
      #        ,pch=16
      #        ,lwd=2
      #        ,cex=0.5
      #        ,type="n" 
      #        ,axes=F
      #        ,xlab="",ylab=""
      #        ,xlim=c(min(axis.sequence),max(axis.sequence))
      #        ,ylim=c(min(flux.cumul,bot.cumul),max(flux.cumul,bot.cumul))
      #        ,xaxs="i" 
      #      # ,yaxs="i"
      # )
      # cumul.colours <- c("red4","navyblue")
      # lines (times, flux.cumul,col=cumul.colours[1])
      # lines (times, bot.cumul[1:length(times)],col=cumul.colours[2])
      # length(timey)
      # length(times)
      # length(flux.cumul)
      # # points(timey, flux.cumul,col=cumul.colours)####################
      # cumul.leg.text<- c("Cumulative SWI mass","Cumulative bottom mass")
      # 
      # axis(4,cex.axis=0.7,cex.lab=1.0,tck=T,tcl=-0.2,line=0
      #      ,tck=T,tcl=-0.3,col.axis="white",at=y.axis.sequence.2)# Ticks
      # axis(4,cex.axis=axis.tick.size,cex.lab=1.0,tck=F,tcl=-0.2,line=0.5
      #      ,lwd=0,at=y.axis.sequence.2,las=1)# Labels
      # flux.cumul.unit.text = expression("Cumulative flux (g m "^"-2"*")")
      # # flux.cumul.unit.text = expression("(g m"^"-2"*")")
      # # mtext(4,text="Cumulative flux",cex=axis.label.size,line=4.0) # 1=bottom, 2=left, 3=top, 4=right
      # # mtext(4,text=flux.cumul.unit.text,cex=axis.label.size,line=5.5) # 1=bottom, 2=left, 3=top, 4=right
      # mtext(4,text=flux.cumul.unit.text,cex=axis.label.size,line=5.0) # 1=bottom, 2=left, 3=top, 4=right
      # mtext(3,text="Time (number of days)",cex=axis.label.size,line=1.5, adj=0.55)
      # mtext(1,text="Time (date)",cex=axis.label.size,line=1.5, adj=0.55)
# Cumulative plot. Turn it on or off ^^^
# # # # # # # # # # # # # # # # # # # # # # # # # # 

legend( "left"
        , inset=0.05
        # , fill = c(mass.colours[2])
        , fill = c(mass.colours[2:4])
        # , legend = legend.text[1]
        , legend = legend.text
        # , pch = 15
        , bty = "o"
        , cex = axis.label.size*1.0
        , title = "Mass in sediment"
        # , title = "Mass in sediment (left axis)"
)
# legend( "right"
#         , inset  = 0.05
#         # , fill   = cumul.colours
#         , col   = cumul.colours
#         , legend = cumul.leg.text
#         # , pch    = 20
#         , bty    = "o"
#         , cex    = axis.label.size*1.0
#         , lty    = 1
#         , title = "Cumulative mass (right axis)" 
# )
# 
