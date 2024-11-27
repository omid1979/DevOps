kubectl apply -f nginx-deployment.yaml
kubectl apply -f haproxy-ingress.yaml
kubectl apply -f nginx-ingress.yaml


## veryfing  
kubectl get pods --all-namespaces 
kubectl get services
