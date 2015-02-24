#!/bin/bash
if ! [ $INDEX ]; then echo "Please start this script with <main.sh>."; exit 99; fi

#012
#------------------------------------------------------------------------------------------------------------
#Check required program-paths.
#arg:  
#ret: 0 (success) OR 1 (error)
function check_programs(){ 
	execute "var_set $ffmpeg" 16 ###|| { print_help && exit 15; }
	execute "var_set $bmdcapture" 17 ###|| { print_help && exit 16; }
	return 0
}

#013
#------------------------------------------------------------------------------------------------------------
#Check required args for ffmpeg-command and set default-values if available.
#arg:  
#ret: 0 (success) OR 1 (error)
function check_ffmpeg_args(){ 
	! var_set $rec_bgimage && ffcmd_bg="" || ffcmd_bg="-loop 1 -i $rec_bgimage -r 25"
	! var_set $rec_audcodec && rec_audcodec="ac3"
	! var_set $rec_vidcodec && rec_vidcodec="libx264 -preset veryfast"
	execute "$ffmpeg -formats -loglevel quiet | grep -o $rec_audcodec" 9 ###|| { print_help && exit 9; }
	execute "$ffmpeg -formats -loglevel quiet | grep -o $rec_vidcodec" 9 ###|| { print_help && exit 9; }
	! var_set $rec_numvidcaptcards && rec_numvidcaptcards=`lspci | grep -o Blackmagic | wc -w`
	execute "./record.presets.sh $rec_layoutpre $rec_numvidcaptcards" 14 && layout_preset=$S001_cmdreturn || { execute "./record.presets.sh default $rec_numvidcaptcards" 14 && layout_preset=$S001_cmdreturn; }
	! var_set $rec_outfile && ffcmd_outfile="$WORKSPACE_PATH/recordings/record."`date +%d%b%Y.%H%M`".mkv" || ffcmd_outfile=$rec_outfile
 	execute "touch -c $ffcmd_outfile" 2 ###|| { print_help && exit 2; }

	return 0
}

#014
#------------------------------------------------------------------------------------------------------------
#Check and get sound-devices.
#arg:  
#ret: 0 (success) OR 1 (error)
function get_audio_devices(){
	! var_set $ff_soundsys && { execute "dpkg -l | grep 'alsa-base'" 0 && ff_soundsys="alsa" || \
							  { execute "dpkg -l | grep ' pulseaudio '" 0 && ff_soundsys="pulse";} || exec_error 10; } ###&& { print_help && exit 10; }
	! var_set $ff_soundhw && { execute "arecord -L | grep '^default'" 11 && ff_soundhw="$S001_cmdreturn"; } ###|| { print_help && exit 11; }
	return 0
}

#015
#------------------------------------------------------------------------------------------------------------
#Check and get video-devices.
#arg:  
#ret: 0 (success) OR 1 (error)
function get_vidrecord_devices(){
	execute "dpkg -l | grep -E 'desktopvideo.*Blackmagic'" 12 ###|| { print_help && exit 12; }
	execute "lspci | grep -o Blackmagic" 13 ###|| { print_help && exit 13; }
	return 0
}


check_programs && check_ffmpeg_args && get_audio_devices && get_vidrecord_devices


ffcmd_audin="-f $ff_soundsys -i $ff_soundhw"
ffcmd_audenc="-c:a $rec_audcodec"
for i in `eval echo {1..$rec_numvidcaptcards}`; do
	ffcmd_vidin+=("-i <($bmdcapture -m ${mod_vidcaptcards[$((i-1))]} -V3 -C $((i-1)) -F nut -f pipe:p$i &)")
done
ffcmd_videnc="-c:v $rec_vidcodec"
ffcmd_layout="$layout_preset"

ffcmd="$ffmpeg -y -v quiet -stats $ffcmd_audin $ffcmd_bg ${ffcmd_vidin[*]} $ffcmd_audenc $ffcmd_videnc $ffcmd_layout $ffcmd_outfile"
echo $ffcmd

printf "[${GRN}Record started at %s${OFF}]\n" "$(date +%H:%M:%S)"

(eval "$ffcmd" &)

rec_ctrl=false
until [ "$rec_ctrl" == "s" ]
do
	read -n 1 -s rec_ctrl
	case $rec_ctrl in
		s)
			killall -s SIGINT ffmpeg
			sleep 1
			printf "\n[${MAG}Record stopped at %s${OFF}]\n" "$(date +%H:%M:%S)"
			break
			;;
		m)
			a=1
			#MONITORING on/off
	esac
done






#http://trac.ffmpeg.org/wiki/Capture/ALSA
