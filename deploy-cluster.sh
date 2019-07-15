MASTERS=3
NAMESPACE="redis-cluster"

NODES=$(($MASTERS*2))
kubectl create namespace $NAMESPACE
kubectl apply -f redis-cluster.yml -n $NAMESPACE

while true
do
  rows=$(kubectl get pods -n $NAMESPACE|awk '{if(NR>1)print}'|grep 'redis-cluster'|awk '{ print $2}'|grep '1/1'|wc -l)
  if [ $rows == 1 ]
  then
    break
  else
    sleep 1
  fi
done

# kubectl get pods -n $NAMESPACE
kubectl scale statefulset redis-cluster --replicas=$NODES -n $NAMESPACE

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

kubectl exec -it redis-cluster-0 -n $NAMESPACE -- redis-cli --cluster create --cluster-replicas 1  $(kubectl get pods -l app=redis-cluster -o jsonpath='{range.items[*]} {.status.podIP}:6379' -n $NAMESPACE) <<< "yes"
