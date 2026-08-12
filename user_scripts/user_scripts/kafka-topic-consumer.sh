#!/bin/bash

# Default Kafka bootstrap server and Zookeeper address
DEFAULT_BOOTSTRAP_SERVER="localhost:9092"
DEFAULT_ZOOKEEPER="localhost:2181"

# Function to list all Kafka topics using Zookeeper
list_topics() {
  $KAFKA_HOME/bin/kafka-topics.sh --list --zookeeper $KAFKA_ZOOKEEPER
}

# Function to consume messages from a selected topic
consume_topic() {
  local topic=$1
  local from_beginning=$2
  local cmd="$KAFKA_HOME/bin/kafka-console-consumer.sh --topic $topic --bootstrap-server $DEFAULT_BOOTSTRAP_SERVER"
  if [ "$from_beginning" = true ]; then
    cmd+=" --from-beginning"
  fi
  eval $cmd
}

# Function to search topics with configurable case sensitivity
search_topics() {
  local search_string=$1
  local case_sensitive=$2
  if [ "$case_sensitive" = true ]; then
    echo "$topics" | grep "$search_string"
  else
    echo "$topics" | grep -i "$search_string"
  fi
}

# Parse command line options
KAFKA_ZOOKEEPER=$DEFAULT_ZOOKEEPER
SEARCH_STRING=""
CASE_SENSITIVE=false
FROM_BEGINNING=false

while getopts "z:s:cbh" opt; do
  case $opt in
    z) KAFKA_ZOOKEEPER="$OPTARG" ;;
    s) SEARCH_STRING="$OPTARG" ;;
    c) CASE_SENSITIVE=true ;;
    b) FROM_BEGINNING=true ;;
    h) echo "Usage: $0 [-z zookeeper_address] [-s search_string] [-c] [-b] [-h]"
       echo "  -z : Specify Zookeeper address (default: localhost:2181)"
       echo "  -s : Search string for topics"
       echo "  -c : Enable case-sensitive search"
       echo "  -b : Consume messages from the beginning of the topic"
       echo "  -h : Display this help message"
       exit 0 ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

echo "Using Kafka Zookeeper address: $KAFKA_ZOOKEEPER"

echo "Fetching list of topics from Kafka broker at $KAFKA_ZOOKEEPER..."
topics=$(list_topics)

if [ -z "$topics" ]; then
  echo "No topics found."
  exit 1
fi

# If a search string is provided, use it to filter topics
if [ -n "$SEARCH_STRING" ]; then
  echo "Searching for topics containing '$SEARCH_STRING' (case-${CASE_SENSITIVE:+in}sensitive):"
  filtered_topics=$(search_topics "$SEARCH_STRING" $CASE_SENSITIVE)
  if [ -z "$filtered_topics" ]; then
    echo "No matching topics found."
    exit 1
  fi
  topics="$filtered_topics"
fi

topics_array=($topics)
echo "Available Kafka topics:"
select topic in "${topics_array[@]}"; do
  if [ -n "$topic" ]; then
    echo "Starting to listen to topic: $topic"
    if [ "$FROM_BEGINNING" = true ]; then
      echo "Consuming messages from the beginning of the topic"
    else
      echo "Consuming only new messages"
    fi
    consume_topic $topic $FROM_BEGINNING
    break
  else
    echo "Invalid selection. Please try again."
  fi
done

