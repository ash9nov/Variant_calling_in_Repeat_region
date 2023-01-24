#!/bin/bash

# This script is only working to find variant located at 2:47641560
# If there is a variant, the variant will be attached at the end of the VCF file

# Has tested at the following cases:
# 2:47641560 507 507.00 507 A:0 C:0 G:506 T:1 N:0 -> 1/1
# 2:47641560 507 507.00 507 A:0 C:299 G:207 T:1 N:0 -> 1/2
# 2:47641560 507 507.00 507 A:299 C:0 G:207 T:1 N:0 -> 0/1


# get files from command line
DEP=$1 # the result from DepthOfCoverage
VCF=$2 # the original vcf file

# get the read count line from result of DepthOfCoverage
VARIANT=`grep '2:47641560' $DEP`
#ARR=($VARIANT)
ARR=($(echo "$VARIANT"|tr ',' '\n'))

# If there is reads at the position: 2:47641560
if [ ! -z "${ARR[0]}" ]; then
    DP=${ARR[1]}
    COUNTA=`echo ${ARR[4]}|cut -f2 -d':'`
    COUNTC=`echo ${ARR[5]}|cut -f2 -d':'`
    COUNTG=`echo ${ARR[6]}|cut -f2 -d':'`
    COUNTT=`echo ${ARR[7]}|cut -f2 -d':'`

    # calculate the reference base ratio
    RATIO=`echo "scale=2;($COUNTA/$DP)"|bc`

    # if the reference base ratio is between 0.25 and 0.75, to predict 0/1 case
    # find out which the alternative allele and the depth of htat allele
    if (( $(bc <<< "$RATIO > 0.25") )) && (( $(bc <<< "$RATIO < 0.75") )); then
	MAX=0
	if [ $COUNTG -ge $COUNTC ] && [ $COUNTG -ge $COUNTT ]; then
	    ALT='G'
	    ADD=$COUNTG
	    MAX=$COUNTG
	fi

	if [ $COUNTC -ge $COUNTG ] && [ $COUNTC -ge $COUNTT ] && [ $COUNTC -ge $MAX ]; then
	    ALT='C'
	    ADD=$COUNTC
	fi

	if [ $COUNTT -ge $COUNTC ] && [ $COUNTT -ge $COUNTG ] && [ $COUNTT -ge $MAX ]; then
	    ALT='T'
	    ADD=$COUNTT
	fi

	echo -e "2\t47641560\t.\tA\t$ALT\t0\tLowQual\tDP=$DP\tGT:AD:DP\t0/1:$COUNTA,$ADD:$DP" >> $VCF

    # if the reference base ratio is < 0.25, very seldom though, try to predict 1/1 or 1/2
    # very naive way, if any base has ratio > 0.25, will be count as alternative allele
    # If there is only one base counted, then it is 1/1 case
    # If there are two bases counted, then it is 1/2 case
    elif (( $(bc <<< "$RATIO < 0.25") )); then

	RATIOG=`echo "scale=2;($COUNTG/$DP)"|bc`
	RATIOC=`echo "scale=2;($COUNTC/$DP)"|bc`
	RATIOT=`echo "scale=2;($COUNTT/$DP)"|bc`

	if (( $(bc <<< "$RATIOG > 0.25") )); then
	    ((ALTCOUNT++))
	    if [ -z "$ALT" ]; then
		ALT="G"
		ADD=$COUNTG
	    else
		ALT+=",G"
		ADD+=",$COUNTG"
	    fi
	fi

	if (( $(bc <<< "$RATIOC > 0.25") )); then
	    ((ALTCOUNT++))
	    if [ -z "$ALT" ]; then
		ALT="C"
		ADD=$COUNTC
	    else
		ALT+=",C"
		ADD+=",$COUNTC"
	    fi
	fi

	if (( $(bc <<< "$RATIOT > 0.25") )); then
	    ((ALTCOUNT++))
	    if [ -z "$ALT" ]; then
		ALT="T"
		ADD=$COUNTT
	    else
		ALT+=",T"
		ADD+=",$COUNTT"
	    fi
	fi

	if [ $ALTCOUNT -eq 1 ]; then
	    echo -e "2\t47641560\t.\tA\t$ALT\t0\tLowQual\tDP=$DP\tGT:AD:DP\t1/1:$COUNTA,$ADD:$DP" >> $VCF
	elif [ $ALTCOUNT -eq 2 ]; then
	    echo -e "2\t47641560\t.\tA\t$ALT\t0\tLowQual\tDP=$DP\tGT:AD:DP\t1/2:$COUNTA,$ADD:$DP" >> $VCF
	fi

    fi

fi
