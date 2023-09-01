#!/bin/bash
#  Author: Ben Halpern
#  Veracode
#  Microsoft App Center Post Build Script
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# How to use:
#  Place this script inside the root directory of the application connected to Appcenter.
#  Either modify the constants, or comment them out and set them as enviornmental variables from within Micrsoft App Center
#  A "VID" and "VKEY" Variable need to be set within App Center set with the Veracode API ID and Key 
#  If you provide a "SRCCLR_API_TOKEN" variable in App Center then a SCA Agent scan will be performed. https://docs.veracode.com/r/Setting_Up_Agent_Based_Scans
# NOTE: make sure that the archive settings in section SCN010 when creating the archive match that of your configuration
# This shell script is meant to be used as a modifiable document showing a method of integrating veracode into the Microsoft App Center Workflow
# If the build log is able to be pulled out of App Center, then that can be used instead of the Archive being generated.

#::SCN001
##################################################################################
# Script Configuration Switches
##################################################################################
# DEBUG : true -> Uses Hardcoded Test Values
# LEGACY: true -> Uses old method of Gen-IR

LEGACY=true
DEBUG=true

if [ "$LEGACY" == "true" ]; then
  echo "----------------------------------------------------------------------------"
  echo " Legacy is turned on : $LEGACY"
  echo "----------------------------------------------------------------------------"

fi

if [ "$DEBUG" == "true" ]; then

  echo "----------------------------------------------------------------------------"
  echo " Debug is turned on : $DEBUG"
  echo "----------------------------------------------------------------------------"

fi

###################################################################################
# XCODE Settings Variables
##################################################################################
# Put the location of Your Signing Identity to sign the code with
# This is needed for archiving the application. If you already have an archive file produced then this step is not needed and can be commented out.
# IF the code signing identity is already loaded from MS APP center you may be able to pass an enviornmental variable to call it
# https://learn.microsoft.com/en-us/appcenter/build/custom/variables/#pre-defined-variables
CODE_SIGN_IDENTITY_V="" 
CODE_SIGNING_REQUIRED_V=NO 
CODE_SIGNING_ALLOWED_V=NO
AD_HOC_CODE_SIGNING_ALLOWED=YES
PROVISIONING_PROFILE=""
DEBUG_INFORMATION_FORMAT=dwarf-with-dsym
ENABLE_BITCODE=NO
echo "======================================================================================"
echo "===        Microsoft App Center Post Build Script with Veracode Integration        ==="
#echo "=====        Veracode Unofficial Integration with Microsoft App Center        ========"
echo "============                    Version 1.0.3                     ===================="
echo "======================================================================================"

#::SCN002
# Inspired by and utilized code written by gilmore867
# https://github.com/gilmore867/VeracodePrescanCheck
#################################################################################
# Downloading Latest Version of the Wrapper 
#################################################################################

# Veracode's API Wrapper
# Documentation:
#   https://docs.veracode.com/r/c_about_wrappers
#     
# Description:
#  Makes a curl request to pull down the latest wrapper version information and then uses that to pull down the latest version of the Veracode API Wrapper.

WRAPPER_VERSION=`curl https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/maven-metadata.xml | grep latest |  cut -d '>' -f 2 | cut -d '<' -f 1`
if `wget https://repo1.maven.org/maven2/com/veracode/vosp/api/wrappers/vosp-api-wrappers-java/$WRAPPER_VERSION/vosp-api-wrappers-java-$WRAPPER_VERSION.jar -O VeracodeJavaAPI.jar`; then
                chmod 755 VeracodeJavaAPI.jar
                echo '[INFO] SUCCESSFULLY DOWNLOADED WRAPPER'
  else
                echo '[ERROR] DOWNLOAD FAILED'
                exit 1
fi

#::SCN003
#################################################################################
# Local Script Variables
# Edit these to match your application
#################################################################################
# Set this manually or configure the appName to be utilized 
#Default
appName="iGoat-Swift"

projectLocation=$APPCENTER_XCODE_PROJECT
#projectLocation="$appName/$appName.xcodeproj"
schemeName=$APPCENTER_XCODE_SCHEME	

if [ "$DEBUG" == "true" ]; then
  projectLocation="./$appName/$appName.xcodeproj"
  #schemeName="iGoat-Veracode"
  
elif [ "$LEGACY" == "true" ]; then
  projectLocation=$APPCENTER_XCODE_PROJECT
fi

#::SCN004
# https://docs.veracode.com/r/r_uploadandscan
###############################################################################
# Parameters for Veracode Upload and Scan
###############################################################################

APPLICATIONNAME="$appName"       # Comment out to use enviornmental variable from within MS APP CENTER
DELETEINCOMPLETE=2                # Default is [(0): don't delete a scan ,(1): delete any scan that is not in progress and doesn't have results ready,(2): delete any scan that doesn't have results ready]  
SANDBOXNAME="MSAPPCENTER"         # If null then will skip
CREATESANDBOX=true
CREATEPROFILE=true
OPTARGS=''

echo "========================================================================================================================================================================"
echo "Moving to build location"
echo "========================================================================================================================================================================"

cd $appName
ls -la

echo "========================================================================================================================================================================"
echo "API Hooks"
echo "========================================================================================================================================================================"


# TODO Check to see if the build succeeded


# Find archive file
echo $APPCENTER_OUTPUT_DIRECTORY	
ls -la $APPCENTER_OUTPUT_DIRECTORY/*	

# use the api to get the build log









#::SCN005
echo "========================================================================================================================================================================"
echo "Clean build"
echo "========================================================================================================================================================================"

xcodebuild clean

#::SCN006
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "========================================================================================================================================================================"
echo "Install Gen-IR and Generate Dependencies"
echo "========================================================================================================================================================================"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
brew tap veracode/tap
brew install gen-ir

#::SCN007
# This section is specific to the example which the file is contained
# Make sure to change this to specifically point to the package managers in which your application utilizes

ls 

# TODO: Add Hueristic check to see which build files are located
#make dependencies
#bundle install
pod install

#::SCN008
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#echo "========================================================================================================================================================================"
#echo "Reading out the configuration structure"
#echo "========================================================================================================================================================================"
#echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#xcodebuild -list 

#::SCN009
#APPCENTER DEFINED ENV VAR

if [ "$DEBUG" == "true" ]; then
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "= App Center Defined  Variables      ===================================================================================================================================" 
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  echo "APPCENTER_XCODE_PROJECT/WORKSPACE:  $APPCENTER_XCODE_PROJECT"	
  echo "APPCENTER_XCODE_SCHEME: $APPCENTER_XCODE_SCHEME"
  echo "APPCENTER_SOURCE_DIRECTORY: $APPCENTER_SOURCE_DIRECTORY"
  echo "APPCENTER_OUTPUT_DIRECTORY: $APPCENTER_OUTPUT_DIRECTORY"

  ls $APPCENTER_SOURCE_DIRECTORY
fi
cd iGoat-Swift
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#::SCN010
# Creating XCODE Project Archive to be place within
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "========================================================================================================================================================================"
echo " Creating Archive"
echo "========================================================================================================================================================================"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# Debug
if [ "$DEBUG" == "true" ]; then
      echo "[DEBUG]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
      
      xcodebuild archive -workspace $appName.xcworkspace -configuration Debug -scheme $schemeName -destination generic/platform=iOS DEBUG_INFORMATION_FORMAT=dwarf-with-dsym -archivePath $appName.xcarchive CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO ENABLE_BITCODE=NO AD_HOC_CODE_SIGNING_ALLOWED=YES | tee build_log.txt
      echo "========================================================================================================================================================================"
      echo "Output from Build_log.txt #############################################################################################################################################"
      echo "========================================================================================================================================================================"
      cat build_log.txt
elif [ "$DEBUG" == "false" ]; then
  # Legacy Mode
  if [ "$LEGACY" == "true" ]; then
      
        xcodebuild archive -workspace $appName.xcworkspace -configuration Debug -scheme $APPCENTER_XCODE_SCHEME -destination generic/platform=iOS DEBUG_INFORMATION_FORMAT=dwarf-with-dsym -archivePath $appName.xcarchive CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO ENABLE_BITCODE=NO | tee build_log.txt
        echo "========================================================================================================================================================================"
        echo "Output from Build_log.txt #############################################################################################################################################"
        echo "========================================================================================================================================================================"
        cat build_log.txt
  else
    # Default
    
    xcodebuild archive -project $appName.xcodeproj -scheme $APPCENTER_XCODE_SCHEME -configuration Debug -destination generic/platform=iOS -archivePath $appName.xcarchive DEBUG_INFORMATION_FORMAT=dwarf-with-dsym CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY_V CODE_SIGNING_REQUIRED=$CODE_SIGNING_REQUIRED_V CODE_SIGNING_ALLOWED=$CODE_SIGNING_ALLOWED_V ENABLE_BITCODE=NO | tee build_log.txt
  fi
else
  # debug is neither true or false
  echo "[Error] There was an issue with the script"

fi

#::SCN011
################################################################################################################################################################################
######################################################### Veracode SCA AGENT BASED SCAN ######################################################################################## 
################################################################################################################################################################################
#if including the SRCCLR_API_TOKEN as an enviornmental variable to be able to conduct Veracode SCA Agent-based scan
# comment out the next line if the token is set in appcenter
# SRCCLR_API_TOKEN=$SRCCLR_API_TOKEN

#if [ -n $SRCCLR_API_TOKEN ]; then
#  
#  echo "========================================================================================================================================================================"
#  echo "RUNNING VERACODE SCA AGENT-BASED SCAN  #################################################################################################################################"
#  echo "========================================================================================================================================================================"
#
#  curl -sSL https://download.sourceclear.com/ci.sh | sh
#  ls -la 
#fi


#updated version
#::SCN012
if [ "$DEBUG" == "true" ]; then
  echo "========================================================================================================================================================================" 
  echo "Contents of archive 1####################################################################################################################################################"
  echo "========================================================================================================================================================================"

  ls -la $appName.xcarchive
fi

echo "========================================================================================================================================================================"
echo "GEN-IR Running #########################################################################################################################################################"
echo "========================================================================================================================================================================"
# See Documentation and Source:
# https://github.com/veracode/gen-ir/

#::SCN013
if [ "$LEGACY" == "true" ]; then
  echo "[LEGACY]::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  echo "========================================================================================================================================================================" 
  echo "Running modified version to write bitcode out to IR folder #############################################################################################################"
  echo "========================================================================================================================================================================"
  
  # uses old method
  #ls -la $appName.xcarchive
  #mkdir $appName.xcarchive/IR
  #gen-ir build_log.txt Signal.xcarchive/ 
  gen-ir build_log.txt $appName.xcarchive/

  echo "========================================================================================================================================================================" 
  echo "Contents of archive  2####################################################################################################################################################"
  echo "========================================================================================================================================================================"

  ls -la $appName.xcarchive/IR
else
  # uses new method
  # https://docs.veracode.com/r/Generate_IR_to_Package_iOS_and_tvOS_Apps
  #echo "Default"
  gen-ir build_log.txt $appName.xcarchive --project-path $projectLocation
fi


if [ "$DEBUG" == "true" ]; then
  echo "========================================================================================================================================================================" 
  echo "Contents of archive 2####################################################################################################################################################"
  echo "========================================================================================================================================================================"

  ls -la $appName.xcarchive
fi

#::SCN013
echo "========================================================================================================================================================================"
echo "Zipping up artifact ####################################################################################################################################################"
echo "========================================================================================================================================================================"

#if [ "$LEGACY" = true ]; then
#  zip -r $appName.zip $appName.xcarchive
#else
#  zip -r $appName.zip $appName.xcarchive
#fi

zip -r $appName.zip $appName.xcarchive
# This section is also specific to your configuration. Make sure to include the necessary SCA component files such as the lock files from your enviornment
zip -r $appName-Podfile.zip Podfile.lock 
ls -la

#::SCN014

mkdir Veracode/
ls -la
cp $appName-Podfile.zip $appName.zip -t Veracode/
ls -la Veracode/

#::SCN015
echo "========================================================================================================================================================================"
echo "#####  Veracode Upload and Scan  #######################################################################################################################################"
echo "========================================================================================================================================================================"
if [ "$DEBUG" == "true" ]; then
  echo "         0000000000000000000000000          1111111    -----------------------------------------------------------"
  echo "         000000              00000        11 111111    ------- Veracode Upload and Scan --------------------------"
  echo "         111111              11111             1111    -----------------------------------------------------------"
  echo "         010101              10101             1111    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "         110010              11011             1111    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "         111111              11111             1111    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "         1111111111111111111111111          111111111  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
fi



if [ -n $SANDBOXNAME ]; then
  if [ "$DEBUG" == "true" ]; then
    echo "[DEBUG]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan 2 -createprofile false -createsandbox true -appname "$APPLICATIONNAME" -sandboxname "$SANDBOXNAME" -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/
  else
    # Default Sandbox
    java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan $DELETEINCOMPLETE -createprofile $CREATEPROFILE -createsandbox $CREATESANDBOX -appname "$APPLICATIONNAME" -sandboxname "$SANDBOXNAME" -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
  fi
else
   if [ "$DEBUG" == "true" ]; then
    echo "[DEBUG]:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan 1 -createprofile false -appname "$APPLICATIONNAME"  -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
  else
    # Default Policy
    java -jar VeracodeJavaAPI.jar -action UploadAndScan -vid $VID -vkey $VKEY  -deleteincompletescan $DELETEINCOMPLETE -createprofile $CREATEPROFILE -appname "$APPLICATIONNAME" -version "$APPCENTER_BUILD_ID-APPCENTER" -filepath Veracode/ $OPTARGS
  fi
fi



#EOF
