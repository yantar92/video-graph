#!/bin/bash
function show_help {
    echo -e "\n\e[37m\e[1mMake side by side video of plot and movie.
\e[0m\e[1mUsage\e[0m: `basename $0` [-h|--help] [-t|--title <\"string\">] [-s|--step <number>] [-l|--load <\"path\">] [-v|--video <\"path\">] [--verbose] [--merge] [--skip_plot] [--force] input_file
\t-h|--help: Show help
\t-t|--title: Set plot title. Default: input_file
\t-s|--step: Set number of plot points added per video frame. Default: 100
\t-l|--load: Set gnuplot file to preload 
\t-v|--video: Set video file name. Default: input_file_name.mp4
\t--verbose: Show the last generated plot
\t--merge: Only merge videos. Do not generate images
\t--skip_plot: Skip plot generation
\t--force: overwrite video files without asking
\t--nomini: do not plot mini graph
\t\e[1minput_file: plain text data file, first two columns will be plotted, third column is used as a time to align with video\e[0m"
}

function confirm () {
    # call with a prompt string or use a default
    read -r -p "${1}[y/N] " response
    case $response in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

function del_png {
    echo -n -e "\e[1mDeleting all graph files... \e[0m" && find "$VIDEO_F" -type f -iname "*.png" -delete && echo -e "\e[92m\e[1mdone   \e[0m"
    rm "$VIDEO_F/list.txt"
}

function clean_files {
    rmdir "$VIDEO_F" 2>&1 >/dev/null
    [[ -e "$infile.infile.tmp" ]] && rm "./$infile.infile.tmp"
}

function del_v1 {
    rm "$VIDEO_GRAPH" 2>&1 > /dev/null
}

function del_v2 {
    rm "$VIDEO_SBS" 2>&1 > /dev/null
}

[[ $# == 0 ]] && show_help && exit

TITLE=""
PRELOAD=""
VIDEO=""
stepP=""
infile=""
VERBOSE="0"
MERGE="0"
SKIP_PLOT="0"
OVERWRITE=""
MINI="1"

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
	-h|--help)
	    show_help && exit
	    ;;
	-t|--title)
	    TITLE="$2"
	    shift # past argument
	    ;;
	-l|--load)
	    PRELOAD="$2"
	    [[ ! -e "$PRELOAD" ]] && echo -e "\e[91m\e[1mFatal error:\e[0m File not exists \"$PRELOAD\"\e[0m" && exit 2
	    shift # past argument
	;;
	-v|--video)
	    VIDEO="$2"
	    [[ ! -e "$VIDEO" ]] && echo -e "\e[91m\e[1mFatal error:\e[0m File not exists \"$VIDEO\"\e[0m" && exit 2
	    shift # past argument
	    ;;
	--verbose)
	    VERBOSE="1"
	    ;;
	--merge)
	    MERGE="1"
	    ;;
	--skip_plot)
	    SKIP_PLOT="1"
	    ;;
	-s|--step)
	    stepP="$2"
	    expr $2 - 0 > /dev/null || echo -e "\e[93m\e[1mWarning:\e[0m Problem with step value \"$stepP\". Setting to default value 100\e[0m"
	    expr $2 - 0 > /dev/null || exit 2
	    shift # past argument
	    ;;
	--force)
	    OVERWRITE="-y"
	    ;;
	--nomini)
	    MINI="0"
	    ;;
	*)
	    infile="$key"
	    [[ "$2" == "" ]] || echo -e "\e[93m\e[1mWarning:\e[0m it seems that there are extra arguments provided\e[0m"
	    [[ -e "$infile" ]] && shift $#
	    [[ ! -e "$infile" ]] && [[ "$MERGE" == "0" ]] && echo -e "\e[91m\e[1mFatal error:\e[0m File not exists \"$infile\"" && exit 2
	    ;;
    esac
    shift # past argument or value
done

if [[ "$SKIP_PLOT" == "1" ]]; then
    confirm "Are you sure that you want to skip generation of the graphs (may cause errors)?" || exit 2
fi

TERMINATED=0
VIDEO_F="$(dirname "$infile")/.$(basename "$infile").video.d"

[[ "$TITLE" == "" ]] && TITLE="$(basename "${infile%.*}")"
[[ "$VIDEO" == "" ]] && VIDEO="${infile%.*}.avi"
[[ ! -e "$VIDEO" ]] && echo -e "\e[91m\e[1mFatal error:\e[0m File not exists \"$VIDEO\"\e[0m" && exit 2

VIDEO_GRAPH="`dirname \"$VIDEO\"`/[graph]`basename \"${VIDEO%.*}.mp4\"`"
VIDEO_PNG="`dirname \"$VIDEO\"`/[graph]`basename \"${VIDEO%.*}.png\"`"
VIDEO_SBS="`dirname \"$VIDEO\"`/[s-b-s]`basename \"${VIDEO%.*}.mp4\"`"
echo "video graph: $VIDEO_GRAPH"

clean_files

[[ "$MERGE" == "1" ]] && [[ ! -e "$VIDEO_GRAPH" ]] && echo -e "\e[91m\e[1mFatal error:\e[0m File not exists \"$VIDEO_GRAPH\"\e[0m" && exit 2
if [[ "$MERGE" == "0" ]]; then
    if [[ "$SKIP_PLOT" == "0" ]]; then
	[[ "$infile" == "" ]] && echo -e "\e[91m\e[1mFatal error:\e[0m No input file specified\e[0m" && exit 2
	[[ -d "$VIDEO_F" ]] || mkdir "$VIDEO_F"
    fi
    [[ "$stepP" == "" ]] && stepP=100
#    rate="`echo \"200 / $stepP\" | bc -l`"
    sed '/^\s*$/d' "$infile" > "$infile.infile.tmp"
fi


echo -e "\e[92m\e[1mStarting...\e[0m" && echo -e "  Input file: \"$infile\"\e[0m" && echo -e "  Video: \"$VIDEO\"" && echo -e "  Title: \"$TITLE\"" && echo -e "  Points per step: $stepP" && echo -e "  Preload gnuplot script: \"$PRELOAD\"" 

if [[ "$MERGE" == "0" ]]; then
    if [[ "$SKIP_PLOT" == "0" ]]; then
	echo -n -e "\e[1mGenerating plots... \e[0m"
	gnuplot -e "video_f=\"$VIDEO_F\"; infile_f=\"$(basename "$infile").infile.tmp\"; infile='$(basename "$infile")'; tit='$TITLE'; stepp=$stepP; preload=\"$PRELOAD\"; verbose=\"$VERBOSE\"; mini=\"$MINI\";" ~/bin/video-graph.gnuplot 2>/dev/null || TERMINATED=1
	if [[ "$TERMINATED" == "1" ]]; then
	    echo -e "\r\e[1mGenerating plots...\e[0m \e[1m\e[91mfail \e[0m"
	    confirm "Delete all the generated graphs?" && del_png
	    clean_files
	    echo -e "\e[91m\e[1mTerminated:\e[0m Problem with generating plots\e[0m"
	    exit 2
	fi
	echo -e "\r\e[1mGenerating plots...\e[0m \e[92m\e[1mdone   \e[0m"
    fi
    
    
    echo -e "\e[1mCreating graph video... \e[0m"
    cp "$VIDEO_F/$infile.png" "$VIDEO_PNG"
    #    ffmpeg $OVERWRITE -v error -hide_banner -r $rate -i "$VIDEO_F/$infile-%06d.png" -codec png "$VIDEO_GRAPH" || TERMINATED=1
    ffmpeg $OVERWRITE -safe 0 -v error -hide_banner -f concat -i "$VIDEO_F/list.txt" "$VIDEO_GRAPH" || TERMINATED=1

    if [[ "$TERMINATED" == "1" ]]; then
	echo -e "\r\e[1mCreating graph video...\e[0m \e[1m\e[91mfail \e[0m"
	confirm "Delete \"$VIDEO_GRAPH\"?" && del_v1
	confirm "Delete all the generated graphs?" && del_png
	clean_files
	echo -e "\n\e[1m\e[91mTerminated:\e[0m Problem generating video from plots\e[0m"
	exit 2
    fi
    

    echo -e "\r\e[1mCreating graph video...\e[0m \e[92m\e[1mdone   \e[0m"
fi


echo -e "\e[1mMerging videos...\e[0m"
ffmpeg $FORCE -v error -hide_banner -i "$VIDEO_GRAPH" -i "$VIDEO" -f lavfi -i "anullsrc=cl=1" -shortest -filter_complex "[0:v]setpts=PTS-STARTPTS, pad=width=iw*2.15:height=ih*1.1:x=iw*0.05:y=0.05*ih:color=white[bg]; [1:v]setpts=PTS-STARTPTS, scale=w=min(800\,600/ih*iw):h=-1[fg]; [bg][fg]overlay=x=trunc(W*0.75-w/2):y=trunc(H*0.5-h*0.5)" -c:v libx264 "$VIDEO_SBS" || TERMINATED=1

if [[ "$TERMINATED" == "1" ]]; then
   echo -e "\e[1mMerging videos...\e[0m \e[1m\e[91mfail \e[0m"
   confirm "Delete \"$VIDEO_SBS\"?" && del_v2
   confirm "Delete \"$VIDEO_GRAPH\"?" && del_v1
   confirm "Delete all the generated graphs?" && del_png
   clean_files
   echo -e "\n\e[1m\e[91mTerminated:\e[0m Problem mergin videos\e[0m"
   exit 2
fi
   
echo -e "\r\e[1mMerging videos...\e[0m \e[92m\e[1mdone   \e[0m"
del_png
clean_files
echo -e "\e[1m\e[92mFinished\e[0m"
