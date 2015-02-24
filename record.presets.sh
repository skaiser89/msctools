#!/bin/bash
#if ! [ $INDEX ]; then echo "Please start this script with <index.sh>."; exit 99; fi
function get_layout_preset(){
	rec_numvidcaptcards=$2
	case $1 in
	picinpic1080tl) # pic in pic, 1920x1080, cam top-left
		[ 2 -eq $rec_numvidcaptcards ] && { \
		preset_filter='-filter_complex "
						[1:0]pad=iw:ih:0:0[bg];
						[2:0]scale=320:-1[left];
						[3:0]scale=1600:-1[right];
						[bg][left]overlay=160:100[leftbg];
						[leftbg][right]overlay=160:100[out]"'; \
		preset_map='-map "[out]" -map 0:0'; } \
		|| return 2;;
	blank1080) # 1 stream, no background, 1920x1080
		[ 1 -eq $rec_numvidcaptcards ] && { \
		preset_filter=''; \
		preset_map='-map 1:0 -map 0:0'; } \
		|| return 2;;
	default|*|sidebyside1080bl) # side by side, 1920x1080, cam bottom-left
		[ 2 -eq $rec_numvidcaptcards ] && { \
		preset_filter='-filter_complex "
						[1:0]pad=iw:ih:0:0[bg];
						[2:0]scale=565:-1[left];
						[3:0]scale=1205:-1[right];
						[bg][left]overlay=50:560[leftbg];
						[leftbg][right]overlay=665:200[out]"'; \
		preset_map='-map "[out]" -map 0:0'; } \
		|| return 2;;
	esac
	#preset_filter=`echo $preset_filter | tr -d " "`
	return 0
}
get_layout_preset $@ && echo $preset_filter $preset_map || echo 0

