#!/bin/bash
#------------------------------------------------------------------------------#
#
# Description
#   This file is called from DAKOTA each loop
#   deprepro copies the file 0/p.dakota to 0/p and modifies
#   the entries inside 0/p based on the arguments of $1 (DAKOTA related)
#   After that, a normal bash script prepares the FOAM, runs it and
#   does some analysis.
#   At the end, the result is catched up and sent back to DAKOTA ($2)
#
# ------------------------------------------------------------------------------


# Dakota change the parameters in this file
# ------------------------------------------------------------------------------
dprepro $1 0/p.dakota 0/p


# Run simulation with new parameter set
# ------------------------------------------------------------------------------


    # Get pressure drop dp
    #---------------------------------------------------------------------------
    dp=$(head -43 0/p | tail -1 | xargs | cut -d' ' -f3 | tr -d ';')
    dp=$(echo ${dp} | sed -e 's/[eE]+*/\\*10\\^/')
    dp=$(echo "scale=3; $dp/1" | bc)


    # Get the loop number
    #---------------------------------------------------------------------------
    loopNumber=`cat .optimizationLoop`
    >&2 echo -e "   ++++ Optimisation loop $loopNumber"
    >&2 echo -e "   |"
    >&2 echo -e "   |--> dp = $dp [m^2/s^2]"

    # Make loop folder for log files
    #---------------------------------------------------------------------------
    logFolder_="Log/Optimization"$loopNumber
    mkdir -p $logFolder_


    # Run case till converged
    #---------------------------------------------------------------------------
    >&2 echo "   |--> Run case in flow direction"
    simpleFoam > $logFolder_/flowDirectionLog


    # Get flux  (average of inlet / outlet would be better here)
    #---------------------------------------------------------------------------
    >&2 echo -en "   |--> Calc flux through outlet: "
    flux1=$(postProcess -func 'flowRatePatch(name=outlet,phi)' -latestTime \
        | tail -n 5 | head -n 1 | cut -d'=' -f2 | xargs)
    >&2 echo $flux1


    # Remove time directorys (reg expression would be nicer)
    #---------------------------------------------------------------------------
    rm -rf 1* 2* 3* 4* 5* 6* 7* 8* 9*


    # Reverse flow (change BC)
    #---------------------------------------------------------------------------
    lineNoInlet=$(grep "inlet" -n constant/polyMesh/boundary | cut -d':' -f1)
    lineNoOutlet=$(grep "outlet" -n constant/polyMesh/boundary | cut -d':' -f1)
    sed -i "${lineNoOutlet}s/.*/inlet/" constant/polyMesh/boundary
    sed -i "${lineNoInlet}s/.*/outlet/" constant/polyMesh/boundary


    # Run case till converged
    #---------------------------------------------------------------------------
    >&2 echo "   |--> Run case in reversed flow direction"
    simpleFoam > $logFolder_/reversedFlowDirectionLog


    # Reset flow (change BC)
    #---------------------------------------------------------------------------
    lineNoInlet=$(grep "inlet" -n constant/polyMesh/boundary | cut -d':' -f1)
    lineNoOutlet=$(grep "outlet" -n constant/polyMesh/boundary | cut -d':' -f1)
    sed -i "${lineNoOutlet}s/.*/inlet/" constant/polyMesh/boundary
    sed -i "${lineNoInlet}s/.*/outlet/" constant/polyMesh/boundary


    # Get flux  (average of inlet / outlet would be better here)
    #---------------------------------------------------------------------------
    >&2 echo -en "   |--> Calc flux through outlet: "
    flux2=$(postProcess -func 'flowRatePatch(name=outlet)' -latestTime \
        | tail -n 5 | head -n 1 | cut -d'=' -f2 | xargs)
    >&2 echo $flux2


    # Remove time directorys (reg expression would be nicer)
    # If you want to check out results, comment the next line
    #---------------------------------------------------------------------------
    rm -rf 1* 2* 3* 4* 5* 6* 7* 8* 9*


    # Resonse function; Flux should be 10x smaller in reverse direction
    # Hence we use a gradient scheme, the function has to be minimized
    #---------------------------------------------------------------------------
    ratio=$(awk -v a=$flux1 -v b=$flux2 'BEGIN { print (a)/(b) }')

    # Ensure that the variable ratio does not include , for decimal separation
    ratio=$(echo $ratio | tr ',' '.')
    funct=$(echo "scale=6; 3-$ratio" | bc)

    if [ $(echo $funct | grep "-") ];
    then
        funct=${funct//-}
    fi


    >&2 echo "   |--> Ratio between fluxes is: $ratio"
    >&2 echo "   |--> Function for dakota is: $funct"
    >&2 echo "   |"
    echo -e "$dp\t$ratio\t$funct" >> analyseData.dat
    echo $funct > .dakotaInput.dak


    # Increase the loop number and store in dummy file
    #--------------------------------------------------------------------------
    echo $((loopNumber+1)) > .optimizationLoop


# Generate ouput file for DAKOTA's algorithm
#------------------------------------------------------------------------------
cp .dakotaInput.dak $2

sleep 0.1

#------------------------------------------------------------------------------
