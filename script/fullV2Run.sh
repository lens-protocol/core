set -e

TARGET=$1

echo "Running Full Lens V2 Deployment on $TARGET environment"

echo "Deploying Lens V2 Implementation and upgrade contracts..."
bash script/run.sh A_DeployLensV2Upgrade $TARGET

echo "Deploying Lens V2 Periphery..."
bash script/run.sh B_DeployLensV2Periphery $TARGET

echo "Changing Lens V1 Admins..."
bash script/run.sh C_ChangeLensV1Admins $TARGET s

echo "Performing Lens V2 Upgrade..."
bash script/run.sh D_PerformV2Upgrade $TARGET

echo "Running Governance Actions (whitelisting profile creator, registering currencies and modules)..."
bash script/run.sh E_GovernanceActions $TARGET

echo "Interacting with Lens V2..."
bash script/run.sh F_InteractWithLensV2 $TARGET
