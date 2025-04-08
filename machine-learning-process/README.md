# Installation

1- install mlflow using helm:
```
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo add localstack https://helm.localstack.cloud
helm repo update

```

2- Deploy everything using command below:
```
skaffold dev
```
3- Open the code-server and mlflow on your browser:
```
code-server: http://localhost:8000
mlflow: http://localhost:5000
```

### **Troubleshooting**  

If the **Code Server** and **Mlflow** are unreachable at `http://127.0.0.1:8000` and `http://127.0.0.1:5000` respectively, there may be an existing process occupying those port. You can terminate the process using the command below, allowing Kubernetes to automatically re-establish port forwarding for traffic on port `8000` and `5000`:  

```sh
sudo fuser -k 8000/tcp
sudo fuser -k 5000/tcp
```