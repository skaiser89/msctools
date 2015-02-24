#!/bin/bash
INDEX=true

#color-codes
BLK=$(tput setaf 0)
RED=$(tput setaf 1)
GRN=$(tput setaf 2)
YEL=$(tput setaf 3)
LIM=$(tput setaf 190)
BLU=$(tput setaf 4)
MAG=$(tput setaf 5)
CYN=$(tput setaf 6)
WHT=$(tput setaf 7)
FAT=$(tput bold)
OFF=$(tput sgr0)
#POWDER_BLUE=$(tput setaf 153)
#BLINK=$(tput blink)
#REVERSE=$(tput smso)
#UNDERLINE=$(tput smul)

FAIL="[${MAG}FAIL${OFF}]"
SUCC="[ ${GRN}OK${OFF} ]"

A_errors=(
"" \
"001: Unexpected error." \
"002: File not found." \
"003: File cannot be created." \
"004: Folder not found." \
"005: Folder cannot be created." \
"006: Arguments do not match." \
"007: Workspace Folders cannot be created." \
"008: No Workspace specified." \
"009 Unaviable ffmpeg option." \
"010 No soundsystem found (alsa/pulse)." \
"011 No default audio-capture-device found."
"012 No driver for Blackmagic capture-device found." \
"013 No Blackmagic capture-device found." \
"014 Layout-Preset doesn't exist." \
"015 Error during record." \
"016 ffmpeg not found." \
"017 bmdcapture not found."
)

A_messages=(
"" \
"    Successfully done." \
"    File loaded." \
"    File created." \
"    Folder loaded." \
"    Folder created." \
"    Arguments passed." \
"    Workspace set." \
"    Workspace set." \
"    ffmpeg option passed." \
"    Soundsystem found." \
"    Default audio-capture-device found." \
"    Driver for Blackmagic capture-devives found." \
"    Blackmagic capture-device found." \
"    Layout-Preset loaded." \
"	 Record done." \
"    ffmpeg is available." \
"    bmdcapture is available."
)

A_wsfolders=( \
"recordings" \
"results" \
"tmp" \
"tmp/ocr" \
"tmp/ocr/chapters" \
"tmp/ocr/sections" \
"tmp/slides" \
"tmp/data"
)





declare -a A_sects			# section-array	
declare -a A_secttype		# related section type
declare -a A_sectrank		# related section rank
declare -A A_sectrankcount	# related count of ranks per sectiontype

#005
#------------------------------------------------------------------------------------------------------------
#Prints help.
#arg: 
#ret: console-output
function print_help(){
	echo -e \
"HELP------------------------------------------------------
USAGE: 
\t$0 <video_file> <workspace_directory> <actions> <options>

ACTIONS: 
--record \t\t start recording

OPTIONS: 
--video-codec \t\t set video-codec for the recording
--audio-codec \t\t set audio-codec for the recording
--background-image \t set background-image-location and thereby video-resolution
--layout-preset \t set positioning of the video-streams by predefined values
--output-file \t\t specify a filename for the resulting video-file
----------------------------------------------------------
"
	return 0
}

#002:003
#------------------------------------------------------------------------------------------------------------
#Creates status-array.
#arg: error-code | evaluated command
#ret: status-array AND exit-code
function exec_error(){
	A_status=("$FAIL" "${MAG}${A_errors[$1]}${OFF}")
	[ $1 -eq 0 ] && return 1 || return $1             #####!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
}

function exec_success(){
	A_status=("$SUCC" "${GRN}${A_messages[$1]}${OFF}")
	return 0
}

#004
#------------------------------------------------------------------------------------------------------------
#Prints status-array in table format.
#arg: 
#ret: console-output
function exec_print(){
	printf "%s %s\n" "${A_status[0]}" "${A_status[1]}" 
}

#001
#------------------------------------------------------------------------------------------------------------
#Executes a given command in String with <eval> and handles errors.
#arg: command in double-quotes | assumed error-code
#ret: command output (stdin) OR error print AND error-code
function execute(){
	cmd="Executing <"`echo $1 | cut -d " " -f 1`"> ..."
	printf "%-30s" "$cmd"
	S001_cmdreturn=`eval $1 2> /dev/null` && exec_success $2 || exec_error $2
	ret=$?
	exec_print
	return $ret
}

#008
#------------------------------------------------------------------------------------------------------------
# Checks if an element exists in an array.
#arg: element | array as string
#ret: bool
function array_contains(){
	[ -z `echo $2 | grep -o $1` ] && return 1 || return 0 
}

#010
#------------------------------------------------------------------------------------------------------------
# Checks if a variable is false or set with a value.
#arg: variable
#ret: bool
function var_set(){
	[ "$1" = false ] && return 1 || return 0 
}

#006:007
#------------------------------------------------------------------------------------------------------------
#Checks if an File/Folder exists.
#arg: path to file 
#ret: bool 
function check_file(){
	[ -f $1 ]
}

function check_folder(){
	[ -d $1 ]
}

#011
#------------------------------------------------------------------------------------------------------------
#Creates Workspace folders if not available.
#arg: path to file 
#ret: bool
function create_workspace(){
	for item in ${A_wsfolders[*]}; do 
		mkdir -p "$1"
		{ check_folder $1/$item || mkdir -p "$1/$item"; } || return 4
	done
	return 0
}

#016
#------------------------------------------------------------------------------------------------------------
#Creates a timestamp-string by given tick-intervall.
#arg: unit with value, "S:1" -> tick = 1 second, "M:2" -> tick = 2 minutes 
#ret: timestamp string HH:MM:SS 
function timestamp(){
	
	
	if [ "$1" == "reset" ]; then 
		H=0;M=0;S=0;U=0;s=0;return 0;
	elif [ "$1" == "convert" ]; then 
		seconds=$2
		H=`printf "%02d" $((seconds/3600))`
		M=`printf "%02d" $(((seconds%3600)/60))`
		S=`printf "%02d" $(((seconds%3600)%60))`
		S_timestr="$H-$M-$S"
	else
		S_unit=${1:0:1}
		I_value=${1:2}
		case $S_unit in
			U)
				U=$((U+I_value));;
			S)
				S=$((S+I_value))
				s=$((s+I_value));;
			M)
				M=$((M+I_value));;
			H)
				H=$((H+I_value));;
		esac

		if [ $U -ge 1000 ]; then
			U=$((U-1000))
			S=$((S+1))
			s=$((s+1))
		elif [ $S -ge 60 ]; then
			S=$((S-60))
			M=$((M+1))
		elif [ $M -gt 60 ]; then
			M=$((M-60))
			H=$((H+1))
		fi
		S_timestr="$H:$M:$S"
	fi
	
	S_timestr_secs="$s";
}


#017
#------------------------------------------------------------------------------------------------------------
#Read from section file, created by sections1.html
#arg: txt file with section type and IM sections 
#ret: section-array and section-type-array
function read_sections(){
	i=0
	while read line
	do
		A_sects+=(`echo "$line" | cut -d ":" -f 2`)
		tmp_type_rank=`echo "$line" | cut -d ":" -f 1`
		A_secttype+=(${tmp_type_rank:0:-1})
		A_sectrank+=(${tmp_type_rank: -1})
		#((A_sectrankcount[${tmp_sectrank%?}]++))
		((i++))
	done < "$1"
	[ ${#A_sects[*]} -eq 0 ] && return 1 || { A_sects_indices=${!A_sects[*]}; return 0; }
}



#018
#------------------------------------------------------------------------------------------------------------
#Get existing files from folder.
#arg: path to folder with files to read-in
#ret: file-names AND file-array-indices AND number of files
function readfiles(){
	fkt_files=($(cd $1 && ls))
	fkt_indices=${!fkt_files[*]}
	fkt_count=${#fkt_files[*]}
}




#########################################################################################
### ARGUMENT-HANDLING                                                                 ###
#########################################################################################

#009
#------------------------------------------------------------------------------------------------------------
#
#arg: script-args
#ret:  
function get_args(){
	tmp_opts="$@"
	S_shortopts="v:w:pcso::u::"
	S_longopts="video:,workspace:,tpic,calc,show,tagcloud,chapters,upload,record,dialog,config"
	S_recordopts="background-image:,video-codec:,audio-codec:,output-file:,layout-preset:,video-streams:"
	
	execute "getopt -o $S_shortopts -l $S_longopts,$S_recordopts -- $tmp_opts" 6 && eval set -- "$S001_cmdreturn" || { print_help && exit 6; }
	
	VIDEO_FILE=false; WORKSPACE_PATH=false; TPIC=false; CALC=false; SHOW=false; TAGCLOUD=false; CHAPTERS=false; UPLOAD=false; RECORD=false; DIALOG=false; CONFIG=false
	rec_bgimage=false; rec_vidcodec=false; rec_audcodec=false; rec_outfile=false; rec_layoutpre=false; video_streams=false
	
	source config.cfg

	i=1
	tmp_argcout=$#
	while [ $i -le $tmp_argcout ]
	do
		case "$1" in
			--video)
				execute "check_file $2" 2 && VIDEO_FILE="$2" || { print_help && exit 2; }
				shift 2;;
			--workspace)
				execute "check_folder $2" 4 && WORKSPACE_PATH=$2 || execute "mkdir $2" 7 && WORKSPACE_PATH=$2 || { print_help && exit 7; }
				shift 2;;
			--tpic)
				TPIC=true; shift;; 
			--calc)
				CALC=true; shift;;
			--show)
				SHOW=true; shift;;
			--tagcloud)
				TAGCLOUD=true; shift;; 
				--language|--lang) 
					ocr_lang="$2"; shift 2;;
			--chapters)
				CHAPTERS=true; shift;;
			--upload)
				UPLOAD=true; shift;; 
			--record)
				RECORD=true; shift;;
				--background-image)
					execute "check_file $2" 2 && rec_bgimage="$2" || { print_help && exit 2; }
					shift 2;;
				--video-codec)
					rec_vidcodec="$2"; shift 2;;
				--audio-codec)
					rec_audcodec="$2"; shift 2;;
				--output-file)
					rec_outfile="$2"; shift 2;;
				--layout-preset)
					rec_layoutpre="$2"; shift 2;;
				--video-streams) 
					rec_numvidcaptcards="$2"; shift 2;;
			--dialog)
				DIALOG=true; shift;;
			--config)
				CONFIG=true; shift;;
			--)
				shift; break;;		
		esac
		((i++))
	done

	execute "var_set $WORKSPACE_PATH" 8 && create_workspace $WORKSPACE_PATH || { print_help && exit 8; }  
}

#########################################################################################
### MAIN                                                                              ###
#########################################################################################

! [ $# -eq 0 ] && get_args $@ || print_help

if   [ "$DIALOG" = true ]; then
	source dialog.sh --start
	exit 0
else
	if [ "$RECORD" = true ]; then
		source record.sh
	fi
	if [ "$CHAPTERS" = true ]; then
		source slideshift.sh
	fi
	if [ "$TAGCLOUD" = true ]; then
		source ocr.sh
	fi
	if [ "$UPLOAD" = true ]; then
		source upload.sh
	fi
fi









