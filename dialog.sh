#!/bin/bash

PATH_SCRIPT=`dirname $0`

source $PATH_SCRIPT/config.cfg

diacnf_width=50
diacnf_height=20

A_navigation=()

declare -A A_profile_current

#??
#------------------------------------------------------------------------------------------------------------
#Deletes a selected profile with verification request.
#arg: 
#ret: 
function deleteprofile(){
	B_proceed=false
	getprofiles $PATH_SCRIPT/profiles
	while [ "$B_proceed" = false ]; do
		dia_menue "Profil löschen" "Auswahl" "Löschen" "Zurück" "#" ${#A_profiles_valid[*]} "$str_menue"
		case $? in 	0) 	! [ "$return_entry" == "" ] && S_profile_sel=${A_profiles[$((return_entry-1))]}
										dia_request "Profil \"$S_profile_sel\" löschen?" "#" "#" "#" && { rm -f $PATH_SCRIPT/profiles/$S_profile_sel; B_proceed=true; break; } \
																																					 			 || { B_proceed=false; continue; };;
								1) NEXTFUNC="manageprofiles"; return 1;;
															
		esac
	done
	
	[ "$B_proceed" = true ] && { dia_message "Profil \"$S_profile_name\" erfolgreich gelöscht." "#" "#"; \
															 NEXTFUNC="mainmenue"; return 0; } \
													|| { NEXTFUNC="deleteprofiles"; return 1; }
}



#??
#------------------------------------------------------------------------------------------------------------
#Checking validation of a profile.
#arg: profile-file
#ret: 0 -> valid | !=0 -> invalid
function check_profile(){
	for k in ${!A_profile_dummy[*]}; do
		grep -q $i $1 || return 1
	done 
	[ `grep -o "A\_profile\_current\[" $1 | wc -w` -eq ${#A_profile_dummy[*]} ] || return 1
	[ `grep -o "\]=" $1 | wc -w` -eq ${#A_profile_dummy[*]} ] || return 1
	return 0
}

#??
#------------------------------------------------------------------------------------------------------------
#Loading and checking files which include profile information.
#arg: profile-folder
#ret: list of valid profiles <A_profiles_valid>
function getprofiles(){
	A_profiles=(`ls $1`)
	A_profiles_valid=()
	str_menue=""; int_menue=1;
	for i in ${!A_profiles[*]}; do
			check_profile $1/${A_profiles[$i]} && { str_menue+="$int_menue ${A_profiles[$i]} "; A_profiles_valid+=(${A_profiles[$i]}); ((int_menue++)); }
	done 
}

#??
#------------------------------------------------------------------------------------------------------------
#Generate ffmpeg-cmd.
#arg: profile-array
#ret: generated ffmpeg-cmd
function ffmpeg_cmd(){
	echo "> "${A_profile_current[*]}
	exit
}


#??
#------------------------------------------------------------------------------------------------------------
#Dialog Template: Menue [ OK | BACK ].
#arg: menue-title | hint | ok-label | cancel-label | list-height | menue-emtries
#ret: user-choice
function dia_menue(){
	dia_menue_title=$1
	! [ "$2" == "#" ] && dia_menue_hint="- $2" || dia_menue_hint=""
	dia_menue_oklabel=$3
	dia_menue_cancellabel=$4
	! [ "$5" == "#" ] && dia_menue_extabutton="--extra-button --extra-label $5" || dia_menue_extabutton=""
	dia_menue_listheight=$6
	dia_menue_str=$7
	
	#[ "${dia_menue_hint:0:1}" == "!" ] && dia_menue_hint=${dia_menue_hint:1}
	
	return_entry=`\
	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--ok-label "$dia_menue_oklabel" \
					--cancel-label "$dia_menue_cancellabel" $dia_menue_extabutton \
					--menu "$dia_menue_title $dia_menue_hint" $diacnf_height $diacnf_width $dia_menue_listheight $dia_menue_str 3>&1 1>&2 2>&3`
	return_btn=$?
	echo $return_btn
	return $return_btn
	
}

#??
#------------------------------------------------------------------------------------------------------------
#Dialog Template: Yes-No-Request.
#arg: request-title | [hint] | [yes-label] | [no-label]
#ret: user-choice
function dia_request(){
	dia_request_title=$1
	! [ "$2" == "#" ] && dia_request_hint="- $2" || dia_request_hint=""
	! [ "$3" == "#" ] && dia_request_yeslabel=$3 || dia_request_yeslabel="Ja"
	! [ "$4" == "#" ] && dia_request_nolabel=$4 || dia_request_nolabel="Nein" 

	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--yes-label $dia_request_nolabel \
					--no-label $dia_request_yeslabel \
					--yesno "$dia_request_title $dia_request_hint" $diacnf_height $diacnf_width
	btn_return=$?					
	[ $btn_return -eq 1 ] && return 0 || return 1
}

#??
#------------------------------------------------------------------------------------------------------------
#Dialog Template: Inputbox [ OK | BACK ].
#arg: input-title | hint | ok-label | cancel-label 
#ret: user-choice
function dia_input(){
	dia_input_title=$1
	! [ "$2" == "#" ] && dia_input_hint="- $2" || dia_input_hint=""
	dia_input_oklabel=$3
	dia_input_cancellabel=$4
	
	#! [ "${dia_input_hint:0:1}" == "!" ] || dia_input_hint=${dia_input_hint:1}
	return_entry=`\
	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--ok-label "$dia_input_oklabel" \
					--cancel-label "$dia_input_cancellabel" \
					--inputbox "$dia_input_title $dia_input_hint" $diacnf_height $diacnf_width 3>&1 1>&2 2>&3`
	return_btn=$?	
}

#??
#------------------------------------------------------------------------------------------------------------
#Dialog Template: Message-Box [ OK ].
#arg: input-title | input-text | ok-label
#ret: user-choice
function dia_message(){
	dia_message_title=$1
	! [ "$2" == "#" ] && dia_message_text=$2 || dia_message_text=""
	! [ "$3" == "#" ] && dia_message_oklabel=$3 || dia_message_oklabel="OK"

	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--ok-label $dia_message_oklabel \
					--msgbox "$dia_message_title\n\n$dia_message_text" $diacnf_height $diacnf_width
	btn_return=$?					
	[ $btn_return -eq 1 ] && return 0 || return 1
}

#??
#------------------------------------------------------------------------------------------------------------
#File-name prompt with exception-handling.
#arg: 
#ret: profile-name : S_profile_name
function newprofile_name(){
	B_proceed=false
	S_hint="Profilnamen festlegen"
	while [ "$B_proceed" = false ]; do
		dia_input "Neues Profil" "$S_hint" "Weiter" "Abbrechen"

		if [ $return_btn -eq 0 ]; then
			#überprüfung
			return_entry=`echo $return_entry | tr -s [:blank:] "_"` #leerzeichen durch _ ersetzen
			[ "$return_entry" == "" ] \
				&& { S_hint="Ungültiger Profilname"; B_proceed=false; continue; } \
				|| B_proceed=true
			[ -e $PATH_SCRIPT/profiles/$return_entry ] \
				&& { S_hint="Profilname bereits vorhanden"; ! dia_request "Datei \"$return_entry\" überschreiben?" 0 0 0 && { B_proceed=false; continue; } \
																																											 													 || B_proceed=true; } \
				|| B_proceed=true
		elif [ $return_btn -eq 1 ]; then
			NEXTFUNC="manageprofiles"
			return 1
		fi
	done
	S_profile_name=$return_entry
	
	NEXTFUNC="newprofile_data"
	return 0
}

#??
#------------------------------------------------------------------------------------------------------------
#Prompt profile-configuration on base of given values.
#arg: 
#ret: profile-data : S_profile_data
function newprofile_data(){
#	navigation next $FUNCNAME

	S_hint1="Optionen festlegen"
	
	B_profile=false
	while [ "$B_profile" = false ]; do 
		str_menue1=""
		for i in ${!A_profile_key[*]}; do
				str_menue1+="$i ${A_profile_dummy[$i]} "
		done 
		
		dia_menue "Neues Profil" "$S_hint1" "Auswählen..." "Zurück" "Profil_anlegen" ${#A_profile_key[*]} "$str_menue1"
		if [ $return_btn -eq 0 ]; then
			S_arraykey=$return_entry 
			A_listselect=(${A_profile_options[$S_arraykey]})
		elif [ $return_btn -eq 3 ]; then
			B_profile=true
			for i in ${A_profile_dummy[*]}; do	
				[ "$i" == "..." ] && B_profile=false																												
			done
			[ "$B_profile" = "false" ] && { S_hint1="Profil nicht komplett"; continue; } \
																 || break
		elif [ $return_btn -eq 1 ]; then
			NEXTFUNC="newprofile_name"
			return 1														 
		fi
										
															
		str_menue2=""
		for i in ${!A_listselect[*]}; do
				str_menue2+="$((i+1)) ${A_listselect[$i]} "
		done
		
		dia_menue "Option wählen" "#" "OK" "Zurück" "#" ${#A_listselect[*]} "$str_menue2"
		if [ $return_btn -eq 0 ]; then
			! [ "$return_entry" == "" ] && \
				A_profile_dummy[$S_arraykey]=${A_listselect[$((return_entry-1))]}
		fi

	done	
	
	#profildatei-inhalt generieren
	S_profile_data=""
	for i in ${!A_profile_dummy[*]}; do
		S_profile_data+="A_profile_current[$i]=${A_profile_dummy[$i]};"	 
	done  
	echo $S_profile_data > $PATH_SCRIPT/profiles/$S_profile_name
	
	[ -e $PATH_SCRIPT/profiles/$S_profile_name ] && dia_message "Profil \"$S_profile_name\" erfolgreich angelegt." "#" "#"
	
	NEXTFUNC="manageprofiles"
	return 0
}

#??
#------------------------------------------------------------------------------------------------------------
#Display the configuration of the previous loaded profile.
#arg: profile-file (=name)
#ret: 
function loadprofile_show(){
	#### declare -A A_profile_current
	
	getprofiles $PATH_SCRIPT/profiles
	dia_menue "Profil laden" "Auswahl" "Laden" "Zurück" "#" ${#A_profiles_valid[*]} "$str_menue"
	return_btn1=$?
	case $return_btn1 in 	0) 	! [ "$return_entry" == "" ] && S_profile_sel=${A_profiles[$((return_entry-1))]}
														source $PATH_SCRIPT/profiles/$S_profile_sel
														str_menue1=""
														for i in ${!A_profile_current[*]}; do
																str_menue1+="${A_profile_key[$i]}: ${A_profile_current[$i]}\n"
														done 
														dia_request "Profil laden - Geladenes Profil\n\n$str_menue1" "#" "Zurück" "Weiter"
														return_btn2=$?
														case $return_btn2 in 	0) NEXTFUNC="loadprofile_show"; return 1;;
																									1) dia_message "Profil \"$S_profile_sel\" erfolgreich geldaden." "#" "#"
																										 NEXTFUNC="manageprofiles"; return;;
														esac;;
												1) NEXTFUNC="manageprofiles"; return 1;;
	esac
}





#navigation next $FUNCNAME

function mainmenue(){
	dia_menue "Hauptmenü" "#" "Weiter" "Beenden" "#" 3 "1 Aufnahme 2 Profile 3 Optionen"
	if [ $return_btn -eq 0 ]; then
		case $return_entry in 
			1) NEXTFUNC="takerecord";;
			2) NEXTFUNC="manageprofiles";;
			3) NEXTFUNC="editoptions";; 
		esac
	else NEXTFUNC="exit"
	fi      
}

function takerecord(){
	
	dia_menue "Aufnahme" "#" "Weiter" "Beenden" "#" 3 "1 Aufnahme 2 ronk 3 flap"
	if [ $return_btn -eq 0 ]; then
		case $return_entry in 
			1) [ "${#A_profile_current[*]}" -eq 0 ] \
					&& NEXTFUNC="loadprofile_show" \
					|| NEXTFUNC="ffmpeg_cmd";;
			2) NEXTFUNC="exit";;
			3) NEXTFUNC="exit";;
		esac
	else NEXTFUNC="mainmenue"
	fi      
}

function manageprofiles(){
	dia_menue "Aufnahme-Profile verwalten" "#" "Weiter" "Zurück" "#" 3 "1 Neues_Profil 2 Profil_laden 3 Profil_löschen"
	if [ $return_btn -eq 0 ]; then
		case $return_entry in 
			1) NEXTFUNC="newprofile_name";;
			2) NEXTFUNC="loadprofile_show";;
			3) NEXTFUNC="deleteprofile";;
		esac
	else NEXTFUNC="mainmenue"
	fi      
}

function editoptions(){
	dia_menue "Optionen" "#" "Weiter" "Zurück" "#" 3 "1 foo 2 bar 3 qux"
	if [ $return_btn -eq 0 ]; then
		case $return_entry in 
			1) NEXTFUNC="exit";;
			2) NEXTFUNC="exit";;
			3) NEXTFUNC="exit";;
		esac
	else NEXTFUNC="mainmenue"
	fi      
}

function dia_loop(){
	NEXTFUNC=$1
	
	while true; do
		$NEXTFUNC
	done 

}



#newprofile
#loadprofile
#deleteprofile

#mainmenue
dia_loop mainmenue
