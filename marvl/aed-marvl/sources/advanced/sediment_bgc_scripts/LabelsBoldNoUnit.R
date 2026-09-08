# dailyfluxlabels<-function(thisfile){
  label=as.character()
  thisfile = files[i]
  if(thisfile=="oxy")       {label.bold.nounit=expression(bold("O"[2]))}
  if(thisfile=="so4")       {label.bold.nounit=expression(bold("SO"[4]^"2-"))}
  if(thisfile=="frp")       {label.bold.nounit=expression(bold("PO"[4]^"3-"))}
  if(thisfile=="amm")       {label.bold.nounit=expression(bold("NH"[4]^"+"))}
  if(thisfile=="ch4")       {label.bold.nounit=expression(bold("CH"[4]))}
  if(thisfile=="dic")       {label.bold.nounit=expression(bold("DIC" ))}
  if(thisfile=="h2s")       {label.bold.nounit=expression(bold("H"[2]*"S"))}
  if(thisfile=="pomspecial"){label.bold.nounit=expression(bold("Organic matter"))}
  if(thisfile=="pin")       {label.bold.nounit=expression(bold("PIN"))}
  if(thisfile=="nit")       {label.bold.nounit=expression(bold("NO"[3]^"-"))}
  if(thisfile=="feoh3a")    {label.bold.nounit=expression(bold("Fe(OH)"["3A"]))}
  if(thisfile=="feoh3b")    {label.bold.nounit=expression(bold("Fe(OH)"["3B"]))}
  if(thisfile=="pip")       {label.bold.nounit=expression(bold("PIP"))}
  if(thisfile=="feii")      {label.bold.nounit=expression(bold("Fe"^"2+"))}
  if(thisfile=="mnii")      {label.bold.nounit=expression(bold("Mn"^"2+"))}
  if(thisfile=="mno2a")     {label.bold.nounit=expression(bold("MnO"["2A"]))}
  if(thisfile=="mno2b")     {label.bold.nounit=expression(bold("MnO"["2B"]))}
  if(thisfile=="n2")        {label.bold.nounit=expression(bold("N"["2"]))}
  if(thisfile=="n2o")       {label.bold.nounit=expression(bold("N"["2"]*"O"))}
  if(thisfile=="no2")       {label.bold.nounit=expression(bold("NO"["2"]^"-"))}
  if(thisfile=="so4")       {label.bold.nounit=expression(bold("SO"[4]^"2-"))}
  if(thisfile=="poml")      {label.bold.nounit=expression(bold("Labile POM"))}
  if(thisfile=="pomr")      {label.bold.nounit=expression(bold("Refractory POM"))}
  if(thisfile=="dopr")      {label.bold.nounit=expression(bold("Refractory DOP"))}
  if(thisfile=="pocr")      {label.bold.nounit=expression(bold("Refractory POC"))}
  if(thisfile=="pocl")      {label.bold.nounit=expression(bold("Labile POC"))}
  if(thisfile=="docr")      {label.bold.nounit=expression(bold("Refractory DOC"))}
  if(thisfile=="docl")      {label.bold.nounit=expression(bold("Labile DOC"))}
  if(thisfile=="ponl")      {label.bold.nounit=expression(bold("Labile PON"))}
  if(thisfile=="ponr")      {label.bold.nounit=expression(bold("Refractory PON"))}
  if(thisfile=="donl")      {label.bold.nounit=expression(bold("Labile DON"))}
  if(thisfile=="donr")      {label.bold.nounit=expression(bold("Refractory DON"))}
  if(thisfile=="popl")      {label.bold.nounit=expression(bold("Labile POP"))}
  if(thisfile=="popr")      {label.bold.nounit=expression(bold("Refractory POP"))}
  if(thisfile=="dopl")      {label.bold.nounit=expression(bold("Labile DOP"))}
  if(thisfile=="dopr")      {label.bold.nounit=expression(bold("Refractory DOP"))}
  if(thisfile=="fes")       {label.bold.nounit=expression(bold("FeS"))}
  if(thisfile=="fes2")      {label.bold.nounit=expression(bold("FeS"[2]))}
  if(thisfile=="salt")      {label.bold.nounit=expression(bold("Salinity"))}
  # label<<-label
# }
