#!/bin/bash
if ! [ $INDEX ]; then echo "Please start this script with <index.sh>."; exit 99; fi

A_errors+=(
"018 XXX." \
"019 XXX." 
)

A_messages+=(
"    XXX." \
"    XXX." 
)

#img_buffer=3		# how many images should stored at same time

S_timestr=""			
S_timestr_secs="";


#019
#------------------------------------------------------------------------------------------------------------
#Determines slideshifts on tI_he base of values by imagemagick.
#arg: fuzz-value from imagemagick
#ret: <slideshiftstr> full|part|none
function determine_slideshift(){
	arg_count=$#
	det=0
	if [ $arg_count -ne 0 ]
	then
		for item in $@
		do
			[ $item -gt 5000 ] && { ((det++));((det++));		continue; } 
			[ $item -gt 2000 ] && { ((det++));				 	continue; } 
		done
		
		[ $det -eq $((arg_count*2)) ] 	&& { det_value=3; return 0; }
		[ $det -gt 0 ]					&& { det_value=1; return 0; }
											 det_value=0; return 0;
	else
		det_value=0
		return 1;
	fi
}

#020
#------------------------------------------------------------------------------------------------------------
#
#arg: 
#ret: 
function get_comparevalues(){
	execute "check_file $WORKSPACE_PATH/tmp/data/$file_compare_sections" 2 \
		&& { read_sections $WORKSPACE_PATH/tmp/data/$file_compare_sections && sectfile=true || sectfile=false; } \
		|| { sectfile=false; } 
	
	execute "$ffmpeg -i $VIDEO_FILE -loglevel quiet -f image2 -vf fps=1/$I_ticks $WORKSPACE_PATH/tmp/slides/%05d.png" 0	
	readfiles $WORKSPACE_PATH/tmp/slides/	
	#execute "readfiles $WORKSPACE_PATH/tmp/slides/" 2 ###|| { print_help && exit 2; } 
	img_iterator=1
	rm -f $WORKSPACE_PATH/tmp/data/$file_compare_values
	for i in $fkt_indices
	do
		if ! [ -z "${fkt_files[$((i+1))]}" ]
		then
			imcmd1="compare -metric Fuzz -fuzz 10%"
			imcmd2="$WORKSPACE_PATH/tmp/slides/${fkt_files[$i]} $WORKSPACE_PATH/tmp/slides/${fkt_files[$((i+1))]} null: 2>> $WORKSPACE_PATH/tmp/data/$file_compare_values"
			#ocrimages $path_folder/$fold_imgdata/${fkt_files[$i]}
			echo ">>>img:$img_iterator" >> $WORKSPACE_PATH/tmp/data/$file_compare_values
			if [ $sectfile = true ]
			then
				for j in $A_sects_indices
				do
					eval "$imcmd1 -extract ${A_sects[j]} $imcmd2"		
				done
			else
				eval "$imcmd1 $imcmd2"	
			fi

			((img_iterator++))
		fi
	done
	echo ">>>img:$img_iterator" >> $WORKSPACE_PATH/tmp/data/$file_compare_values

	timestamp reset
	comp_values=()
	while read line
	do	
		if [ "${line:0:3}" == ">>>" ]
		then
			determine_slideshift ${comp_values[*]}
			timestamp S:$I_ticks
			img1=${line:7};img2=$((img1+1))
			[ $det_value -eq 3 ] || [ $det_value -eq 1 ] && echo "$det_value $S_timestr" >> $WORKSPACE_PATH/tmp/data/$file_slideshifts
			[ $det_value -eq 0 ] && rm -f $WORKSPACE_PATH/tmp/slides/`printf "%05d\n" $img1`.png
			comp_values=()
		else	
			float_value=$(echo "$line" | cut -d " " -f 1)
			comp_values="$comp_values ${float_value/\.*} "
		fi 
	done < "$WORKSPACE_PATH/tmp/data/$file_compare_values"
	return 0
}

echo moin
get_comparevalues



