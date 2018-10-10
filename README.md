# video-graph

The script works with load/displacement/time data from Hysitron PI, which is exported to a txt file. The load/displacement is plotted and combined with the video recording.

![Example screenshot of the resulting video](example.png)

## Requirements

1. gnuplot
2. ffmpeg
3. bash

## Usage

````
video-graph.sh [-h|--help] [-t|--title <"string">] [-s|--step <number>] [-l|--load <"path">] 
               [-v|--video <"path">] [--verbose] [--merge] [--skip_plot] [--force] input_file

	-h|--help: Show help

	-t|--title: Set plot title. Default: input_file

	-s|--step: Set number of plot points added per video frame. Default: 100

	-l|--load: Set gnuplot file to preload 

	-v|--video: Set video file name. Default: input_file_name.mp4

	--verbose: Show the last generated plot

	--merge: Only merge videos. Do not generate images

	--skip_plot: Skip plot generation

	--force: overwrite video files without asking

	--nomini: do not plot mini graph

	input_file: plain text data file, first two columns will be plotted, 
              third column is used as a time to align with video
````
