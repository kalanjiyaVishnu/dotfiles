topic=$1
if [ -z "$1" ]
  then
    echo "No argument supplied"
    exit 0
fi
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic $topic --from-beginning --bootstrap-server localhost:9092
