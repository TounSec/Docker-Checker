#!/bin/bash

# HELP
if [ $# -lt 1 ] || [ $1 == "-h" ] || [ $1 == "--help" ]; then
	echo -e "\033[34mAuto implementation of \033[0m\033[36mdocker_checker.sh\033[0m in the \033[33mcrontab\033[0m"
	echo ""
	echo "-h, --help															 Print help"
	echo "-sp,--script-path													Absolut path of the docker_checker.sh script"
	echo ""
	echo "[OPTION]"
	echo "-sa, --script-arguments												The docker_check.sh arguments [Default : -ac]"
	echo "-ti, --time-interval													Time interval at which the script should be executed [Default : 0 0 * * *]"
	echo ""
	echo -e "Usage : \033[36m$0 -sp <SCRIPT_PATH> [OPTION]\033[0m"
	exit
fi

SCRIPT_PATH=""
SCRIPT_ARGUMENTS="-ac"
TIME_INTERVAL="0 0 * * *"
while (($#)); do
	case $1 in
		-sp|--script-path)
			if [ -z $2 ]; then
				echo "Script path is missing"
				exit 1
			elif [ ! -f $2 ]; then
				echo "Script path doesn't exist"
				exit 1
			elif [ ! -x $2 ]; then
				echo "Script path doesn't executable"
				exit 1
			fi
			SCRIPT_PATH=$2
			shift 2
			;;
		-sa|--script-arguments)
			if [ -z $2 ]; then
				echo "Script arguments is missing"
				exit 1
			fi
			SCRIPT_ARGUMENTS=$2
			shift 2
			;;
		-ti|--time-interval)
			if [ -z $2 ]; then
				echo "TIme interval is missing"
				exit 1
			fi
			TIME_INTERVAL=$2
			shift 2
			;;
		*)
			echo "Unreconignized argument : $1"
			exit 1
			;;
	esac
done

# Add script in the crontab
(sudo crontab -l 2>/dev/null; echo "$TIME_INTERVAL $SCRIPT_PATH $SCRIPT_ARGUMENTS") | sudo crontab -
echo -e "\033[36mThe script has been added to the crontab\033[0m"
