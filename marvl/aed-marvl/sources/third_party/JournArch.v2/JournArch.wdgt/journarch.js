var gDoneButton;
var gInfoButton;
var gGETButton;
var gmyURLButton;
var gDOIButton;
var gGOOButton;
var gAMSButton;
var gAGUButton;
var gEGSButton;
  
function setup()
{
  gDoneButton = new AppleGlassButton(document.getElementById("doneButton"), 
         "Done", hidePrefs);
  gInfoButton = new AppleInfoButton(document.getElementById("infoButton"), 
         document.getElementById("front"), "white", "white", showPrefs);
  gInfoButton.setStyle("black","black");
  //gDoneButton.setStyle("black","black");

  gGETButton = new AppleGlassButton(
        document.getElementById("getarch"),
        "Click to access the archive",
        getPAPERarchive);
  gGETButton.textElement.style.fontSize = "12px";
  gGETButton.textElement.style.fontFamily = "Lucida Grande";
  gGETButton.textElement.style.color = "black";
  gGETButton.textElement.style.fontWeight = "bold";

  gmyURLButton = new AppleGlassButton(
        document.getElementById("myurl"),
	"Widget Website",
         goHOME);
  gmyURLButton.textElement.style.fontSize = "12px";
  gmyURLButton.textElement.style.fontFamily = "Lucida Grande";
  gmyURLButton.textElement.style.color = "white";
  gmyURLButton.textElement.style.fontWeight = "bold"; 

  gDOIButton = new AppleGlassButton(
        document.getElementById("getdoi"),
	"DOI",
	searchDOI);
  gDOIButton.textElement.style.fontSize = "12px";
  gDOIButton.textElement.style.fontFamily = "Lucida Grande";
  gDOIButton.textElement.style.color = "black";
  gDOIButton.textElement.style.fontWeight = "bold"; 

  gGOOButton = new AppleGlassButton(
        document.getElementById("getgoo"),
	"Google Scholar",
        searchGOO);
  gGOOButton.textElement.style.fontSize = "12px";
  gGOOButton.textElement.style.fontFamily = "Lucida Grande";
  gGOOButton.textElement.style.color = "black";
  gGOOButton.textElement.style.fontWeight = "bold"; 

  gAMSButton = new AppleGlassButton(
        document.getElementById("getams"),
	"AMS",
        searchAMS);
  gAMSButton.textElement.style.fontSize = "12px";
  gAMSButton.textElement.style.fontFamily = "Lucida Grande";
  gAMSButton.textElement.style.color = "black";
  gAMSButton.textElement.style.fontWeight = "bold"; 

  gAGUButton = new AppleGlassButton(
        document.getElementById("getagu"),
	"AGU",
        searchAGU);
  gAGUButton.textElement.style.fontSize = "12px";
  gAGUButton.textElement.style.fontFamily = "Lucida Grande";
  gAGUButton.textElement.style.color = "black";
  gAGUButton.textElement.style.fontWeight = "bold"; 

  gEGSButton = new AppleGlassButton(
        document.getElementById("getegs"),
	"EGS",
        searchEGS);
  gEGSButton.textElement.style.fontSize = "12px";
  gEGSButton.textElement.style.fontFamily = "Lucida Grande";
  gEGSButton.textElement.style.color = "black";
  gEGSButton.textElement.style.fontWeight = "bold"; 

}

function showPrefs()
{
    var front = document.getElementById("front");
    var back  = document.getElementById("back");
    if (window.widget)
        widget.prepareForTransition("ToBack");
    front.style.display="none";
    back.style.display="block";
    if (window.widget)
        setTimeout ('widget.performTransition();', 0);
}

function showSEARCH()
{
    var front = document.getElementById("frontsearch");
    front.style.display="block";
}
function hideSEARCH()
{
    var front = document.getElementById("frontsearch");
    front.style.display="none";
}

function hidePrefs()
{
    var front = document.getElementById("front");
    var back  = document.getElementById("back");
    if (window.widget)
        widget.prepareForTransition("ToFront");
    back.style.display="none";
    front.style.display="block";
    if (window.widget)
        setTimeout ('widget.performTransition();', 0);
}


function getPAPERarchive(){
journal=document.archive.paper.options[document.archive.paper.selectedIndex].value;
annee=document.archive.year.options[document.archive.year.selectedIndex].value;
switch (journal){
 case 'bams':inst='AMS';   var vol=annee-1919;issn='1520-0477';break;
 case 'jclim': inst='AMS'; var vol=annee-1987;issn='1520-0442';break;
 case 'jas': inst='AMS';   var vol=annee-1943;issn='1520-0469';break;
 case 'jpo': inst='AMS';   var vol=annee-1970;issn='1520-0485';break;
 case 'mwr': inst='AMS';   var vol=annee-1872;issn='1520-0493';break;

 case 'grl':inst='AGU';    var journ='gl';break;
 case 'jgratm':inst='AGU'; var journ='jd';break;
 case 'jgroc':inst='AGU';  var journ='jc';break;
 case 'rg':inst='AGU';     var journ='rg';break;

 case 'nlpg':inst='EGS';break;
}
switch (inst){
  case 'AMS':
    var url='http://ams.allenpress.com/amsonline/?request=get-author-index&issn='+issn+'&volume='+vol;break;
  case 'AGU':
    var url='http://www.agu.org/pubs/back/'+journ;break;
    break;
  case 'EGS':
    var url='http://www.copernicus.org/EGU/npg/published_papers.html';break;
  }
        if (widget)
        {
            widget.openURL(url);
        }
}

function searchDOI()
{
        var value = document.getElementById("searchinput").value;
        if (value.length > 0)
        {
                value = encodeURIComponent (value);
		var url = "http://dx.doi.org/" + value;
                if (widget) {
                        widget.openURL (url);
}}}
function searchGOO()
{
        var value = document.getElementById("searchinput").value;
        if (value.length > 0)
        {
                value = encodeURIComponent (value);
                var url = "http://scholar.google.com/scholar?q=" + value ;
                if (widget) {
                        widget.openURL (url);
}}}
function searchAMS()
{
        var value = document.getElementById("searchinput").value;
        if (value.length > 0)
        {
                value = encodeURIComponent (value);
                var url = "http://ams.allenpress.com/perlserv/?anywhere=" + value + "&x=0&y=0&anywhere_boolean=ALL&issn=ALL&total_hits=0&request=search-simple&searchtype=simple&hits_per_page=10&previous_hit=0&sort=relevance#results";
                if (widget) {
                        widget.openURL (url);
}}}

function searchAGU()
{
        var value = document.getElementById("searchinput").value;
        if (value.length > 0)
        {
                value = encodeURIComponent (value);
                var url = "http://www.googlesyndicatedsearch.com/u/agu1?ie=UTF-8&oe=UTF-8&q=" + value + "&btnG=Search";
                if (widget) {
                        widget.openURL (url);
}}}


function searchEGS()
{
        var value = document.getElementById("searchinput").value;
        if (value.length > 0)
        {
                value = encodeURIComponent (value);
                var url = "http://search.nonlin-processes-geophys.net/search?q="+value+"&restrict=&btnG=Search&client=CopernicusLibrary&output=xml_no_dtd&proxystylesheet=CopernicusLibrary&site=CopernicusLibrary&oe=utf8";
                if (widget) {
                        widget.openURL (url);
}}}
function goHOME()
{
    var url = "http://scripts.mit.edu/~gmaze/blog/index.php?page_id=629";
    if (widget) {
        widget.openURL (url);
}}




var growboxInset;
function mouseDown(event)
{
    document.addEventListener("mousemove", mouseMove, true);
    document.addEventListener("mouseup", mouseUp, true);
    growboxInset = {x:(window.innerWidth - event.x), y:(window.innerHeight - event.y)};
    event.stopPropagation();
    event.preventDefault();
}
function mouseMove(event)
{
    var x = event.x + growboxInset.x;
    var y = event.y + growboxInset.y;
    document.getElementById("resize").style.top = (y-12);
    window.resizeTo(x,y);
    event.stopPropagation();
    event.preventDefault();
}
function mouseUp(event)
{
    document.removeEventListener("mousemove", mouseMove, true);
    document.removeEventListener("mouseup", mouseUp, true);
    event.stopPropagation();
    event.preventDefault();
}