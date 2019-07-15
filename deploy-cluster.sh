MASTERS=3
NAMESPACE="redis-cluster"
NODES=$(($MASTERS*2))

kubectl create namespace $NAMESPACE
kubectl apply -f redis-cluster.yml -n $NAMESPACE
kubectl get pods -n $NAMESPACE
kubectl scale statefulset redis-cluster --replicas=$NODES -n $NAMESPACE
kubectl exec -it redis-cluster-0 -n $NAMESPACE -- redis-cli --cluster create --cluster-replicas 1  $(kubectl get pods -l app=redis-cluster-o jsonpath='{range.items[*]} {.status.podIP}:6379' -n $NAMESPACE)
