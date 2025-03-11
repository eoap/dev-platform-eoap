# Installation

1- Create namespace:
```
kubectl create ns tile-based-training
```
2- install mlflow using helm:
```
helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update
helm install my-mlflow community-charts/mlflow --namespace tile-based-training

```

3- edit [init.sh](./files/init.sh) with a correct repository:
ex: 
```
git clone https://{your_git_account}:{your_access_token}@github.com/ai-extensions/notebooks.git
```

4- Deploy everything using command below:
```
skaffold dev
```