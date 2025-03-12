!#bin/bash
## Dont run shell scripts. run commands acoordingly one by one.

kubectl apply -f app-blue-shared-vol.yaml
kubectl expose deployment blue-app --type=NodePort
kubectl get deploy,po,svc
minikube service list
curl http://192.168.59.110:30704
