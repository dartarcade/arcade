#!/bin/bash

# Script to build and optionally run the Arcade documentation Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

IMAGE_NAME="arcade-docs"
CONTAINER_NAME="arcade-docs-container"
PORT="8080"

print_usage() {
    echo "Usage: $0 [build|run|stop|logs|shell]"
    echo ""
    echo "Commands:"
    echo "  build   Build the Docker image"
    echo "  run     Build and run the container"
    echo "  stop    Stop the running container"
    echo "  logs    Show container logs"
    echo "  shell   Open a shell in the running container"
    echo ""
    echo "Options:"
    echo "  -p, --port PORT   Port to run on (default: 8080)"
    echo "  -h, --help        Show this help message"
}

build_image() {
    echo -e "${YELLOW}Building Docker image: $IMAGE_NAME${NC}"
    docker build -t $IMAGE_NAME .
    echo -e "${GREEN}✓ Image built successfully${NC}"
}

run_container() {
    # Stop existing container if running
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${YELLOW}Stopping existing container...${NC}"
        docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
        docker rm $CONTAINER_NAME >/dev/null 2>&1 || true
    fi

    echo -e "${YELLOW}Starting container on port $PORT...${NC}"
    docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:8080 \
        --restart unless-stopped \
        $IMAGE_NAME

    echo -e "${GREEN}✓ Container started successfully${NC}"
    echo -e "${GREEN}📖 Documentation available at: http://localhost:$PORT${NC}"
    echo -e "${GREEN}🏥 Health check available at: http://localhost:$PORT/health${NC}"
    
    # Show logs for a few seconds
    echo -e "${YELLOW}Container logs:${NC}"
    sleep 2
    docker logs $CONTAINER_NAME --tail 10
}

stop_container() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${YELLOW}Stopping container...${NC}"
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
        echo -e "${GREEN}✓ Container stopped${NC}"
    else
        echo -e "${RED}Container is not running${NC}"
    fi
}

show_logs() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker logs -f $CONTAINER_NAME
    else
        echo -e "${RED}Container is not running${NC}"
    fi
}

open_shell() {
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker exec -it $CONTAINER_NAME /bin/sh
    else
        echo -e "${RED}Container is not running${NC}"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        build)
            COMMAND="build"
            shift
            ;;
        run)
            COMMAND="run"
            shift
            ;;
        stop)
            COMMAND="stop"
            shift
            ;;
        logs)
            COMMAND="logs"
            shift
            ;;
        shell)
            COMMAND="shell"
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Execute command
case $COMMAND in
    build)
        build_image
        ;;
    run)
        build_image
        run_container
        ;;
    stop)
        stop_container
        ;;
    logs)
        show_logs
        ;;
    shell)
        open_shell
        ;;
    *)
        print_usage
        exit 1
        ;;
esac