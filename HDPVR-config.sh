#!/bin/sh

#by David Stoll
#June 11, 2011


#It doesn't look like it needs to be run as root, but these lines would check that
#if [ "$(id -u)" != "0" ]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

echo ""

device=`dmesg | grep "hdpvr" | grep "video" | grep "attached" | tail -1 | grep -o '[^ ]*$'` # find device

device="/dev/$device"	# set device variable to full path

if [ "$device" = "" ] || [ ! -e $device ]
	then
		echo " device error or unable to find HDPVR"
		echo ""
		exit 1
fi


#if audioinputnum variable isn't set to something, the until operation works, but echos an operand error
if [ -z $1 ]
	then
		audioinputnum="null"
	else
		audioinputnum="$1"
fi

audioencoding=`v4l2-ctl --device=$device -l | grep "audio_encoding" | cut -d ' ' -f 24 | cut -c 7 | tr -d '\n'`	# determine current audio encoding: aac (default) or ac3


#translate current audio encoding numeric config settings to human readable descriptions
if [ $audioencoding = "3" ]
	then
		audioencoding="aac"
elif [ $audioencoding = "4" ]
	then
		audioencoding="ac3"
else
		echo " device error or unable to parse config"
		echo " encoding cannot be = '$audioencoding'"
		exit 1
fi



#if no input given on command line, so ask for it
until [ $audioinputnum = "0" ] || [ $audioinputnum = "1" ] || [ $audioinputnum = "2" ] || [ $audioinputnum = "3" ] || [ $audioinputnum = "4" ] || [ $audioinputnum = "q" ]
	do
		echo " You can set the input on the command line and avoid this menu"
		echo " by simply adding the appropriate number after the script call."
		echo ""
		echo " Found HDPVR at: $device"
		echo -n " Current config: $audioencoding on " && v4l2-ctl --device=$device --get-audio-input
		echo ""
		echo " Which input would you like the HDPVR to use?"
		echo ""
		echo " 0 = Audio input : 0 (RCA back)"
		echo " 1 = Audio input : 1 (RCA front)"
		echo " 2 = Audio input : 2 (SPDIF)"
		echo " 3 = Audio encoding = aac"
		echo " 4 = Audio encoding = ac3 (somewhat flakey, may require HDPVR power cycle)"
		echo " q = quit"
		echo ""
		read audioinputnum		
		if [ -z $audioinputnum ]
			then
				audioinputnum="null"
		fi

done


#don't change the next 3 lines unless your firmware reports different text when checking input setting (replace ? with your correct device number): v4l2-ctl --device=/dev/video? --get-audio-input
in0txt="Audio input : 0 (RCA back)"
in1txt="Audio input : 1 (RCA front)"
in2txt="Audio input : 2 (SPDIF)"

echo " now checking input..."

echo -n " Current config: $audioencoding on " && v4l2-ctl --device=$device --get-audio-input



#If RCA back (0) was chosen and not used, make the change.
if [ $audioinputnum = 0 ]
	then 
		if [ "$(v4l2-ctl --device=$device --get-audio-input | grep 'RCA' )" = "$in1txt" ] || [ "$(v4l2-ctl --device=$device --get-audio-input | grep 'SPDIF' )" = "$in2txt" ]	# check to see if any RCA input is being used
			then
				echo ""
				echo " changing audio input..."
				echo -n " " && v4l2-ctl --device=$device --set-audio-input=$audioinputnum
				echo -n " " && v4l2-ctl --device=$device --get-audio-input
				echo -n " New config: $audioencoding on " && v4l2-ctl --device=$device --get-audio-input
				echo ""
				exit 1
		fi
fi



#If RCA front (1) was chosen and not used, make the change.
if [ $audioinputnum = 1 ]
	then 
		if [ "$(v4l2-ctl --device=$device --get-audio-input | grep 'RCA' )" = "$in0txt" ] || [ "$(v4l2-ctl --device=$device --get-audio-input | grep 'SPDIF' )" = "$in2txt" ]	# check to see if any RCA input is being used
			then
				echo ""
				echo " changing audio input..."
				echo -n " " && v4l2-ctl --device=$device --set-audio-input=$audioinputnum
				echo -n " " && v4l2-ctl --device=$device --get-audio-input
				echo -n " New config: $audioencoding on " && v4l2-ctl --device=$device --get-audio-input
				echo ""
				exit 1
		fi
fi



#If spdif/optical (2) was chosen and not used, make the change.
if [ $audioinputnum = 2 ]
	then 
		if [ "$(v4l2-ctl --device=$device --get-audio-input | grep 'RCA' )" = "$in0txt" ] || [ "$(v4l2-ctl --device=$device --get-audio-input | grep 'RCA' )" = "$in1txt" ]	# check to see if any RCA input is being used
			then
				echo ""
				echo " changing audio input..."
				echo -n " " && v4l2-ctl --device=$device --set-audio-input=$audioinputnum
				echo -n " " && v4l2-ctl --device=$device --get-audio-input
				echo -n " New config: $audioencoding on " && v4l2-ctl --device=$device --get-audio-input
				echo ""
				exit 1
		fi
fi




#If aac (3) was chosen and not used, make the change.
if [ $audioinputnum = 3 ] && [ $audioencoding = "ac3" ] 
	then
		echo ""
		echo " changing audio encoding..."
		v4l2-ctl --device=$device --set-ctrl=audio_encoding=$audioinputnum
		echo -n " New config: aac on " && v4l2-ctl --device=$device --get-audio-input
		echo ""
		exit 1
fi



#If ac3 (4) was chosen and not used, make the change.
if [ $audioinputnum = 4 ] && [ $audioencoding = "aac" ] 
	then
		echo ""
		echo " changing audio encoding..."
		v4l2-ctl --device=$device --set-ctrl=audio_encoding=$audioinputnum
		echo -n " New config: ac3 on " && v4l2-ctl --device=$device --get-audio-input
		echo ""
		exit 1
fi



echo " no change made" # must be set correctly
echo ""
