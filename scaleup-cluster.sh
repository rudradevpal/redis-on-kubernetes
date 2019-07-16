# No of master node to add. The same no of Slave will also be created.
MASTERS=1
# Namespace to launch the cluster. The namespace should exist in Kubernetes
NAMESPACE="redis-cluster"

NODES=$(($MASTERS*2))

echo "> Checking no of existing nodes"
OLD_NODES=$(kubectl get pods -n $NAMESPACE|awk '{if(NR>1)print}'|grep 'redis-cluster'|wc -l)
echo $OLD_NODES" existing nodes found"

NODES=$(($OLD_NODES+$NODES))
echo "> Scaling redis-cluster from "$OLD_NODES" to "$NODES
kubectl scale statefulset redis-cluster --replicas=$NODES -n $NAMESPACE

echo "> Checking readiness of all replicas"
while true
do
  rows=$(kubectl get pods -n $NAMESPACE| awk '{if(NR>1)print}'|grep 'redis-cluster'|awk '{ print $2}'|grep '1/1'|wc -l)
  if [ $rows == $NODES ]
  then
    break
  else
    sleep 1
  fi
done

for i in $(seq $OLD_NODES $(($NODES-1)));
do
  echo "> Joining node redis-cluster-"$i" to the cluster";
  kubectl exec redis-cluster-0 -n $NAMESPACE -- redis-cli --cluster add-node $(kubectl get pod redis-cluster-$i -n $NAMESPACE -o jsonpath='{.status.podIP}'):6379 $(kubectl get pod redis-cluster-0 -n $NAMESPACE -o jsonpath='{.status.podIP}'):6379
done

echo "> Rebalancing the masters"
kubectl exec redis-cluster-0 -n $NAMESPACE -- redis-cli --cluster rebalance --cluster-use-empty-masters $(kubectl get pod redis-cluster-0 -n $NAMESPACE -o jsonpath='{.status.podIP}'):6379
