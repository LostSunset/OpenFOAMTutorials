#!/bin/bash
#------------------------------------------------------------------------------#
#                                                                              #
#   A   utomatic    |  Build by Tobias Holzmann                                #
#   O   ptimization |  Version 3.1.0                                           #
#   P   rocess      |                                                          #
#   C   chain       |                                                          #
#                                                                              #
#------------------------------------------------------------------------------#
#
# Description
#   Run the dakota tool and run the process chain
#
# ------------------------------------------------------------------------------


# Dakota change the parameters in this file
# ------------------------------------------------------------------------------
dprepro $1 0/p.dakota 0/p


# Run simulation with new parameter set
# ------------------------------------------------------------------------------

    
    # Get pressure drop dp
    #---------------------------------------------------------------------------
    dp=`head -43 0/p | tail -1`
    dp=`echo $dp | cut -d' ' -f3`
    dp=${dp::-1}
    dp=`echo ${dp} | sed -e 's/[eE]+*/\\*10\\^/'`
    dp=`echo "scale=3; $dp/1" | bc`


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


    # Reset flow (change BC)
    #---------------------------------------------------------------------------
    sed -i '34s/.*/inlet/' constant/polyMesh/boundary
    sed -i '40s/.*/outlet/' constant/polyMesh/boundary


    # Run case till converged
    #---------------------------------------------------------------------------
    >&2 echo "   |--> Run case in flow direction"
    simpleFoam > $logFolder_/flowDirectionLog


    # Get flux  (average of inlet / outlet would be better here)
    #---------------------------------------------------------------------------
    >&2 echo "   |--> Calc flux through outlet"
    flux1=`patchIntegrate phi outlet -latestTime \
        | tail -4 | head -1 | cut -d'=' -f2`


    # Remove time directorys (reg expression would be nicer)
    #---------------------------------------------------------------------------
    rm -rf 1* 2* 3* 4* 5* 6* 7* 8* 9*


    # Reverse flow (change BC)
    #---------------------------------------------------------------------------
    sed -i '34s/.*/outlet/' constant/polyMesh/boundary
    sed -i '40s/.*/inlet/' constant/polyMesh/boundary


    # Run case till converged
    #---------------------------------------------------------------------------
    >&2 echo "   |--> Run case in reversed flow direction"
    simpleFoam > $logFolder_/reversedFlowDirectionLog


    # Get flux  (average of inlet / outlet would be better here)
    #---------------------------------------------------------------------------
    >&2 echo "   |--> Calc flux through outlet"
    flux2=`patchIntegrate phi outlet -latestTime \
        | tail -4 | head -1 | cut -d'=' -f2`


    # Remove time directorys (reg expression would be nicer)
    #---------------------------------------------------------------------------
    rm -rf 1* 2* 3* 4* 5* 6* 7* 8* 9*


    # Resonse function; Flux should be 10x smaller in reverse direction
    # Hence we use a gradient scheme, the function has to be minimized
    #---------------------------------------------------------------------------
    echo $flux1 > .flux1
    echo $flux2 > .flux2
    f1=`cat .flux1`
    f2=`cat .flux2`
    ratio=`awk -v a=$f1 -v b=$f2 'BEGIN { print (a)/(b) }'`
    funct=`echo "scale=6; 3-$ratio" | bc`

    if [ `echo $funct | grep "-"` ];
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
