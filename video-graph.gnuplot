#!/usr/bin/gnuplot 
#set term qt size 800,600
f(x)=af*x+bf
set border 15;
set xtics mirror
set grid x;
set grid lw 1
set lmargin 10
USNG="($1/1000):($2/1000)"
i=1
if (strlen(preload) !=0 ) { load preload; }
CONF="w p pt 7 ps 0.1 lc rgb 'gray70' not";
CONF2="w lp pt 7 ps 0.4 lw 0.2 lc rgb 'gray10' not"
CONFRED="w p pt 7 ps 0 lc rgb 'white' not"
if (reddot=="1") {CONFRED="w p pt 7 ps 1.5 lc rgb 'red' not"}
#infile="4500nm 03 DC.txt"
if (strlen(infile) == 0) { print "No input file specified. Exiting..."; exit; }
if (strlen(tit) == 0) { tit=infile; print "No title specified. Setting to '".tit."'"; }
if (strlen(delay) == 0) { delay=0 }
#print sprintf("Starting plot generation...\nInput file name = \"%s\"\nPlot title = \"%s\"\nStep = %d",infile, tit, stepp)

#infile_f=".infile.tmp"
stats infile_f u 1 nooutput
maxidx = 1+floor(STATS_records/stepp)*stepp
j=0
prevtime = 0
timenow = 0
do for [i=1+stepp:maxidx:stepp] {
    j=j+1;
    if (verbose=="1") {set term wxt size 800,600; }
    if (i+stepp>=maxidx) {set term pngcairo size 800,600; set output sprintf('%s/%s.png',video_f,infile);}
    set tics scale 1;
    set tics font ",12"
    set xlabel "Displacement, {/Symbol m}m" font ",14";
    set ylabel "Load,mN" font ",14";
    set mxtics;
    set mytics;
    ##set title "Beam: L=40.231um, W=5.068um, T=2.386um" font ",14";
    set title tit font ",14";
    set size 1,1;
    set origin 0,0;
    stats infile_f every ::1::i u ($3+delay) nooutput
    prevtime = timenow
    timenow = STATS_max
    if (strlen(preload) !=0 ) { load preload; }
    set style rect fc rgb "white" fs solid 1 noborder
    set label 1 sprintf("Test time: %.6f sec", timenow) at screen 0, screen 0 offset character 1, character 1 font ",12"
    if (verbose=="1") {plot infile_f u @USNG every (ceil(i/1E4))::1::i @CONF2, infile_f u @USNG every (ceil(i/1E4))::i::i @CONFRED;}
    if (i+stepp>=maxidx) {plot infile_f u @USNG @CONF2;}
    set term pngcairo size 800,600;
    set output sprintf('%s/%s-%06.0f.png',video_f,infile,j);
    system(sprintf("echo -e \"file '%s-%06.0f.png'\\nduration %f\" >> \"%s/list.txt\"",infile,j,(timenow-prevtime),video_f)) #duration is in micro sec
    message=i*(i+1)*100.0/maxidx/(maxidx+1);
    system(sprintf("echo -ne \"\\r\\e[1mGenerating plots...\\e[0m %.2f%%\"",message))
    set multiplot;
    set object 1 rect from screen 0.15, screen 0.58 to screen 0.47,screen 0.88
    plot infile_f u @USNG every ::1::i @CONF2, infile_f u @USNG every ::i::i @CONFRED;
    unset object 1;
    unset object 2;
    unset label 1;
    set tics scale 0;
    set tics font ",6"
    unset xlabel;
    unset ylabel;
    unset mxtics;
    unset mytics;
    unset title;
    set size  0.4,0.4;
    set origin 0.1,0.5;
    af=1;bf=1E-1;
    set autoscale
    if (i>3) {fit f(x) infile_f u @USNG every ::(i-10*stepp)::i via af,bf;}
    set label 2 sprintf("Slope: %.6f", af) at graph 0, graph 1 offset character 1, character -1 font ",8"
    if (mini=="1") {plot infile_f u @USNG every ::(i-10*stepp)::i @CONF;}
    unset label 2
    unset multiplot
}
#extra file according to http://trac.ffmpeg.org/wiki/Slideshow
system(sprintf("echo \"file '%s-%06.0f.png'\" >> \"%s/list.txt\"",infile,j,video_f))

system("rm fit.log")
