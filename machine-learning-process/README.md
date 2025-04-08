# Installation

1- Create namespace:
```
kubectl create ns tile-based-training
```
2- install mlflow using helm:
```
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo add localstack https://helm.localstack.cloud
helm repo update

```

3- Deploy everything using command below:
```
skaffold dev
```
4- Open the code-server and mlflow on your browser:
```
code-server: http://localhost:8000
mlflow: http://localhost:5000
```
5- Follow the documentations of both `training` and `inference`.
6- Run the application packages with calrissian(documentation is provided for each module).


### **Troubleshooting**  

If the **Code Server** and **Mlflow** are unreachable at `http://127.0.0.1:8000` and `http://127.0.0.1:5000` respectively, there may be an existing process occupying those port. You can terminate the process using the command below, allowing Kubernetes to automatically re-establish port forwarding for traffic on port `8000` and `5000`:  

```sh
sudo fuser -k 8000/tcp
sudo fuser -k 5000/tcp
```