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
	echo "-f, --format 						Format
												Available format :											
    													table: 					A columnar summary (default).
    													cyclonedx: 			 An XML report conforming to the CycloneDX 1.4 specification.
    													cyclonedx-json: 	  A JSON report conforming to the CycloneDX 1.4 specification.
    													json: 					Use this to get as much information out of Grype as possible!
"
	echo ""
	echo "Usage : ./docker_image_checker.sh [MODES] [OPTIONS]"
	exit
fi

# Arguments management
MODE=""
VERBOSE=false
OUTPUT=""
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
			if [ -z $2 ] || [ ${2:0:1} == "-" ]; then
				echo "Output path is missing or invalid after -o|--output option"
				exit 1
			fi
			OUTPUT="$2"
			shift 2
			;;
		-f|--format)
			FORMAT="$2"
			shift 2
			;;
		*)
			echo "Unrecognized argument : $arg"
			exit 1
			;;
	esac
done

# Check if the output directory exist and create it if it doesn't
if [ ! -z $OUTPUT ]; then
	mkdir -p $OUTPUT
fi

# Quick scan function for image vulnerabilities with GRYPE
vuln_scan() {
	local IMAGES=$1
	local VERBOSE=$2
	local OUTPUT=$3
	local FORMAT=$4
	
	if [ $VERBOSE == true  ]; then
		if [ ! -z $OUTPUT ]; then
			for IMAGE in $IMAGES; do
				echo -e "\033[34m[$(date -u +"%Y-%m-%d %H:%M UTC")]\033[0m Quick Vulnerability Scan for \033[33m$IMAGE\033[0m"
				TIME_START=$(date +%s)
				grype $IMAGE -o $FORMAT | tee "$OUTPUT/$(date -u +"%Y%m%d-%H:%M")_$IMAGE.$FORMAT"
				echo ""
			done
		else
			for IMAGE in $IMAGES; do	
				echo -e "\033[34m[$(date -u +"%Y-%m-%d %H:%M UTC")]\033[0m Quick Vulnerability Scan for \033[33m$IMAGE\033[0m"
				TIME_START=$(date +%s)
				grype $IMAGE -o $FORMAT
				echo ""
			done
		fi
			TIME_DIFF=$[ $(date +%s) - $TIME_START ]
			echo -e "Time to scan : \033[36m$TIME_DIFF secondes\033[0m"		
	else 
		if [ ! -z $OUTPUT ]; then
			for IMAGE in $IMAGES; do
				echo -e "\033[34mQuick Vulnerability Scan for \033[33m$IMAGE\033[0m"
				grype $IMAGE -o $FORMAT | tee "$OUTPUT/$(date -u +"%Y%m%d-%H:%M")_$IMAGE.$FORMAT"
				echo ""
			done
		else
			for IMAGE in $IMAGES; do
				echo -e "\033[34mQuick Vulnerability Scan for \033[33m$IMAGE\033[0m"
				grype $IMAGE -o $FORMAT
				echo ""
			done
		fi	
	fi
}

# Scan for all container image
if [ $MODE == "--all-container" ]; then
	IMAGES=$(sudo docker ps -a --format "{{.Image}}")
	vuln_scan "$IMAGES" "$VERBOSE" "$OUTPUT" "$FORMAT"

# Scan for all installed docker image
elif [ $MODE == "--all-image" ]; then
	IMAGES=$(sudo docker images --format "{{.Repository}}:{{.Tag}}")
	vuln_scan "$IMAGES" "$VERBOSE" "$OUTPUT" "$FORMAT"
fi
