#!/bin/bash

# Variables
IMAGE_NAME="piece_of_cake_game"
CONTAINER_NAME="piece_of_cake_container"
REQUESTS_FILE="requests/group_8/hard.json"
OUTPUT_FILE="/app/flamegraph.svg"  # Adjust if needed
HOST_OUTPUT_FILE="./flamegraph.svg"

# Step 1: Build the Docker image (only if necessary)
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

# Step 2: Run the Docker container in detached mode
echo "Starting Docker container in detached mode..."
docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME"

# Step 3: Wait a few seconds to let the program start
sleep 0.5
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Container '$CONTAINER_NAME' is not running. Checking logs for details..."
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Step 4: Get the PID of the running Python process
echo "Getting PID of main.py..."
PID=$(docker exec -it "$CONTAINER_NAME" ps aux | grep "[m]ain.py" | awk '{print $2}')
if [ -z "$PID" ]; then
    echo "Error: Could not find a Python process running 'main.py' in the container."
    docker logs "$CONTAINER_NAME"
    exit 1
fi
echo "Found main.py running with PID: $PID"

# Step 5: Start py-spy to record the flame graph in the background
echo "Recording flame graph using py-spy..."
docker exec -it "$CONTAINER_NAME" py-spy record -p "$PID" --output $OUTPUT_FILE --rate 1000
docker cp "$CONTAINER_NAME":$OUTPUT_FILE $HOST_OUTPUT_FILE
sleep 3
docker logs "$CONTAINER_NAME"

# # Step 6: Wait for main.py to complete
# echo "Waiting for main.py to complete..."
# while docker exec "$CONTAINER_NAME" ps -p "$PID" > /dev/null; do
#     sleep 1
# done
echo "main.py has completed."

# # Step 7: Verify and Copy the flamegraph.svg file from the container to the host
# echo "Checking if flamegraph.svg was created in the container..."
# if docker exec -it "$CONTAINER_NAME" ls -l $OUTPUT_FILE; then
#     echo "Copying flame graph to the host machine..."
#     docker cp "$CONTAINER_NAME":$OUTPUT_FILE $HOST_OUTPUT_FILE
# else
#     echo "Error: flamegraph.svg not found in /app."
#     docker logs "$CONTAINER_NAME"
#     exit 1
# fi

# Step 8: Stop and remove the container
echo "Stopping and removing the container..."
docker stop "$CONTAINER_NAME"
docker rm "$CONTAINER_NAME"

echo "Flame graph saved as $HOST_OUTPUT_FILE"
