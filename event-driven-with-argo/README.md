# Event driven with argo:
## Installation

- The user must start a Minikube cluster (you can use the `--driver` option to specify the container runtime) using the command below:  

    ```
    minikube start --driver=docker
    ```  

    Using `--driver=docker` runs Minikube inside a Docker container instead of a virtual machine, which provides several advantages. It ensures a faster and more lightweight Kubernetes cluster initialization. This approach is particularly useful for development and testing environments where quick deployment and easy cleanup.

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

- Wait for the deployment to stablize (1-3 minutes) and then open your browser on the link printed, usually http://127.0.0.1:8000. 

- You will see the code server is running. Follow the documentations under `doc` folder.


> Note: Here is an example of Redis' publisher which is discussed in detail in the repository you have on code server
>
>```python
>
>from os import environ
>from redis import Redis
>from time import sleep
>
>stream_key = environ.get("STREAM", "STREAM")
>producer = environ.get("PRODUCER", "user-1")
>
>
>def connect_to_redis():
>    hostname = environ.get("REDIS_HOSTNAME", "redis-service") 
>    port = environ.get("REDIS_PORT", 6379)
>
>    return Redis(hostname, port, retry_on_timeout=True)
>
>
>def send_event(redis_connection, aoi, reference):
>    count = 0
>
>    try:
>        # TODO cloud events
>        # un-map the "data" wrt app package parameters
>        data = {
>            "producer": producer,
>            "href": reference,
>        }
>        resp = redis_connection.xadd(stream_key, data)
>        print(resp)
>        count += 1
>
>    except ConnectionError as e:
>        print(f"ERROR REDIS CONNECTION: {e}")
>
>
>connection = connect_to_redis()
>
>references = [
>    "https://earth-search.aws.element84.com/v0/collections/sentinel-s2-l2a-cogs/items/S2A_10TFK_20210708_0_L2A",
>    "https://earth-search.aws.element84.com/v0/collections/sentinel-s2-l2a-cogs/items/S2B_10TFK_20210713_0_L2A",
>    "https://earth-search.aws.element84.com/v0/collections/sentinel-s2-l2a-cogs/items/S2A_10TFK_20210718_0_L2A",
>    "https://earth-search.aws.element84.com/v0/collections/sentinel-s2-l2a-cogs/items/S2A_10TFK_20220524_0_L2A",
>    "https://earth-search.aws.element84.com/v0/collections/sentinel-s2-l2a-cogs/items/S2A_10TFK_20220514_0_L2A",
>    "https://earth-search.aws.element84.com/v0/collections/sentinel-s2-l2a-cogs/items/S2A_10TFK_20220504_0_L2A"
>]
>
>for reference in references:
>    send_event(connection, aoi, reference)
>    sleep(1)
>```

### **Troubleshooting**  

If the **Code Server** is unreachable at `http://127.0.0.1:8000`, there may be an existing process occupying the port. You can terminate the process using the command below, allowing Kubernetes to automatically re-establish port forwarding for traffic on port `8000`:  

```sh
sudo fuser -k 8000/tcp
```