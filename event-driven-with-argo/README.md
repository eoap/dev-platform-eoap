# Event driven with argo:

> Note: It is highly recommended to follow [this tutorial](https://eoap.github.io/event-driven-with-argo/) to know the rationale behind this activity.

## Installation

- The user must start a Minikube cluster using the command below:  

    ```
    minikube start
    ```  

- Please add the following repositories to your Helm chart to ensure access to the required packages:  

    ```sh
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo add localstack https://helm.localstack.cloud
    ```  

    Adding these repositories allows you to seamlessly install and manage **Argo** (a workflow orchestration tool) and **LocalStack** (a local AWS cloud emulator) using Helm. This ensures that your Kubernetes environment is properly configured for deploying workflows and simulating AWS services efficiently.
- Run the command below:
    ```
    skaffold dev
    ```

- Wait for the deployment to stabilize (1-3 minutes) and then open your browser on the link printed, usually http://127.0.0.1:8000. 

- You will see the code server is running. Follow the documentations under `doc` folder.




### **Troubleshooting**  

If the **Code Server** is unreachable at `http://127.0.0.1:8000`, there may be an existing process occupying the port. You can terminate the process using the command below, allowing Kubernetes to automatically re-establish port forwarding for traffic on port `8000`:  

```sh
sudo fuser -k 8000/tcp
```