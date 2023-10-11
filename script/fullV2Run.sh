set -e

TARGET=$1

echo "Running Full Lens V2 Deployment on $TARGET environment"

bash script/run.sh LensV2UpgradeDeployment $TARGET

bash script/run.sh LensV1ChangeAdmins $TARGET n

bash script/run.sh LensV1ToV2Upgrade $TARGET

bash script/run.sh LensV2DeployPeriphery $TARGET
