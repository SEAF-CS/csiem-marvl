# dailyfluxlabels<-function(thisfile){
  label=as.character()
  thisfile = files[i];thisfile
  if(thisfile=="oxy")       {label=expression("O"[2]*" (mmol m"^-2*" d"^-1*")")           ;factor=1}
  if(thisfile=="so4")       {label=expression("SO"[4]^"2-"*" (mmol m"^-2*" d"^-1*")")     ;factor=1}
  if(thisfile=="frp")       {label=expression("PO"[4]^"3-"*" (mmol m"^-2*" d"^-1*")")     ;factor=1}
  if(thisfile=="amm")       {label=expression("NH"[4]^"+"*" (mmol m"^-2*" d"^-1*")")      ;factor=1}
  if(thisfile=="ch4")       {label=expression("CH"[4]*" (mmol m"^-2*" d"^-1*")")          ;factor=1}
  if(thisfile=="dic")       {label=expression("DIC (mmol m"^-2*" d"^-1*")")               ;factor=1}
  if(thisfile=="h2s")       {label=expression("H"[2]*"S (mmol m"^-2*" d"^-1*")")          ;factor=1}
  if(thisfile=="pomspecial"){label=expression("Organic matter (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="pin")       {label=expression("PIN (mmol m"^-2*" d"^-1*")")               ;factor=1}
  if(thisfile=="nit")       {label=expression("NO"[3]^"-"*" (mmol m"^-2*" d"^-1*")")      ;factor=1}
  if(thisfile=="feoh3a")    {label=expression("Fe(OH)"["3A"]*" (mmol m"^-2*" d"^-1*")")   ;factor=1}
  if(thisfile=="feoh3b")    {label=expression("Fe(OH)"["3B"]*" (mmol m"^-2*" d"^-1*")")   ;factor=1}
  if(thisfile=="pip")       {label=expression("PIP (mmol m"^-2*" m"^-2*" d"^-1*")")       ;factor=1}
  if(thisfile=="feii")      {label=expression("Fe"^"2+"*" (mmol m"^-2*" m"^-2*" d"^-1*")");factor=1}
  if(thisfile=="mnii")      {label=expression("Mn"^"2+"*" (mmol m"^-2*" m"^-2*" d"^-1*")");factor=1}
  if(thisfile=="mno2a")     {label=expression("MnO"["2A"]*" (mmol m"^-2*" d"^-1*")")      ;factor=1}
  if(thisfile=="mno2b")     {label=expression("MnO"["2B"]*" (mmol m"^-2*" d"^-1*")")      ;factor=1}
  if(thisfile=="n2")        {label=expression("N"["2"]*" (mmol m"^-2*" d"^-1*")")         ;factor=1}
  if(thisfile=="n2o")       {label=expression("N"["2"]*"O (mmol m"^-2*" d"^-1*")")        ;factor=1}
  if(thisfile=="no2")       {label=expression("NO"["2"]*" (mmol m"^-2*" d"^-1*")")        ;factor=1}
  if(thisfile=="so4")       {label=expression("SO"[4]^"2-"*" (mmol m"^-2*" d"^-1*")")     ;factor=1}
  if(thisfile=="poml")      {label=expression("Labile POM (mmol m"^-2*" d"^-1*")")        ;factor=1}#(1e3/1e4)}
  if(thisfile=="pomr")      {label=expression("Refractord POM (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="dopr")      {label=expression("Refractory DOP (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="pocr")      {label=expression("Refractory POC (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="pocl")      {label=expression("Labile POC (mmol m"^-2*" d"^-1*")")        ;factor=1}#(1e3/1e4)}
  if(thisfile=="docr")      {label=expression("Refractory DOC (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="docl")      {label=expression("Labile DOC (mmol m"^-2*" d"^-1*")")        ;factor=1}#(1e3/1e4)}
  if(thisfile=="ponl")      {label=expression("Labile PON (mmol m"^-2*" d"^-1*")")        ;factor=1}#(1e3/1e4)}
  if(thisfile=="ponr")      {label=expression("Refractory PON (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="donl")      {label=expression("Labile DON (mmol m"^-2*" d"^-1*")")        ;factor=1}#(1e3/1e4)}
  if(thisfile=="donr")      {label=expression("Refractory DON (mmol m"^-2*" d"^-1*")")    ;factor=1}#(1e3/1e4)}
  if(thisfile=="fes")       {label=expression("FeS (mmol m"^-2*" d"^-1*")")               ;factor=1}#(1e3/1e4)}
  if(thisfile=="salt")      {label=expression("Salinity (PSU m"^-2*" d"^-1*")")           ;factor=1}#(1e3/1e4)}
  # label<<-label
# }
