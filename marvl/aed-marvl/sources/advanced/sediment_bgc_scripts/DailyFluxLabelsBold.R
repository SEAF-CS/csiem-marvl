# dailyfluxlabels<-function(thisfile){
  label=as.character()
  thisfile = files[i]
  if(thisfile=="oxy")       {label.bold=expression(bold("O"[2]*" (mmol m"^-2*" d"^-1*")")           );factor=1}
  if(thisfile=="so4")       {label.bold=expression(bold("SO"[4]^"2-"*" (mmol m"^-2*" d"^-1*")")     );factor=1}
  if(thisfile=="frp")       {label.bold=expression(bold("PO"[4]^"3-"*" (mmol m"^-2*" d"^-1*")")     );factor=1}
  if(thisfile=="amm")       {label.bold=expression(bold("NH"[4]^"+"*" (mmol m"^-2*" d"^-1*")")      );factor=1}
  if(thisfile=="ch4")       {label.bold=expression(bold("CH"[4]*" (mmol m"^-2*" d"^-1*")")          );factor=1}
  if(thisfile=="dic")       {label.bold=expression(bold("DIC (mmol m"^-2*" d"^-1*")")               );factor=1}
  if(thisfile=="h2s")       {label.bold=expression(bold("H"[2]*"S (mmol m"^-2*" d"^-1*")")          );factor=1}
  if(thisfile=="pomspecial"){label.bold=expression(bold("Organic matter (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="pin")       {label.bold=expression(bold("PIN (mmol m"^-2*" d"^-1*")")               );factor=1}
  if(thisfile=="nit")       {label.bold=expression(bold("NO"[3]^"-"*" (mmol m"^-2*" d"^-1*")")      );factor=1}
  if(thisfile=="feoh3a")    {label.bold=expression(bold("Fe(OH)"["3A"]*" (mmol m"^-2*" d"^-1*")")   );factor=1}
  if(thisfile=="feoh3b")    {label.bold=expression(bold("Fe(OH)"["3B"]*" (mmol m"^-2*" d"^-1*")")   );factor=1}
  if(thisfile=="pip")       {label.bold=expression(bold("PIP (mmol m"^-2*" m"^-2*" d"^-1*")")       );factor=1}
  if(thisfile=="feii")      {label.bold=expression(bold("Fe"^"2+"*" (mmol m"^-2*" m"^-2*" d"^-1*")"));factor=1}
  if(thisfile=="mnii")      {label.bold=expression(bold("Mn"^"2+"*" (mmol m"^-2*" m"^-2*" d"^-1*")"));factor=1}
  if(thisfile=="mno2a")     {label.bold=expression(bold("MnO"["2A"]*" (mmol m"^-2*" d"^-1*")")      );factor=1}
  if(thisfile=="mno2b")     {label.bold=expression(bold("MnO"["2B"]*" (mmol m"^-2*" d"^-1*")")      );factor=1}
  if(thisfile=="n2")        {label.bold=expression(bold("N"["2"]*" (mmol m"^-2*" d"^-1*")")         );factor=1}
  if(thisfile=="n2o")       {label.bold=expression(bold("N"["2"]*"O (mmol m"^-2*" d"^-1*")")        );factor=1}
  if(thisfile=="no2")       {label.bold=expression(bold("NO"["2"]*" (mmol m"^-2*" d"^-1*")")        );factor=1}
  if(thisfile=="so4")       {label.bold=expression(bold("SO"[4]^"2-"*" (mmol m"^-2*" d"^-1*")")     );factor=1}
  if(thisfile=="poml")      {label.bold=expression(bold("Labile POM (mmol m"^-2*" d"^-1*")")        );factor=1}#(1e3/1e4)}
  if(thisfile=="pomr")      {label.bold=expression(bold("Refractord POM (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="dopr")      {label.bold=expression(bold("Refractory DOP (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="pocr")      {label.bold=expression(bold("Refractory POC (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="pocl")      {label.bold=expression(bold("Labile POC (mmol m"^-2*" d"^-1*")")        );factor=1}#(1e3/1e4)}
  if(thisfile=="docr")      {label.bold=expression(bold("Refractory DOC (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="docl")      {label.bold=expression(bold("Labile DOC (mmol m"^-2*" d"^-1*")")        );factor=1}#(1e3/1e4)}
  if(thisfile=="ponl")      {label.bold=expression(bold("Labile PON (mmol m"^-2*" d"^-1*")")        );factor=1}#(1e3/1e4)}
  if(thisfile=="ponr")      {label.bold=expression(bold("Refractory PON (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="donl")      {label.bold=expression(bold("Labile DON (mmol m"^-2*" d"^-1*")")        );factor=1}#(1e3/1e4)}
  if(thisfile=="donr")      {label.bold=expression(bold("Refractory DON (mmol m"^-2*" d"^-1*")")    );factor=1}#(1e3/1e4)}
  if(thisfile=="fes")       {label.bold=expression(bold("FeS (mmol m"^-2*" d"^-1*")")               );factor=1}#(1e3/1e4)}
  if(thisfile=="salt")      {label.bold=expression(bold("Salinity (PSU m"^-2*" d"^-1*")")           );factor=1}#(1e3/1e4)}
  # label<<-label
# }
