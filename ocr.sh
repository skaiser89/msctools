#!/bin/bash
if ! [ $INDEX ]; then echo "Please start this script with <index.sh>."; exit 99; fi

A_errors+=(
"018 No chapter-section found in $file_compare_sections." \
"019 No stopword-file found." \
"020 Error while OCR-File merging." \
"021 Stopword-deleting failed."
)

A_messages+=(
"    Chapter-section loaded." \
"    Stopword-file loaded." \
"    OCR-Files merged."
"    Stopwords deleted."
) 

declare -A A_chapters_rank
declare -A A_chapters_num
declare -A A_chapters_start


#021
#------------------------------------------------------------------------------------------------------------
# 
#arg: 
#ret: 
function check_args()
{
	! var_set $ocr_lang && $ocr_lang="eng"
	execute "check_file $WORKSPACE_PATH/tmp/data/$file_compare_sections" 2 
}


#022
#------------------------------------------------------------------------------------------------------------
# 
#arg: 
#ret: 
function init_sectiondata()
{
	execute "check_file $WORKSPACE_PATH/tmp/data/$file_compare_sections" 2 \
	&& read_sections $WORKSPACE_PATH/tmp/data/$file_compare_sections \
	&& readfiles $WORKSPACE_PATH/tmp/slides/ || return 2
	return 0
}

#023
#------------------------------------------------------------------------------------------------------------
# Merges multiple text-files-paths to string.
#arg: folder with text-files
#ret: string with file-paths
function filepath_merge()
{
	readfiles $1
	fkt_filepaths=""
	for item in ${fkt_files[*]}
	do
		fkt_filepaths="$fkt_filepaths $1/$item "
	done	
}



#024
#------------------------------------------------------------------------------------------------------------
# Merging section-files and extract most frequent keywords.
#arg: folder with section-files
#ret: most frequent keywords
function get_sectiontags()
{
	filepath_merge $1
	#execute "cat $tmp_filename" 20 && echo $S001_cmdreturn \ ????????????????????????????????????? 
	cat $fkt_filepaths \
	| tr '\n' ' ' \
	| tr '\t' ' ' \
	| tr '[:upper:]' '[:lower:]' \
	| tr -cd "[:alpha:][:blank:]\'" \
	| sed -e 's/ .[[:space:]]//g' \
	| sed -e 's/ ..[[:space:]]//g' \
	| tr -s ' '  \
	> $WORKSPACE_PATH/tmp/ocr/$file_sect_merge
#!!! script path!!!
	execute "cat /scr/glan1/skaiser/BA/scripts_BA/resources/stopwords/$ocr_lang" 19 && sed_str=`echo $S001_cmdreturn | sed "s#[^ ][^ ]*#-e \"s/ &[[:space:]]/ /g\"#g"` || return 19
	execute "cat $WORKSPACE_PATH/tmp/ocr/$file_sect_merge" 21 && echo $S001_cmdreturn | eval "sed $sed_str" > $WORKSPACE_PATH/tmp/ocr/$file_sect_stopwords
	execute "cat $WORKSPACE_PATH/tmp/ocr/$file_sect_stopwords" 2 && echo $S001_cmdreturn \
																		| tr -c '[:alnum:]' '[\n*]' \
																		| tr -s ' ' \
																		| sort \
																		| uniq -c \
																		| sort -nr \
																		| head -$max_sect_tags
}

#026
#------------------------------------------------------------------------------------------------------------
#Determine the minimum of a sequence.
#arg: sequence of numbers
#ret: minimum ($fkt_min)
function min()
{
	fkt_min=0
	numbers=($@)
	[ ${numbers[0]} -lt ${numbers[1]} ] && fkt_min=${numbers[0]} || fkt_min=${numbers[1]}
	for i in ${!numbers[*]}
	do
		[ $((i+1)) -ge ${#numbers[*]} ] && break
		[ $fkt_min -gt ${numbers[$((i+1))]} ] && fkt_min=${numbers[$((i+1))]}
	done
}

#027
#------------------------------------------------------------------------------------------------------------
#Compares two strings based on amount of driffrent chars in same position or shift 1 left/right. 
#arg: string1 | string2
#ret: minimum amount of driffrent chars in same position or shift 1 left/right. ($fkt_min)
function string_compare()
{
	str1=$1
	str2=$2
	fkt_diffcount1=0
	fkt_diffcount2=0
	fkt_diffcount3=0
	[ ${#str1} -eq ${#str2} ] && str_length=${#str1}
	[ ${#str1} -lt ${#str2} ] && str_length=${#str2}
	[ ${#str1} -gt ${#str2} ] && str_length=${#str1}
	i=0
	while [ $i -lt $str_length ]
	do
		! [ "${str1:$i:1}" == "${str2:$i:1}" ] && ((fkt_diffcount1++))
		! [ "${str1:$i:1}" == "${str2:$((i+1)):1}" ] && ((fkt_diffcount2++))
		! [ "${str1:$i:1}" == "${str2:$((i-1)):1}" ] && ((fkt_diffcount3++))
		((i++))
	done
	min $fkt_diffcount1 $fkt_diffcount2 $fkt_diffcount3
}

#028
#------------------------------------------------------------------------------------------------------------
# Finds the intersection of strings.
#arg: string-array
#ret: string-intersection
function string_intersection()
{
	A_fktcompare=$@	
	tmp_wc=0	

	until [ $tmp_wc -eq 1 ]
	do
		tmp_cmd="printf \"%s\\n\""
		for item in ${A_fktcompare[*]}
		do
			tmp_cmd+=" \"$item\" "
		done
		tmp_cmd+="| sed -e 'N;s/^\(.*\).*\n\1.*$/\1/'"
		A_fktcompare=(`eval $tmp_cmd`)
		tmp_wc=`echo "${A_fktcompare[*]}" | wc -w`
	done

	fkt_intersection="${A_fktcompare[*]}"
}

#025
#------------------------------------------------------------------------------------------------------------
# 
#arg:
#ret:
function get_chapters()
{
	###filepath_merge $1
	###A_chapters=(`cat $fkt_filepaths | tr ' ' '_'`)

	readfiles $1
	for item in ${fkt_files[*]}
	do
		A_chapters+=(`cat $1/$item | tr ' ' '_'`)
	done	
		

	echo ${A_chapters[@]}
	#echo ${A_chapters[@]} | tr ' ' '\n'
	for j in ${!A_chapters[*]}
	do
		#! var_set ${A_chapters[$i]} && { A_chapters[$i]="-----"; continue; }
		arr1=`echo ${A_chapters[$j]} | cut -d ':' -f 3`
		arr2=`echo ${A_chapters[$((j+1))]} | cut -d ':' -f 3`
		string_compare $arr1 $arr2
		#echo $fkt_min ">>>"$arr1" ~~~ "$arr2
		
		[ $fkt_min -gt 3 ] && A_chapters_filtered+=(${A_chapters[$j]}) #A_chapters=(${A_chapters[@]:0:$j} ${A_chapters[@]:$((j + 1))}) #unset A_chapters[$((i+1))]
		
	done
	echo "---------------------------------------------------------------------------------------------------"
	#echo ${A_chapters_filtered[@]} | tr ' ' '\n'
	echo "---------------------------------------------------------------------------------------------------"
	#echo ${A_chapters[@]} | tr ' ' '\n'
	echo "---------------------------------------------------------------------------------------------------"
	#echo ${A_chapters[@]} | tr ' ' '\n' | cut -d ':' -f 3 | tr -cd "[:alpha:]\n_" | hunspell -L -p $WORKSPACE_PATH/tmp/data/dict.dic
	add_chapter=""
	add_time=""
	lst_chapter=""
	for k in ${!A_chapters[*]}
	do
		tmp_content=`echo ${A_chapters[$k]} | cut -d ':' -f 3-`
		tmp_ranktime=`echo ${A_chapters[$k]} | cut -d ':' -f 1,2`
		tmp_time=`echo ${A_chapters[$k]} | cut -d ':' -f 2`

		[ $k -eq 0 ] && add_time=$tmp_time \
		! [ "$tmp_content" == "$add_chapter" ] && add_time=$tmp_time

		! [ "$tmp_content" == "$add_chapter" ] && ! [ "$tmp_content" == "false" ] && { add_chapter=$tmp_content; A_chapters_unique+=("$tmp_time:$tmp_content"); }

		tmp_spellcheck=`echo ${A_chapters[$k]} | hunspell -L -p $WORKSPACE_PATH/tmp/data/dict.dic`
		[ "$tmp_spellcheck" == "" ] && A_chapters_spellchecked+=("`echo ${A_chapters[$k]} | sed -e 's/__*/_/g' -e 's/^_//g' -e 's/_$//g' -e 's/:$/:false/g'`") \
									  || A_chapters_spellchecked+=("$tmp_ranktime:false")
		[ "$tmp_content" == "false" ] && {  } \
									   || 
	done

	echo ${A_chapters_spellchecked[@]} | tr ' ' '\n'
	

	#cat $fkt_filepaths | cut -d ":" -f 3 | sed '/^\s*$/d' | uniq 
	

}

#029
#------------------------------------------------------------------------------------------------------------
# 
#arg: 
#ret: 
function extract_words()
{
	
	
	input_file=$1
	it=$2

	tmp_tick=`echo $input_file | sed -e 's/[^0-9]//g' -e 's/^0*//g'`
	timestamp convert $tmp_tick

	for i in ${!A_sects[*]}; do
		tmp_sect=${A_sects[$i]}
		tmp_secttype=${A_secttype[$i]}
		tmp_sectrank=${A_sectrank[$i]}
		tmp_secttype=${tmp_secttype:0:7}

		
		tmp_filename=`printf "%05d.%s.%s" $it $S_timestr $tmp_sectrank`
		
		case $tmp_secttype in
			chapter) #|section
				convert -threshold  50% -extract $tmp_sect $input_file $WORKSPACE_PATH/tmp/ocr/tmp$it.png \
				&& tesseract -l $ocr_lang $WORKSPACE_PATH/tmp/ocr/tmp$it.png $WORKSPACE_PATH/tmp/ocr/tmp$it 1>/dev/null 2>&1 \
				&& S_ocrresult=`cat $WORKSPACE_PATH/tmp/ocr/tmp$it.txt` #\
				###&& { rm -f $WORKSPACE_PATH/tmp/ocr/tmp.txt; rm -f $WORKSPACE_PATH/tmp/ocr/tmp.png; }
			;;&
			chapter)
				#for j in {1..${A_sectrankcount[$tmp_sectrank]}}; do
				! [ -z "$S_ocrresult" ] && echo "$tmp_sectrank:$S_timestr:$S_ocrresult" | tr "\n" " " >> $WORKSPACE_PATH/tmp/ocr/chapters/$tmp_filename.chapter.txt
			;;&
			# section)
			#	! [ -z "$S_ocrresult" ] && echo "$S_ocrresult " >> $WORKSPACE_PATH/tmp/ocr/sections/$tmp_filename.section.txt
			#;;
			*)
				a=1
			;;
		esac
	done
}
: '
init_sectiondata \
&& { var_set $CHAPTERS && { execute "array_contains \"chapter\" \"${A_secttype[*]}\"" 18 || CHAPTERS=false;  }; }
|| 
extract_chapters "/SCR/test123/tmp/slides/00019.png"
'

init_sectiondata

###c=1
###timestamp reset
###for k in $fkt_indices; do
###	extract_words $WORKSPACE_PATH/tmp/slides/${fkt_files[$k]} $c
###	((c++))
###done

##get_sectiontags $WORKSPACE_PATH/tmp/ocr/sections
get_chapters $WORKSPACE_PATH/tmp/ocr/chapters



##for it in {6..13}
##do
##	A_temp+=(`echo "${A_chapters[$it]}" | cut -d ':' -f 3`)
##done

##echo "###"
##echo "${A_temp[*]}" | tr ' ' '\n'
##echo "###"


##string_intersection ${A_temp[*]}

##echo $fkt_intersection
###readfiles $WORKSPACE_PATH/tmp/ocr/sections #${fkt_files[*]}
###	cd $WORKSPACE_PATH/tmp/ocr/sections/
#merge section-files, delete unusable symbols, format into whitespace separated wordlist
###	cat ${fkt_files[*]} | tr '\n' ' ' | tr '\t' ' '  | tr '[:upper:]' '[:lower:]' | tr -cd "[:alpha:][:blank:]\'" | sed -e 's/ .[[:space:]]//g' | tr -s ' '  > $WORKSPACE_PATH/tmp/ocr/test1.txt
#generate expr. list for sed based on stopwordlist to delete stopwords
###	str=`cat /scr/glan1/skaiser/BA/scripts_BA/resources/stopwords/en | sed "s#[^ ][^ ]*#-e \"s/ &[[:space:]]/ /g\"#g"`
#eval sed with genereted expr. list
###	eval "cat $WORKSPACE_PATH/tmp/ocr/test1.txt | sed $str" > $WORKSPACE_PATH/tmp/ocr/test2.txt
#filter most frequent words




#http://sourceforge.net/projects/tagcloudmaker/

#http://stackoverflow.com/questions/1251999/sed-how-can-i-replace-a-newline-n
#http://unix.stackexchange.com/questions/18236/how-do-i-find-the-overlap-of-two-strings-in-bash
