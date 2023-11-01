set -e

TARGET=$1
CATAPULTA=$2

# If $CATAPULTA is defined, but it's not 'catapulta' then we exit with error
if [[ "$CATAPULTA" != "" && "$CATAPULTA" != "catapulta" ]]
    then
        echo "To deploy use catapulta add 'catapulta' to params. Terminating"
        exit 1
fi

echo "Running Full Lens V2 Deployment on $TARGET environment"

echo "Deploying Lens V2 Implementation and upgrade contracts..."
bash script/run.sh S01_DeployLensV2Upgrade $TARGET _ $CATAPULTA

read -p "Continue?" CONFIRMATION

echo "Deploying Lens V2 Periphery..."
bash script/run.sh S02_DeployLensV2Periphery $TARGET _ $CATAPULTA

read -p "Continue?" CONFIRMATION

# Run addBalance script if the following fails:

echo "Changing Lens V1 Admins..."
bash script/run.sh S03_ChangeLensV1Admins $TARGET s

read -p "Continue?" CONFIRMATION

echo "Performing Lens V2 Upgrade..."
bash script/run.sh S04_PerformV2Upgrade $TARGET

read -p "Continue?" CONFIRMATION

echo "Running Governance Actions (whitelisting profile creator, registering currencies and modules)..."
bash script/run.sh S05_GovernanceActions $TARGET

read -p "Continue?" CONFIRMATION

echo "Interacting with Lens V2..."
bash script/run.sh S06_InteractWithLensV2 $TARGET
