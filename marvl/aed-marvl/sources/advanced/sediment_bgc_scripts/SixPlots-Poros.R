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


plot(Depcols$Porosity,Depcols$Depths
     ,ylim=c(max(as.numeric(Depcols$Depths)),min(as.numeric(Depcols$Depths)))
     ,type="n"
     ,axes=F , xlab="", ylab=""
     ) 
lines(Depcols$Porosity,Depcols$Depths,col="navy")
axis(3,cex=axis.label.size)
axis(2,cex=axis.label.size)
mtext(3,text="Porosity",cex=axis.label.size,line=2,col="navy")
mtext(2,text=expression("Depth (cm)"),cex=axis.label.size,line=2)
box(bty="o")