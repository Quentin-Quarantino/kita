#!/bin/bash

# disk2img2disk
# Script by Cedrick Z
minus='---------------------------------------------------------------------------------------------------'
osvg=osvg
imgFolder='/opt/images/'
toDay=$(date +"%Y%m%d")
nImgName='raw'
version='v2.1'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELL='\033[0;33m'
BLUE='\033[1;34m'
NC='\033[0m'

clear
echo -e "
$BLUE#                                  $YELL                            ╒,* ╥@╩╩╩ÑN
$BLUE#                                  $YELL                             \`@.▓\`      ╫⌐
$BLUE#                                  $YELL                               ╘▓       ╓,
$BLUE#                                  $YELL                                \"╩@m $BLUE╗╝\"  \"╨N ╙⌐─
$BLUE#    ╓╓    ╓╓                      $YELL                                    $BLUE║[      ]╣ \`
$BLUE#    ╢▒  ╓╣╜   ]╢\[               ║╢$YELL  \]╢╩╙╨▓@        j▓┐                $BLUE╙╣     ,╢╜  $YELL,
$BLUE#    ║▒╓╣╝            ,          ╢╣$YELL  ]╢∩  ╫▓         ╟▓         ╫▓       $BLUE╙╝Ñ%╝╙  $YELL ]╢,
$BLUE#    ║▒╚╢╖      ▒  ▒╣╜\`╙╢╕  @╣╜╨h▒[$YELL  ]╢▓╨╨╩▓╗  ╓@ÑÑ@, ╫▓  ,@   ╬▓ ╓@Ñ@╦    ╓╥╖, , ╠╢Ö\"
$BLUE#    ║▒  ╚╣╖   j▒  ╢╣   ╣║ ╢╢    ▒[$YELL   ╢Γ   ]╢∩]╢@ææ╬▓  ╫▓,▓╫▓,▓Ñ ╟╢╦╦╦╬╣  ▓╩  ╫▓╙ ]╢
$BLUE#    ║╣    ╨Ñ~ ]╣  ╢╢   ╢╢ └╣╖²,@╣[$YELL   ╢▓╥╦@▓╝  ▓N²  ,   ▓▓  ╟╢╝  └▓╗   ,  ╫▓æ@▓\`   ▓@╥
$BLUE#                             \`    $YELL   ²          ╙╙╙\`        \"     \`╙╙╙\`  ▓@,²
$BLUE# $YELL    RaspberryPI Image Creator     $YELL                                      .▓╝``╙╩▓╕
$BLUE#    by C.Z                        $YELL                                       ▓▓╥╖╥@▓╛ $NC" 

#Check if root
if [ `whoami` != root ] ;then
	printf "\n\n$RED [!] you must be root! $NC\n [-] exit scrip without doing something...\n$minus\n\n"
	exit 1
fi

checkDev ()
{
	clear
        printf "\n$YELL -> check attached SD disk$NC \n\n [+] Task: check attached SD disk\n\n$minus\n\n [-] check filesystem\n"
	rootDev=`lsblk |grep $osvg -B5 |grep -v $osvg| awk {'print $1'} |egrep '^.[a-z]'`
	echo ' [-] check for attached SCSI removable disk'
	newSD=`grep -Ff <(hwinfo  --disk --short) <(hwinfo --usb --short) |grep -v 'disk:' |awk '{print $1}'`
#       newSD=`dmesg |grep ' sd.*Attached SCSI removable disk' |awk '{print $5}' |awk -F '[' '{print $2}' |awk -F ']' '{print $1}' |tail -n 1`
	if [ -z ${newSD+x} ] ;then
		printf "\n\n$RED [!] nothing found... please check if the device connectet\n $NC"
		exit 1
	fi
	if [ `echo $newSD |wc -w ` -ge 2 ] ;then
		printf "\n\n $RED [!] more than 1 usb device found, to be on the safe side the script is aborted\n\n $NC"
		exit 1
	fi
	printf " [-]$GREEN found: $newSD $NC \n$minus\n\n"
}

checkIMG () 
{
	if [[ -z $(ls -lt $imgFolder |grep ^- ) ]] ;then
                printf " [-] You don't have any images in the image folder yet... \n [-] Check the variables or the folder \n [!]$RED script aborted without doing anything.$NC\n$minus\n\n"
                exit 1
        fi
}

rmOldParts ()
{
	clear
	printf "\n$GREEN -> check attached SD disk >$YELL remove old partitions$NC \n\n [+] Task: remove old partitions\n\n$minus\n\n [-] count old partitions\n"
	oldParts=`fdisk -l $newSD |grep ^/dev |awk '{print $1}'`
	printf " [-]$RED remove old partitions in 10 seconds\n$NC [-]$RED press 'CTRL + C' if you want to abort\n$NC" ;sleep 11 
	for i in $oldParts ;do echo -e 'd\n\nw\n ' |fdisk $newSD 2&>/dev/null ;done
	printf " [-] all partitions deleted\n$minus\n\n"
}

img2sd ()
{
	clear
	printf "\n$GREEN -> check attached SD disk > remove old partitions > choose image >$YELL copy image on SD $NC \n [+] Task: copy image on SD\n\n$minus\n\n [-] this will take a lot of time... get yourself a coffee... this step takes about 20 - 40 minutes\n\n"
	dd if=$img of=$newSD status=progress
	printf "\n [-]$GREEN done$NC\n$minus\n\n"
        sleep 5
        Device=`echo $newSD |tr '/' ' ' |awk '{print $2}'`
        echo 1 >/sys/class/block/$Device/device/delete 2&>/dev/null

}

chooseIMG ()
{
	clear
	printf "\n$GREEN -> check attached SD disk > remove old partitions >$YELL choose image$NC \n\n [+] Task: choose image\n\n$minus\n\n"
	c=0
	count=0
	while [ "$c" == "0" ] && [ "$count" != "3" ]
	do
		printf " [?] do you want to use the latest image; $(ls -lt $imgFolder |grep ^- |head -n 1 |awk '{print $9}')$GREEN y$NC =$GREEN yes$RED n$NC =$RED no$NC ;" ; read -p " " yesNo
		if [[ "$yesNo" == "yes" ]] || [[ "$yesNo" == "y" ]] ;then
			imgFile=`ls -lt $imgFolder |grep ^- |awk '{print $9}' |head -n 1`
			img="$imgFolder$imgFile"
			echo
			c=1
			count=3
		fi
		if [[ "$yesNo" == "no" ]] || [[ "$yesNo" == "n" ]] ;then
			printf " [-] list of available images:\n\n "
			ls -lt $imgFolder |grep ^- |awk '{print $9}'
			read -p " [-] select an image: " tstImg
			if [ -f $imgFolder$tstImg ] ;then
				img="$imgFolder$tstImg"
				echo ' [-]$GREEN image selected $NC'
				c=1
			else
				echo "$RED [!] image not found... try again $NC "
			fi
		fi
		count=$((count+1))
	done
}

sd2img ()
{
	clear
        printf "\n$GREEN -> check attached SD disk >$YELL create image from SD card$NC \n\n [+] Task: create image from SD card\n\n$minus\n\n \n"
	np="$imgFolder$nImgName-$toDay"
	if [ ! -d /opt/images ] ;then
		echo " [-] folder $imgFolder not found"
		mkdir /opt/images
		echo " [-] $imgFolder created"
	fi
	Size=`fdisk -l --bytes $newSD |grep ^$newSD  |awk '{print $5}' |tail -1`
	SIZE=$(($Size/1000000))
	printf " [-] size of partition is : $SIZE M\n [-] read the last used sector\n"
	endSek=`fdisk -l $newSD |grep ^$newSD  |awk '{print $3}' |tail -1`
	echo ' [-] extend the value by 1000 for safety'
	rEnd=$(($endSek+1000))
        echo ' [-] find mountpoints and umonut it!'
        um=`echo $newSD |tr '/' ' ' |awk '{print $2}'`
        um1=`lsblk |egrep $um.*part |awk '{print $7}'`
	if [ ! -z "$um1" ] ;then
		 umount $um1
	fi
	um1=`lsblk |egrep $um.*part |awk '{print $7}'`
	if [ -z "$um1" ] ;then
		 printf " [-]$GREEN umount successfully$NC\n"
	else
		count=0
		while [ ! -z "$um1" ] || [ "$count" == "3" ]
		do
			echo ' [!] try force umount'
			umount -f $um1 
			count=$((count+1))
			um1=`lsblk |egrep $um.*part |awk '{print $7}'`
		done
		if [ ! -z "$um1" ] ;then
		       printf "$RED\n [!] umount cannot be performed\n [!] try to do this manually and with the following command this step can be done:\n$NC [-] check manually if the name is already assigned\n\n [c] dd if=$newSD  of=/opt/images/$nImgName-$toDay.img count=$rEnd status=progress \n\n $RES [!] Do nothing if you dont know what you do... $NC \n$minus"
		       exit 1
	       fi
       fi
       if [ -f /opt/images/$nImgName-$toDay.img ] ;then
               printf "\n$minus\n$RED [!] name is already taken - name: $nImgName-$toDay.img\n$NC"
               printf " [?] do you want to$RED overwrite$NC it or give it a$GREEN unique$NC name?$RED o$NC =$RED overwrite$NC /$GREEN u$NC =$GREEN unique$NC\: " ;read -p " " ans
	       if [ $ans == "u" ] || [ $ans == "unique:" ] ;then
			np="/opt/images/$nImgName-$toDay"
			c=1
			nppc=$np-$c
			while [ -f $nppc.img ]
			do
				c=$((c+1))
				nppc=$np-$c
			done
		      echo " [-] create new image: $nppc.img"
	              dd if=$newSD  of=$nppc.img count=$rEnd status=progress
		      printf " [-]$GREEN done $NC \n [-] check image\n"
		      cmp -l $newSD $nppc.img -n $rEnd
		      printf "\n$minus\n\n"
		      exit 1
		fi	
                if [ "$ans" == "o" ] || [ "$ans" == "overwrite" ] ;then
                       echo test
                        rm -f /opt/images/$nImgName-$toDay.img 2>/dev/null
			p="/opt/images/$nImgName-$toDay"
	                echo " [-] create new image: $np.img"
              		dd if=$newSD  of=$np.img count=$rEnd status=progress
	                printf " [-]$GREEN done$NC \n [-] check image \n"
	                cmp -l $newSD $np.img -n $rEnd
 			printf "\n$minus\n\n"
 	                exit 1
                fi
       else
	       np="/opt/images/$nImgName-$toDay"
	       echo " [-] create new image: $np.img"
	       dd if=$newSD  of=$np.img count=$rEnd status=progress
	       printf " [-]$GREEN done$NC \n [-] check image \n"
               cmp -l $newSD $np.img -n $rEnd
               printf "\n$minus\n\n"
               exit 1
       fi
       sleep 5
       Device=`echo $newSD |tr '/' ' ' |awk '{print $2}'`
       echo 1 >/sys/class/block/$Device/device/delete 2&>/dev/null
}

usage ()
{
	printf "not ready yet"
}

### Main:
##---------------------------------------------------------------------------------------------------
sleep 2 
A=${1,2,3,4}
while [[ "$q1" != "1" && "$q1" != "2" && "$q1" != "3" && "$q1" != "4" ]] 
do
	if [ "$count" -eq "3" ] ; then
		echo "exit scrip without doing something.."
		exit 1
	fi
	clear
	printf "\n$minus\n\n [ 1 ] copy a image on SD card\n [ 2 ] create new image\n [ 3 ] check attached SD disk\n [ 4 ] info and help\n\n$minus\n "
	read -p "enter a number: " q1 
	count=$((count+1))
done
case "$q1" in
	1)
		checkDev
		checkIMG
		rmOldParts
                chooseIMG
		img2sd
		exit 1
	;;
	2)
		checkDev
		sd2img
		exit 1
	;;
	3)
		checkDev
		exit 1
	;;
	4)
		usage
		exit 1
esac
exit 1

