#!/bin/bash

# Help
if [ $# -lt 1 ] || [ $1 == "-h" ] || [ $1 == "--help" ]; then
	echo -e "\033[34mAuto Vulnerability Scan for docker images with\033[33m GRYPE\033[0m"
	echo ""
	echo "-h, --help						  Print help"
	echo "[MODES]"
	echo "-ai, --all-image				    Scan all installed docker image for vulnerabilities "
	echo "-ac, --all-container	      			Scan  all containers for image vulnerabilities"
	echo ""
	echo "[OPTIONS]"
	echo "-v, --verbose					      Detail of the output scan execution"
	echo "-o, --output						Path output for each files result of the scan, if the directory doesn't exist, he is created"
	echo "-c, --config						Grype configuration file
												Default configuration search paths:
    													.grype.yaml
    													.grype/config.yaml
    													~/.grype.yaml
    													<XDG_CONFIG_HOME>/grype/config.yaml
	"
	echo "-f, --format 						Format [Default : table]
												Available format :											
    													table: 					A columnar summary (default).
    													cyclonedx: 			 An XML report conforming to the CycloneDX 1.4 specification.
    													cyclonedx-json: 	  A JSON report conforming to the CycloneDX 1.4 specification.
    													json: 					Use this to get as much information out of Grype as possible!
	"
	echo ""
	echo -e "Usage : \033[36m$0 [MODES] [OPTIONS]\033[0m"
	exit
fi

# Arguments management
MODE=""
VERBOSE=false
OUTPUT=""
CONFIG=""
FORMAT="table"
while (($#)); do
	case $1 in
		-ai|--all-image)
			MODE="--all-image"
			shift
			;;
		-ac|--all-container)
			MODE="--all-container"
			shift
			;;
		-v|--verbose)
			VERBOSE=true
			shift
			;;
		-o|--output)
			if [ -z $2 ]; then
				echo "Output path is missing"
				exit 1
			fi
			OUTPUT="$2"
			# Check if the output directory exist and create it if it doesn't with root access permision
			if [ ! -d $OUTPUT ]; then
				sudo mkdir -p $OUTPUT
       				sudo chmod 700 $OUTPUT
			fi
			shift 2
			;;
		-c|--config)
			if [ -z $2 ]; then
				echo "Configuration file is missing"
				exit 1
			fi
			if [ ! -f $2 ]; then
				echo "The specified file doesn't exist"
				exit 1
			fi
			CONFIG=$2
			shift 2
			;;
		-f|--format)
			FORMAT="$2"
			shift 2
			;;
		*)
			echo "Unrecognized argument : $1"
			exit 1
			;;
	esac
done


# Quick scan function for image vulnerabilities with GRYPE
vuln_scan() {
	local IMAGES=$1
	local VERBOSE=$2
	local OUTPUT=$3
	local CONFIG=$4
	local FORMAT=$5
	
	if [ $VERBOSE == true  ]; then
	TIME_START=$(date +%s)
		if [ ! -z $OUTPUT ]; then
			if [ ! -z $CONFIG ]; then
				for IMAGE in $IMAGES; do
					echo -e "\033[34m[$(date -u +"%Y-%m-%d %H:%M UTC")]\033[0m Quick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -c $CONFIG | sudo tee "$OUTPUT/$(date -u +"%Y%m%d-%H:%M")_$IMAGE.$FORMAT"
					echo ""
				done
			else
				for IMAGE in $IMAGES; do
					echo -e "\033[34m[$(date -u +"%Y-%m-%d %H:%M UTC")]\033[0m Quick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -o $FORMAT --scope all-layers | sudo tee "$OUTPUT/$(date -u +"%Y%m%d-%H:%M")_$IMAGE.$FORMAT"
					echo ""
				done
			fi
		else
			if [  ! -z $CONFIG  ]; then
				for IMAGE in $IMAGES; do	
					echo -e "\033[34m[$(date -u +"%Y-%m-%d %H:%M UTC")]\033[0m Quick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -c $CONFIG
					echo ""
				done
			else
				for IMAGE in $IMAGES; do	
					echo -e "\033[34m[$(date -u +"%Y-%m-%d %H:%M UTC")]\033[0m Quick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -o $FORMAT --scope all-layers
					echo ""
				done		
			fi
		fi
	TIME_DIFF=$[ $(date +%s) - $TIME_START ]
	echo -e "Time to scan : \033[36m$TIME_DIFF secondes\033[0m"		
	else 
		if [ ! -z $OUTPUT ]; then
			if [ ! -z $CONFIG ]; then
				for IMAGE in $IMAGES; do
					echo -e "\033[34mQuick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -c $CONFIG | sudo tee "$OUTPUT/$(date -u +"%Y%m%d-%H:%M")_$IMAGE.$FORMAT"
					echo ""
				done
			else
				for IMAGE in $IMAGES; do
					echo -e "\033[34mQuick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -o $FORMAT --scope all-layers | sudo tee "$OUTPUT/$(date -u +"%Y%m%d-%H:%M")_$IMAGE.$FORMAT"
					echo ""
				done
			fi
		else
			if [ ! -z $CONFIG ]; then
				for IMAGE in $IMAGES; do
					echo -e "\033[34mQuick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -c $CONFIG
					echo ""
				done
			else
				for IMAGE in $IMAGES; do
					echo -e "\033[34mQuick Vulnerability Scan for \033[33m$IMAGE\033[0m"
					grype $IMAGE -o $FORMAT --scope all-layers
					echo ""
				done
			fi
		fi	
	fi
}

# Scan for all container image
if [ $MODE == "--all-container" ]; then
	IMAGES=$(sudo docker ps -a --format "{{.Image}}")
	vuln_scan "$IMAGES" "$VERBOSE" "$OUTPUT" "$CONFIG" "$FORMAT"

# Scan for all installed docker image
elif [ $MODE == "--all-image" ]; then
	IMAGES=$(sudo docker images --format "{{.Repository}}:{{.Tag}}")
	vuln_scan "$IMAGES" "$VERBOSE" "$OUTPUT" "$CONFIG" "$FORMAT"
fi
