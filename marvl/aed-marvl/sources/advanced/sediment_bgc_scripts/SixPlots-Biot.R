for(zz in 1:length(zones)){
  if(nchar(zones)==1){longzones<-paste0("0000",zones)} # Load sed data}
  if(nchar(zones)==2){longzones<-paste0("000" ,zones)} # Load sed data}
  if(nchar(zones)==3){longzones<-paste0("00"  ,zones)} # Load sed data}
}
depfi<-(paste0(folder,longzones,"/","Depths.sed"))
depfile.1<-as.matrix(read.table(file=depfi, header=FALSE, skip=0))
rownames(depfile.1)<-gsub("&","",depfile.1[,1])
depfile.2<-data.frame(t(depfile.1[,2:dim(depfile.1)[2]]))

Depcols<-list(
 depfile.2$Depths
,depfile.2$Porosity
,depfile.2$Irrigation
,depfile.2$Bioturbation
,depfile.2$Layer_size_cm
,depfile.2$Thick_cm
,depfile.2$Porewater_m3_per_m2
,depfile.2$Solids_m3_per_m2
)

Depvar=c( "Depths"
          ,"Porosity"
          ,"Irrigation"
          ,"Bioturbation"
          ,"Layer_size_cm"
          ,"Thick_cm"
          ,"Porewater_m3_per_m2"
          ,"Solids_m3_per_m2")

names(Depcols)<-names(depfile.2)
plot(Depcols$Bioturbation,Depcols$Depths
     ,ylim=c(max(as.numeric(Depcols$Depths)),min(as.numeric(Depcols$Depths)))
     ,type="n"
     ,axes=F , xlab="", ylab=""
     ) 
box(bty="o")
lines(Depcols$Bioturbation,Depcols$Depths,col="navy")
axis(2,cex=axis.label.size)
mtext(3,text="Bioturbation",cex=axis.label.size,line=2,col="navy")

axis(3,cex=axis.label.size, line = 1, lwd= 0, tck=F) # The labels
axis(3     ,tck=T     ,tcl=-0.5     ,line = 0
     ,col.axis="white"     ,cex.axis=1     ,cex=0.1     ) # The ticks
par(new=T)
plot(Depcols$Irrigation,Depcols$Depths
     ,ylim=c(max(as.numeric(Depcols$Depths)),min(as.numeric(Depcols$Depths)))
     ,type="n"
     ,axes=F , xlab="", ylab=""
)
axis(1,cex=axis.label.size)
lines(Depcols$Irrigation,Depcols$Depths,col="red4")
mtext(2,text=expression("Depth (cm)"),cex=axis.label.size,line=2)
mtext(1,text="Irrigation",cex=axis.label.size,line=2,col="red4")

legend("bottomright",inset=0.1,legend = c("Bioturbation","Irrigation")
       ,col=c("navy","red4")
       ,pch=16
       ,cex=axis.label.size)