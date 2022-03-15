#!/bin/bash

#login
gcloud auth list
gcloud config set account 'vijayabh@google.com'
gcloud init
gcloud auth login --no-launch-browser

#Environment
STAGING=https://staging-dataplex.sandbox.googleapis.com/
PRODUCTION=https://dataplex.googleapis.com/
AUTOPUSH=https://autopush-dataplex.sandbox.googleapis.com/
TEST_ENVIRONMENT=$AUTOPUSH
TEST_SERVICE="${TEST_ENVIRONMENT}/v1"
#token=$(gcloud auth print-access-token)
Content_Type="Content-Type: application/json"

#Project Name
TEST_PROJECT=dataplex-cdf

#Cloud Storage Bucket Details
BUCKETPATH=projects/dataplex-cdf/buckets

# To verify the Log files for Errors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Location Name
TEST_LOCATION=us-central1

#Metastore Name
METASTORE_NAME=us-central1

#Lake & Zone Name
LAKENAME=dp-$RANDOM-lake
ZONENAME=dp-$RANDOM-zone
ASSETNAME=dp-$RANDOM-asset
ENVIRONMENTNAME=dp-$RANDOM-environment


#Cloud Storage BucketName
CSBUCKETNAME=taskstesting/pyspark/hello-world/helloworld.py
CSBUCKETCONVERSION=task-copypaste/demo1/conversion.py
InvalidCSBUCKETNAME=tataskstesting/pyspark/hello-world/helloworld.py
CurrentDateTime=$(date '+%F'T"%H:%M:%SZ")
SOURCE_ARG_TC25=task-copypaste/demo1/copy.csv
DES_ARG_TC25=task-copypaste/demo1/out2/data01.parquet
InvalidCSBUCKETNAME_TC28=taskstesting/pyspark/hello-world/hello-invalid.py

#Lake Test Data
ExpectedLakeDescription=updatinglake
ExpectedZoneDescription=updatingzone
ExpectedAssetDescription=updatingasset
ExpectedMetastoreInstance=projects/"${TEST_PROJECT}"/locations/"${TEST_LOCATION}"/services/"${METASTORE_NAME}"

#Environment Test Data
ExpectedDiskSize=512
ExpectedMaxNodeCount=6
ExpectedNodeCount=4
ExpectedImageVersion=1.0
ExpectedMaxIdleDuration=600s
ExpectedEnvState=ACTIVE


#Functions
function ResultCheck(){
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
      echo Pass
    else
      echo Failed
    fi
}

function ValidateResultCheck(){
    RESULT=$?
    if [ $RESULT -eq 0 ]; then 
      echo Failed
    else
      echo Pass
    fi
}

function WaitforEnvCreation() {
# Wait until discovery is done
    EnvStatus="" || EnvStatus="CREATING"
          while [[ "${EnvStatus}" == "CREATING" ]]
              do
                sleep 10
                EnvStatus=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(state)")
              done
          if [[ "${EnvStatus}" != "ACTIVE" ]]; then
            #echo "Failed: Task-Job did not run successfully."
            return 1
          fi

      }

function validateEnvironmentDetails() {
    diskSize=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(infrastructureSpec.compute.diskSizeGb)")
          if [[ "${diskSize}" != "${ExpectedDiskSize}" ]]; then
              return 1
          fi
    maxNodeCount=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(infrastructureSpec.compute.maxNodeCount)")
          if [[ "${maxNodeCount}" != "${ExpectedMaxNodeCount}" ]]; then
             return 1
          fi
    nodeCount=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(infrastructureSpec.compute.nodeCount)")
          if [[ "${nodeCount}" != "${ExpectedNodeCount}" ]]; then
              return 1
          fi
    imageVersion=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(infrastructureSpec.osImage.imageVersion)")
          if [[ "${imageVersion}" != "${ExpectedImageVersion}" ]]; then
              return 1
          fi
    maxIdleDuration=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(sessionSpec.maxIdleDuration)")
          if [[ "${maxIdleDuration}" != "${ExpectedMaxIdleDuration}" ]]; then
              return 1
          fi
    envState=$(gcloud alpha dataplex environments describe projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME} --format "value(state)")
          WaitforEnvCreation
          if [[ "${envState}" != "${ExpectedEnvState}" ]]; then
              return 1
          fi
      }

function validateUpdateLake() {
    updateLake=$(gcloud alpha dataplex lakes describe "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --format "value(description)") ;
          if [[ "${updateLake}" != "${ExpectedLakeDescription}" ]]; then
              return 1
          fi
}

function validateUpdateZone() {
    updateZone=$(gcloud alpha dataplex zones describe "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --format "value(description)") ;
          if [[ "${updateZone}" != "${ExpectedZoneDescription}" ]]; then
              return 1
          fi
}

function validateUpdateAsset() {
    updateAsset=$(gcloud alpha dataplex assets describe "${ASSETNAME}" --zone="${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --format "value(description)") ;
          if [[ "${updateAsset}" != "${ExpectedAssetDescription}" ]]; then
              return 1
          fi
}

function validateMetastoreLake() {
    metastoreInstanceLake=$(gcloud alpha dataplex lakes describe "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --format "value(description)") ;
          if [[ "${metastoreInstanceLake}" != "${ExpectedMetastoreInstance}" ]]; then
              return 1
          fi
}

function Resultprint() {
  echo "==============================="
  SearchforErrors="* Pass *"
  passcount=$(grep "$SearchforErrors" "${SCRIPT_DIR}"/*.log | wc -l | tr -d ' ')
  SearchforErrors="* Failed *"
  failcount=$(grep "$SearchforErrors" "${SCRIPT_DIR}"/*.log | wc -l | tr -d ' ')
  total=$((passcount+failcount))
  echo "| ** Execution Status **      |"
  echo "| No of test cases: ${total}        |"
  echo "| No of test cases Passed: ${passcount} |"
  echo "| No of test cases Failed: ${failcount}  |"
  echo "==============================="
}

#Define Environment
echo "Executing on ${TEST_ENVIRONMENT}" ;
gcloud config set api_endpoint_overrides/dataplex ${TEST_ENVIRONMENT} ;

echo "---------------------------------------------------------------------------------------------------------"
#Create a lake
#echo "****** TC01-Create an environment, successfully. ******"
gcloud alpha dataplex lakes create "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
validateEnvironmentDetails
echo "TC01-Create an environment, successfully: * $(ResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC02-Create an environment, with minimum environment id length of 1 ******"
#Creating the Environment
gcloud alpha dataplex environments create e --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
validateEnvironmentDetails
echo "TC02-Create an environment, with minimum environment id length of 1: * $(ResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC03-Create an environment, with minimum environment id length of 63 ******"
#Creating the Environment
gcloud alpha dataplex environments create dp-analyze-environment-dp-analyze-environment1-dp-analyze-envir --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
validateEnvironmentDetails
echo "TC03-Create an environment, with minimum environment id length of 63: * $(ResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC04-Failed to Create an environment, with minimum environment id length of 64 ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create dp-analyze-environment-dp-analyze-environment1-dp-analyze-enviro --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC04-Failed Create an environment, with minimum environment id length of 64: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC05-Fail to create an environment with duplicate environment id ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
#Create duplicate Environmen with Same Name
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC05-Fail to create an environment with duplicate environment id: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC06-Fail to create an environment with invalid environment id with incorrect format ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create environment1@# --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC06-Fail to create an environment with invalid environment id with incorrect format: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC07-Fail to create an environment with invalid description (invalid length-more than 1024) ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create environment1@# --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" -description="The test cases is for to test the invalid length of description. The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description The test cases is for to test the invalid length of description."
echo "TC07-Fail to create an environment with invalid description (invalid length-more than 1024): * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC08-Fail to create an environment with invalid display name (invalid length more than 256 chars) ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create environment1@# --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --display-name="The test case is to test the invalid length of display name The test case is to test the invalid length of display name The test case is to test the invalid length of display name The test case is to test the invalid length of display name The test case is."
echo "TC08-Fail to create an environment with invalid display name (invalid length more than 256 chars): * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC09-Fail to create an environment with missing image version ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version= --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC09-Fail to create an environment with missing image version: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC10-Fail to create an environment with invalid Disk Size in GB. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb=99
echo "TC10-Fail to create an environment with invalid Disk Size in GB: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC11-Fail to create an environment with invalid node count. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count=0 --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC11-Fail to create an environment with invalid node count: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC12-Fail to create an environment with invalid max node count. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count=0 --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC12-Fail to create an environment with invalid max node count: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC13-Fail to create an environment with invalid Max idle duration. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --session-max-idle-duration=599s
echo "TC13-Fail to create an environment with invalid Max idle duration: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC14-Fail to create an environment with invalid image version. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version=v1.01 --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}"
echo "TC14-Fail to create an environment with invalid image version: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC15-Delete an environment ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
validateEnvironmentDetails
#Deleting the Environment
gcloud -q alpha dataplex environments delete projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME}
echo "TC15-Delete an environment: * $(ResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC16-Fail to delete an environment that does not exist. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Deleting the Environment
gcloud -q alpha dataplex environments delete projects/${TEST_PROJECT}/locations/${TEST_LOCATION}/lakes/${LAKENAME}/environments/${ENVIRONMENTNAME}
echo "TC16-Fail to delete an environment that does not exist: * $(ValidateResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC17-Update an environment successfully ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
validateEnvironmentDetails
#Update the Environment
gcloud alpha dataplex environments update ${ENVIRONMENTNAME} --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --compute-node-count=5 --no-user-output-enabled
echo "TC17-Fail to delete an environment that does not exist: * $(ResultCheck) *" ;


echo "---------------------------------------------------------------------------------------------------------"
#echo "****** TC18-Update an environment failing validation checks. ******"
ENVIRONMENTNAME=dp-$RANDOM-environment
#Creating the Environment
gcloud alpha dataplex environments create "${ENVIRONMENTNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --os-image-version="${ExpectedImageVersion}" --compute-node-count="${ExpectedNodeCount}" --compute-max-node-count="${ExpectedMaxNodeCount}" --compute-disk-size-gb="${ExpectedDiskSize}" --no-user-output-enabled
validateEnvironmentDetails
#Update the Environment
gcloud alpha dataplex environments update ${ENVIRONMENTNAME} --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --compute-node-count=5 --compute-max-node-count=3
echo "TC18-Update an environment failing validation checks: * $(ValidateResultCheck) *" ;
echo "---------------------------------------------------------------------------------------------------------"

echo "******************************* lake Test Cases ********************************"
#Create a lake
#echo "****** TC01-Create a Lake, successfully ******"
gcloud alpha dataplex lakes create "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
echo "TC01-Lake Creation succeeds: * $(ResultCheck) *" ;

echo "---------------------------------------------------------------------------------------------------------"
#Update a lake
#echo "****** TC02-Update an Lake, successfully ******"
gcloud alpha dataplex lakes update "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --description="${ExpectedLakeDescription}" --no-user-output-enabled ;
echo "TC02-Lake Update succeeds: * $(validateUpdateLake) *" ;

echo "---------------------------------------------------------------------------------------------------------"
#Delete a lake
#echo "****** TC03-Delete an Lake, successfully ******"
gcloud -q alpha dataplex lakes delete "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
gcloud alpha dataplex lakes describe "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}"  ;
echo "TC03-Lake Deletion succeeds: * $(ValidateResultCheck) *" ;

echo "---------------------------------------------------------------------------------------------------------"
#Create a lake with Metastore Instance
#echo "****** TC04-Create a Lake with Metastore Instance successfully ******"
gcloud alpha dataplex lakes create dp-$RANDOM-lake --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --metastore-service="${ExpectedMetastoreInstance}" ;
echo "TC04-Lake Creation with Metatore Instance succeeds: * $(validateMetastoreLake) *" ;

echo "---------------------------------------------------------------------------------------------------------"
#Detach a Metastore Instance from Lake
#echo "****** TC05-Detach a Metastore Instance successfully from Lake ******"
gcloud alpha dataplex lakes update "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}"  ;
echo "TC05-Lake Creation with Metatore Instance succeeds: * $(ResultCheck) *" ;

echo "---------------------------------------------------------------------------------------------------------"
#Get lake returns a lake
#echo "****** TC06-Get lake returns a lake successfully ******"
gcloud alpha dataplex lakes describe "${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}"  ;
echo "TC06-Get lake returns a lake: * $(ResultCheck) *" ;

echo "---------------------------------------------------------------------------------------------------------"
#List lake works
#echo "****** TC07-List lake successfully ******"
gcloud alpha dataplex lakes list --project="${TEST_PROJECT}" --location="${TEST_LOCATION}"  ;
echo "TC07-List lake: * $(ResultCheck) *" ;

echo "******************************* Zone Test Cases ********************************"
#echo "****** TC01-Create a Zone, successfully ******"
gcloud alpha dataplex lakes create dp-$RANDOM-lake --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
gcloud alpha dataplex zones create "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
echo "TC01-Zone Creation succeeds: * $(ResultCheck) *" ;

#echo "****** TC02-Update a Zone, successfully ******"
gcloud alpha dataplex zones create dp-$RANDOM-zone --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
gcloud alpha dataplex zones update "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --description="${ExpectedZoneDescription}"; ;
echo "TC02-Zone Update succeeds: * $(validateUpdateZone) *" ;

#echo "****** TC03-Delete a Zone, successfully ******"
gcloud alpha dataplex zones delete "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
gcloud alpha dataplex zones describe "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
echo "TC03-Zone Delete succeeds: * $(ValidateResultCheck) *" ;

#echo "****** TC04-Get Zone returns a Zone, successfully ******"
gcloud alpha dataplex zones create dp-$RANDOM-zone --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
gcloud alpha dataplex zones describe "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
echo "TC04-Get Zone returns a Zone Successfully: * $(ResultCheck) *" ;

#echo "****** TC05-List Zone pagination works, successfully ******"
gcloud alpha dataplex zones create dp-$RANDOM-zone --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
gcloud alpha dataplex zones list "${ZONENAME}" --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
echo "TC05-List Zone with pagination works, successfully: * $(ResultCheck) *" ;

#echo "****** TC06-Zone creation results in BigQuery publishing dataset creation with ID as Zone ID and Dataplex labels as user labels ******"
gcloud alpha dataplex zones create dp-$RANDOM-zone --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
bq show "${ZONENAME}"
echo "TC06-Zone creation results in BigQuery publishing dataset creation with ID as Zone ID: * $(ResultCheck) *" ;

echo "******************************* Asset Test Cases ********************************"
#echo "****** TC01-Asset creation, successfully ******"
gcloud alpha dataplex lakes create dp-$RANDOM-lake --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" ;
gcloud alpha dataplex zones create dp-$RANDOM-zone --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
bucketName=dp-$RANDOM-asset-tables
gsutil mb -p "${TEST_PROJECT}" -c STANDARD -l "${TEST_LOCATION}" -b on gs://${bucketName} ;
gcloud alpha dataplex assets create dp-$RANDOM-asset --discovery-enabled --discovery-schedule="5 * * * *" --resource-name=projects/${TEST_PROJECT}/buckets/${bucketName} --resource-type=STORAGE_BUCKET --zone "${ZONENAME}" --description "tc01 test case execution" --display-name="tc-01-asset" --lake="${LAKENAME}" --location="${TEST_LOCATION}" --project="${TEST_PROJECT}" ;
echo "TC01-Asset Creation succeeds: * $(ResultCheck) *" ;

#echo "****** TC02-Update an Asset, successfully ******"
gcloud alpha dataplex assets update "${ASSETNAME}" --zone="${ZONENAME}" --description="${ExpectedAssetDescription}" --lake="${LAKENAME}" --location="${TEST_LOCATION}" --project="${TEST_PROJECT}" ;
echo "TC02-Asset update succeeds: * $(validateUpdateAsset) *" ;

#echo "****** TC03-Get Asset returns an asset, successfully ******"
bucketName=dp-$RANDOM-asset-tables
gsutil mb -p "${TEST_PROJECT}" -c STANDARD -l "${TEST_LOCATION}" -b on gs://${bucketName} ;
gcloud alpha dataplex assets create dp-$RANDOM-asset --discovery-enabled --discovery-schedule="5 * * * *" --resource-name=projects/${TEST_PROJECT}/buckets/${bucketName} --resource-type=STORAGE_BUCKET --zone "${ZONENAME}" --description "tc03 test case execution" --display-name="tc-03-asset" --lake="${LAKENAME}" --location="${TEST_LOCATION}" --project="${TEST_PROJECT}" ;
gcloud alpha dataplex assets describe "${ASSETNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --zone "${ZONENAME}" ; 
echo "TC03-Get Asset returns an asset succeeds: * $(ResultCheck) *" ;

#echo "****** TC04-List asset pagination works, successfully ******"
bucketName=dp-$RANDOM-asset-tables
gsutil mb -p "${TEST_PROJECT}" -c STANDARD -l "${TEST_LOCATION}" -b on gs://${bucketName} ;
gcloud alpha dataplex assets create dp-$RANDOM-asset --discovery-enabled --discovery-schedule="5 * * * *" --resource-name=projects/${TEST_PROJECT}/buckets/${bucketName} --resource-type=STORAGE_BUCKET --zone "${ZONENAME}" --description "tc03 test case execution" --display-name="tc-03-asset" --lake="${LAKENAME}" --location="${TEST_LOCATION}" --project="${TEST_PROJECT}" ;
gcloud alpha dataplex assets list "${ASSETNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --zone "${ZONENAME}" --page-size="10" ;
echo "TC04-List asset pagination works succeeds: * $(ResultCheck) *" ;

#echo "****** TC05-For single region parent zone only single region buckets/datasets can be attached to an asset ******"
gcloud alpha dataplex zones create dp-$RANDOM-zone --lake="${LAKENAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --resource-location-type=SINGLE_REGION --type=RAW ;
bucketName=dp-$RANDOM-asset-tables
gsutil mb -p "${TEST_PROJECT}" -c STANDARD -l us -b on gs://${bucketName} ;
gcloud alpha dataplex assets create dp-$RANDOM-asset --discovery-enabled --discovery-schedule="5 * * * *" --resource-name=projects/${TEST_PROJECT}/buckets/${bucketName} --resource-type=STORAGE_BUCKET --zone "${ZONENAME}" --description "tc03 test case execution" --display-name="tc-03-asset" --lake="${LAKENAME}" --location="${TEST_LOCATION}" --project="${TEST_PROJECT}" ;
echo "TC05-For single region parent zone only single region buckets/datasets can be attached to an asset: * $(ValidateResultCheck) *" ;

#echo "****** TC06-Asset Deletion succeeds ******"
bucketName=dp-$RANDOM-asset-tables
gsutil mb -p "${TEST_PROJECT}" -c STANDARD -l "${TEST_LOCATION}" -b on gs://${bucketName} ;
gcloud alpha dataplex assets create dp-$RANDOM-asset --discovery-enabled --discovery-schedule="5 * * * *" --resource-name=projects/${TEST_PROJECT}/buckets/${bucketName} --resource-type=STORAGE_BUCKET --zone "${ZONENAME}" --description "tc03 test case execution" --display-name="tc-03-asset" --lake="${LAKENAME}" --location="${TEST_LOCATION}" --project="${TEST_PROJECT}" ;
gcloud alpha dataplex assets delete "${ASSETNAME}" --project="${TEST_PROJECT}" --location="${TEST_LOCATION}" --lake="${LAKENAME}" --zone "${ZONENAME}" ;
echo "TC06-Asset Deletion succeeds: * $(ResultCheck) *" ;

Resultprint
