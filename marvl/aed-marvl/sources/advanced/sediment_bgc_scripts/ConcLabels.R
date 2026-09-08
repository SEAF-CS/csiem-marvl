# makelabels     <- function( thisfile ) {
  # label=NULL
  # label=as.character()
  thisfile <- files[i]
  top=3
  if(thisfile=="amm")        {the.label=expression("NH"[4]^"+"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(14+1*4)}
  if(thisfile=="ca")         {the.label=expression("Calcium"^"2+"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=40}
  if(thisfile=="ch4")        {the.label=expression("CH"[4]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12+4*1)} 
  if(thisfile=="caco3")      {the.label=expression("CaCO"[3]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(40+12+16*3)}
  if(thisfile=="chla")       {the.label=expression("Chl-a (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="dic")        {the.label=expression("DIC (mmol L"^-1*") porewater"); issolid=F; mmass=(12+16*3)}
  if(thisfile=="ponl")       {the.label=expression("PON"[L]*" (mmol L"^-1*" solids)"); issolid=F; mmass=(12)}
  if(thisfile=="docl")       {the.label=expression("DOC"[L]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="donl")       {the.label=expression("DON"[L]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="docr")       {the.label=expression("DOC"[R]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="dopl")       {the.label=expression("DOP"[L]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="donr")       {the.label=expression("DON"[R]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="dopr")       {the.label=expression("DOP"[R]*" (mmol L"^-1*") porewater"); issolid=F; mmass=(12)}
  if(thisfile=="feii")       {the.label=expression("Fe"^"2+"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(56)}
  if(thisfile=="feiii")      {the.label=expression("Fe"^"3+"*" (mmol L"^-1*") porewater"); issolid=F; mmass=(56)}
  if(thisfile=="feoh3a")     {the.label=expression("Fe(OH)"["3A"]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(56+(16+1)*3)}
  if(thisfile=="feoh3b")     {the.label=expression("Fe(OH)"["3B"]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(56+(16+1)*3)}
  if(thisfile=="feco3")      {the.label=expression("FeCO"["3"]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(56+12+16*3)}
  if(thisfile=="fes")        {the.label=expression("FeS"*" (mmol L"^-1*" solids)"); issolid=T; mmass=(56+32)}
  if(thisfile=="fes2")       {the.label=expression("FeS"[2]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(56+32*2)}
  if(thisfile=="frp")        {the.label=expression("PO"[4]^"3-"*" (mmol L"^-1*") porewater"); issolid=F; mmass=(31+16*4)}
  if(thisfile=="h2s")        {the.label=expression("H"[2]*"S (mmol L"^-1*") porewater"); issolid=F; mmass=(1*2+32)}
  if(thisfile=="mnii")       {the.label=expression("Mn"^"2+"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(55)}
  if(thisfile=="mniv")       {the.label=expression("Mn"^"4+"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(55)}
  if(thisfile=="mnco3")      {the.label=expression("MnCO"[3]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(55+12+16*3)}
  if(thisfile=="mno2a")      {the.label=expression("MnO"["2A"]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(55+16*2)}
  if(thisfile=="mno2b")      {the.label=expression("MnO"["2B"]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(55+16*2)}
  if(thisfile=="nit")        {the.label=expression("NO"[3]^"-"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(14+16*3)}
  if(thisfile=="oxy")        {the.label=expression("O"[2]*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(16*2)}
  if(thisfile=="pin")        {the.label=expression("Adsorbed NH"[4]^"+" *" (mmol L"^-1*")"); issolid=T; mmass=(14+1*4)}
  if(thisfile=="pip")        {the.label=expression("Adsorbed PO"[4]^"3-"*" (mmol L"^-1*")"); issolid=T; mmass=(31+16*4)}
  if(thisfile=="pipvr")      {the.label=expression("PIPVR (mmol L"^-1*" solids)"); issolid=T; mmass=(31+16*4)}
  if(thisfile=="poml")       {the.label=expression("POM"[L]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pomr")       {the.label=expression("POM"[R]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pocl")       {the.label=expression("POC"[L]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pocr")       {the.label=expression("POC"[R]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pocs")       {the.label=expression("POC"[S]*" macroalgae C (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pons")       {the.label=expression("PON"[S]*" macroalgae N (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pops")       {the.label=expression("POP"[S]*" macroalgae P (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="mpb")        {the.label=expression("MPB (mmol L"^-1*" solids)"); issolid=F; mmass=(12)}
  if(thisfile=="ponr")       {the.label=expression("PON"[R]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(14)}
  if(thisfile=="popl")       {the.label=expression("POP"[L]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(31)}
  if(thisfile=="popr")       {the.label=expression("POP"[R]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(31)}
  if(thisfile=="so4")        {the.label=expression("SO"[4]^"2-"*" (mmol L"^-1*" porewater)"); issolid=F}
  if(thisfile=="ubalchg")    {the.label=expression("Charge balance"); issolid=F; mmass=(1)}
  if(thisfile=="zn")         {the.label=expression("Zn"^"2+"*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(65)}
  if(thisfile=="pH")         {the.label=expression("pH"); issolid=F; mmass=(1)}
  if(thisfile=="poml")       {the.label=expression("Labile POM (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pomr")       {the.label=expression("Refractory POM (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="pomspecial") {the.label=expression("POM special (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="dfer")       {the.label=expression("DOM"[Fermentation_Products]*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(12)}
  if(thisfile=="dhyd")       {the.label=expression("DOM"[Hydrolysis_Products]*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(12)}
  if(thisfile=="domr")       {the.label=expression("DOM"[Refractory]*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(12)}
  if(thisfile=="pe")         {the.label=expression("pe"); issolid=F; mmass=(1)}
  if(thisfile=="ZnS")        {the.label=expression("ZnS"); issolid=T; mmass=(65+32)}
  if(thisfile=="IAP_CaCO3")  {the.label=expression("IAP CaCO3"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_FeCO3")  {the.label=expression("IAP FeCO3"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_FeOH3A") {the.label=expression("IAP_FeOH3A"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_FeOH3B") {the.label=expression("IAP_FeOH3B"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_FeS")    {the.label=expression("IAP_FeS"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_FeS2")   {the.label=expression("IAP_FeS2"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_MnCO3")  {the.label=expression("IAP MnCO3"); issolid=T; mmass=(1)}
  if(thisfile=="IAP_MnO2A")  {the.label=expression("IAP MnO2A"); issolid=T; mmass=(1)}
  if(thisfile=="BAer")       {the.label=expression("Aerobes (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="BDen")       {the.label=expression("Denitrifiers (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="BFer")       {the.label=expression("Fermenters (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="BIro")       {the.label=expression("Iron reducers (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="BMan")       {the.label=expression("Manganese reducers (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="BMet")       {the.label=expression("Methanogens (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="BSul")       {the.label=expression("Sulfate reducers (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="Btot")       {the.label=expression("B"[tot]); issolid=T; mmass=(12)}
  if(thisfile=="N2")         {the.label=expression("N"[2]*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(14*2)}
  if(thisfile=="H2")         {the.label=expression("H"[2]*" (mmol L"^-1*" porewater)"); issolid=F; mmass=(1*2)}
  if(thisfile=="Necromass")  {the.label=expression("Necromass (mmol L"^-1*")"); issolid=F; mmass=(12)}
  if(thisfile=="OAc")        {the.label=expression("Acetate (mmol L"^-1*" porewater)"); issolid=T; mmass=(12+1*3+12+16+16)}
  if(thisfile=="POM1")       {the.label=expression("POM"[1]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="POM2")       {the.label=expression("POM"[2]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="POM3")       {the.label=expression("POM"[3]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="POM4")       {the.label=expression("POM"[4]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(12)}
  if(thisfile=="Feads")      {the.label=expression("Fe"[Adsorbed]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(56)}
  if(thisfile=="Mnads")      {the.label=expression("Mn"[Adsorbed]*" (mmol L"^-1*" solids)"); issolid=T; mmass=(55)}
  if(thisfile=="FDHyd")      {the.label=expression("F"[D[Hyd]]); issolid=F; mmass=(1)}
  if(thisfile=="FIN_O2")     {the.label=expression("F"[In[O[2]]]); issolid=F; mmass=(1)}
  if(thisfile=="FO2")        {the.label=expression("F"[O[2]]); issolid=F; mmass=(1)}
  if(thisfile=="FTAerOAc")   {the.label=expression("F"[T[AerOAc]]); issolid=F; mmass=(1)}
  if(thisfile=="FTDenH2")    {the.label=expression("F"[T[DenH2]]); issolid=F; mmass=(1)}
  if(thisfile=="FTDenOAc")   {the.label=expression("F"[T[DenOAc]]); issolid=F; mmass=(1)}
  if(thisfile=="FTEA_FeOH")  {the.label=expression("F"[TEA[Fe]]); issolid=F; mmass=(1)}
  if(thisfile=="FTEA_MnO2")  {the.label=expression("F"[TEA[Mn]]); issolid=F; mmass=(1)}
  if(thisfile=="FTEA_NO3")   {the.label=expression("F"[TEA[NO[3]]]); issolid=F; mmass=(1)}
  if(thisfile=="FTEA_O2")    {the.label=expression("F"[TEA[O[2]]]); issolid=F; mmass=(1)}
  if(thisfile=="FTEA_SO4")   {the.label=expression("F"[TEA[SO[4]]]); issolid=F; mmass=(1)}
  if(thisfile=="FTFerDHyd")  {the.label=expression("F"[T[Fermentation]]); issolid=F; mmass=(1)}
  if(thisfile=="FTIroOAc")   {the.label=expression("F"[T[IroOAc]]); issolid=F; mmass=(1)}
  if(thisfile=="FTIroH2")    {the.label=expression("F"[T[IroH[2]]]); issolid=F; mmass=(1)}
  if(thisfile=="FTManOAc")   {the.label=expression("F"[T[ManOAc]]); issolid=F; mmass=(1)}
  if(thisfile=="FTMetH2")    {the.label=expression("F"[T[MetH[2]]]); issolid=F; mmass=(1)}
  if(thisfile=="FTMetOAc")   {the.label=expression("F"[T[MetOAc]]); issolid=F; mmass=(1)}
  if(thisfile=="FTSulOAc")   {the.label=expression("F"[T[SulOAc]]); issolid=F; mmass=(1)}
  if(thisfile=="FTSulH2")    {the.label=expression("F"[T[SulH[2]]]); issolid=F; mmass=(1)}
  if(thisfile=="n2o")        {the.label=expression("N"[2]*  "O (mmol L"^-1*" porewater)")  ; issolid=F; mmass=(14*2+16)}
  if(thisfile=="no2")        {the.label=expression("NO"["2"]*" (mmol L"^-1*" porewater)")  ; issolid=F; mmass=(14+16+2)}
  if(thisfile=="n2")         {the.label=expression("N"[2]*"  (mmol L"^-1*")")  ; issolid=F; mmass=(14*2)}
  if(thisfile=="Salinity")   {the.label=expression("Salinity  (PSU)")  ; issolid=F; mmass=(23+35)}
  if(thisfile=="salinity")   {the.label=expression("Salinity  (PSU)")  ; issolid=F; mmass=(23+35)}
  if(thisfile=="salt")       {the.label=expression("Salinity  (PSU)")  ; issolid=F; mmass=(23+35)}
  if(thisfile=="bioturb")    {the.label=expression("Bioturbation")  ; issolid=F; mmass=(23+35)}
  if(thisfile=="cirrig")     {the.label=expression("Irrigation")  ; issolid=F; mmass=(23+35)}
  if(thisfile=="RNO3")       {the.label=expression("R"[NO3])  ; issolid=F; mmass=(14)}
  if(thisfile=="RNO2")       {the.label=expression("R"[NO2O2])  ; issolid=F; mmass=(14)}
  if(thisfile=="RN2O")       {the.label=expression("R"[N2O])  ; issolid=F; mmass=(14)}
  if(thisfile=="RNH4OX")     {the.label=expression("R"[NH4OX])  ; issolid=F; mmass=(14)}
  if(thisfile=="rnh4no2")    {the.label=expression("R"[NH4NO2])  ; issolid=F; mmass=(14)}
  if(thisfile=="RNO2O2")     {the.label=expression("R"[NO2O2])  ; issolid=F; mmass=(14)}
  if(thisfile=="FSal")       {the.label=expression("FSal")  ; issolid=F; mmass=(1)}
  if(thisfile=="FSul")       {the.label=expression("FSul")  ; issolid=F; mmass=(1)}
  
  the.label<- the.label
  issolid<- issolid
  the.label<<-the.label
  return(the.label)
# ; issolid=F}