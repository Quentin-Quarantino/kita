#!/bin/bash

# disk2img2disk
# Script by Cedrick Z

minus='---------------------------------------------------------------------------------------------------'
osvg=osvg
imgFolder='/opt/images/'
toDay=$(date +"%Y%m%d")
nImgName='raw'
version='v0.2'


clear
echo -e '
\033[1;34m                                  \033[0;33m                            ╒,* ╥@╩╩╩ÑN
\033[1;34m                                  \033[0;33m                             `@.▓`      ╫⌐
\033[1;34m                                  \033[0;33m                               ╘▓       ╓,
\033[1;34m                                  \033[0;33m                                "╩@m \033[1;34m╗╝"  "╨N ╙⌐─
\033[1;34m    ╓╓    ╓╓                      \033[0;33m                                    \033[1;34m║[      ]╣ `
\033[1;34m    ╢▒  ╓╣╜   ]╢[               ║╢\033[0;33m  ]╢╩╙╨▓@        j▓┐                \033[1;34m╙╣     ,╢╜  \033[0;33m,
\033[1;34m    ║▒╓╣╝            ,          ╢╣\033[0;33m  ]╢∩  ╫▓         ╟▓         ╫▓       \033[1;34m╙╝Ñ%╝╙  \033[0;33m ]╢,
\033[1;34m    ║▒╚╢╖      ▒  ▒╣╜`╙╢╕  @╣╜╨h▒[\033[0;33m  ]╢▓╨╨╩▓╗  ╓@ÑÑ@, ╫▓  ,@   ╬▓ ╓@Ñ@╦    ╓╥╖, , ╠╢Ö"
\033[1;34m    ║▒  ╚╣╖   j▒  ╢╣   ╣║ ╢╢    ▒[\033[0;33m   ╢Γ   ]╢∩]╢@ææ╬▓  ╫▓,▓╫▓,▓Ñ ╟╢╦╦╦╬╣  ▓╩  ╫▓╙ ]╢
\033[1;34m    ║╣    ╨Ñ~ ]╣  ╢╢   ╢╢ └╣╖²,@╣[\033[0;33m   ╢▓╥╦@▓╝  ▓N²  ,   ▓▓  ╟╢╝  └▓╗   ,  ╫▓æ@▓`   ▓@╥
\033[1;34m                             `    \033[0;33m   ²          ╙╙╙`        "     `╙╙╙`  ▓@,²
    RaspberryPI Image Creator     \033[0;33m                                      .▓╝``╙╩▓╕
\033[1;34m    by C.Z                        \033[0;33m                                       ▓▓╥╖╥@▓╛ \033[0m '
echo

#Check if root
if [ `whoami` != root ] ;then
	echo "    you must be root! exit scrip without doing something.."
	exit 1
fi

#checkDep ()
#{
#	echo '    Check OS'
#	ls -l /etc/ |egrep 'centos|red-hat' ||echo ''
#	rpm -qa |grep hwinfo
#}

checkDev ()
{
	echo 'check filesystem'
	rootDev=`lsblk |grep $osvg -B5 |grep -v $osvg| awk {'print $1'} |egrep '^.[a-z]'`
	echo 'check for attached SCSI removable disk'
	newSD=`grep -Ff <(hwinfo  --disk --short) <(hwinfo --usb --short) |grep -v 'disk:' |awk '{print $1}'`
#       newSD=`dmesg |grep ' sd.*Attached SCSI removable disk' |awk '{print $5}' |awk -F '[' '{print $2}' |awk -F ']' '{print $1}' |tail -n 1`
	if [ -z ${newSD+x} ] ;then
		echo
		echo 'nothing found... please check if the device connectet'
		echo
		exit 1
	fi
	if [ `echo $newSD |wc -w ` -ge 2 ] ;then
		echo
		echo 'more than 1 usb device found, to be on the safe side the script is aborted'
		echo
		exit 1
	fi
	echo "found: $newSD"
	echo $minus
	echo
}

rmOldParts ()
{
	echo 'count old partitions'
#	 osdSize=`fdisk -l $newSD |grep GiB |awk '{print $3}'`
	oldParts=`fdisk -l $newSD |grep ^/dev |awk '{print $1}'`
	echo 'remove old partitions'
	for i in $oldParts ;do `echo -e 'd\n\nw\n ' |fdisk $newSD` 1&2>/dev/null ;done
	echo 'all partitions deleted'
}

img2sd ()
{
	echo 'copy img to the SD'
	echo 'this will take a lot of time... get yourself a coffee... this step takes about 30 - 40 minutes'
	echo
	dd if=$img of=$newSD status=progress
	echo
	echo 'done'
	echo
	echo $minus
	echo
}

chooseIMG ()
{
	c=0
	count=0
	while [ "$c" == "0" ] && [ "$count" != "3" ]
	do
		read -p "do you want to use the latest image;
$(ls -lt $imgFolder |grep ^- |head -n 1)
y=yes n=no ;   " yesNo
		if [ $yesNo == "yes" ] || [ $yesNo == "y" ] ;then
			imgFile=`ls -lt $imgFolder |grep ^- |awk '{print $9}' |head -n 1`
			img="$imgFolder$imgFile"
			echo
			c=1
			count=3
		fi
		if [ $yesNo == "no" ] || [ $yesNo == "n" ] ;then
			echo 'list of available images: '
			echo
			ls -lt $imgFolder |grep ^- |awk '{print $9}'
			read -p "select an image: " tstImg
			if [ -f $imgFolder$tstImg ] ;then
				img="$imgFolder$tstImg"
				echo 'image selected'
				c=1
			else
				echo 'image not found... try again'
			fi
		fi
		count=$((count+1))
	done
}

sd2img ()
{
	np="$imgFolder$nImgName-$toDay"
	if [ ! -d /opt/images ] ;then
		echo "folder $imgFolder not found"
		mkdir /opt/images
		echo "$imgFolder created"
	fi
	echo 'read the last used sector'
	endSek=`fdisk -l $newSD |tail -n 1 |awk '{print $3}'`
	echo 'extend the value by 1000 for safety'
	rEnd=$(($endSek+1000))
        echo 'find mountpoints and umonut it!'
        um=`echo $newSD |tr '/' ' ' |awk '{print $2}'`
        um1=`lsblk |egrep $um.*part |awk '{print $7}'`
	if [ ! -z `lsblk |egrep $um.*part |awk '{print $7}'` ] ;then
		 umount $um1
	fi

	if [ -z `lsblk |egrep $um.*part |awk '{print $7}'` ] ;then
		echo 'umount successfully'
	else
		count=0
		while [ ! -z `lsblk |egrep $um.*part |awk '{print $7}'` ] || [ "$count" == "3" ]
		do
			echo 'try force umount'
			umount -f $um1
			count=$((count+1))
		done
		if [ ! -z `lsblk |egrep $um.*part |awk '{print $7}'` ] ;then
		       echo 'umount cannot be performed'
		       echo 'Try to do this manually and with the following command this step can be done:'
		       echo 'check manually if the name is already assigned'
		       echo
		       echo "dd if=$newSD  of=/opt/images/$nImgName-$toDay.img count=$rEnd status=progress"
		       echo
		       echo "Do nothing if you dont know what you do... "
		       echo $minus
		       exit 1
	       fi
       fi
       if [ -f /opt/images/$nImgName-$toDay.img ] ;then
               echo 'name is already taken'
               read -p "do you want to overwrite it or give it a unique name (name-number)? o=overwrite / u=unique: " ans
                if [ $ans == "o" ] || [ $ans == "overwrite" ] ;then
			rm -f /opt/images/$nImgName-$toDay.img 2>/dev/null
                fi
                if [ $ans == "u" ] || [ $ans == "unique:" ] ;then
			np="/opt/images/$nImgName-$toDay"
			c=1
			nppc=$np$c
			while [ -f $nppc.img ]
			do
				c=$((c+1))
				nppc=$np$c
			done
		      echo "create new image: $nppc.img"
	              dd if=$newSD  of=$nppc.img count=$rEnd status=progress
		      echo 'done'
		      echo 'check image'
		      cmp -l $newSD $nppc.img -n $rEnd
		      echo $minus
		      echo
		      exit 1
		fi

       else
	       np="/opt/images/$nImgName-$toDay"

	       echo "create new image: $np.img"
	       touch $np.img
		echo "$np.img"
	       dd if=$newSD  of=$np.img count=$rEnd status=progress
	       echo 'done'
	       echo 'check image'
               cmp -l $newSD $np.img
               echo $minus
               echo
               exit 1

       fi
}

usage ()
{
	echo
	echo "$0 $version"
	echo
	echo $minus
	echo '
SYNOPSIS'
	echo "	$0 [OPTIONS]"
	echo '
	-h, -help	output a usage message and exit.
	-c, -check	check for attached SCSI removable disk
	-s, -sd2img	check and create new image
	-i, -img2sd	check, remove all from the sd an put a new image on it'
	echo
	echo "osvg=osvg
imgFolder='/opt/images/'
"
	echo $minus
	echo
}

### Main:
##---------------------------------------------------------------------------------------------------
sleep 2 ;clear

echo "
 \[ 1 \] copy a new image on SD card
 \[ 2 \] create new image
 \[ 3 \] check attached SD disk
 \[ 4 \] info and help"
