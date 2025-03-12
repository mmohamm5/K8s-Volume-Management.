# K8s-Volume-Management.

In today's business model, data is the most precious asset for many startups and enterprises. In a Kubernetes cluster, containers in Pods can be either data producers, data consumers, or both. While some container data is expected to be transient and is not expected to outlive a Pod, other forms of data must outlive the Pod in order to be aggregated and possibly loaded into analytics engines. Kubernetes must provide storage resources in order to provide data to be consumed by containers or to store data produced by containers.

Kubernetes uses Volumes of several types and a few other forms of storage resources for container data management. In this chapter, we will talk about ephemeral Volume definitions, PersistentVolume and PersistentVolumeClaim objects, which help us attach persistent storage Volumes to Pods.

## Volumes

As we know, containers running in Pods are ephemeral in nature. All data stored inside a container is deleted if the container crashes. However, the kubelet will restart it with a clean slate, which means that it will not have any of the old data.

To overcome this problem, Kubernetes uses ephemeral Volumes, storage abstractions that allow various storage technologies to be used by Kubernetes and offered to containers in Pods as storage media. An ephemeral Volume is essentially a mount point on the container's file system backed by a storage medium. The storage medium, content and access mode are determined by the Volume Type.

![pic](asset/1.png)

In Kubernetes, an ephemeral Volume is linked to a Pod and can be shared among the containers of that Pod. Although the ephemeral Volume has the same life span as the Pod, meaning that it is deleted together with the Pod, the ephemeral Volume outlives the containers of the Pod - this allows data to be preserved across container restarts.

## Container Storage Interface (CSI)

Container orchestrators like Kubernetes, Mesos, Docker or Cloud Foundry used to have their own methods of managing external storage using Volumes. For storage vendors, it was challenging to manage different Volume plugins for different orchestrators. A maintainability challenge for Kubernetes as well, it involved in-tree storage plugins integrated into the orchestrator's source code. Storage vendors and community members from different orchestrators started working together to standardize the Volume interface - a volume plugin built using a standardized Container Storage Interface (CSI) designed to work on different container orchestrators with a variety of storage providers. Explore the CSI specifications for more details.

Between Kubernetes releases v1.9 and v1.13 CSI matured from alpha to stable support, which makes installing new CSI-compliant Volume drivers very easy. CSI allows third-party storage providers to develop solutions without the need to add them into the core Kubernetes codebase. These solutions are CSI drivers installed only when required by cluster administrators.

## Volume Types

A directory which is mounted inside a Pod is backed by the underlying Volume Type. A Volume Type decides the properties of the directory, like size, content, default access modes, etc. Some examples of Volume Types that support ephemeral Volumes are:

- **emptyDir**

An empty Volume is created for the Pod as soon as it is scheduled on the worker node. The Volume's life is tightly coupled with the Pod. If the Pod is terminated, the content of emptyDir is deleted forever.  

- **hostPath**

The hostPath Volume Type shares a directory between the host and the Pod. If the Pod is terminated, the content of the Volume is still available on the host.

- **gcePersistentDisk**

The gcePersistentDisk Volume Type mounts a Google Compute Engine (GCE) persistent disk into a Pod.

- **awsElasticBlockStore**

The awsElasticBlockStore Volume Type mounts an AWS EBS Volume into a Pod. 

- **azureDisk**

The azureDisk mounts a Microsoft Azure Data Disk into a Pod.

- **azureFile**

The azureFile mounts a Microsoft Azure File Volume into a Pod.

- **cephfs**

The cephfs allows for an existing CephFS volume to be mounted into a Pod. When a Pod terminates, the volume is unmounted and the contents of the volume are preserved.

- **nfs**

The nfs mounts an NFS share into a Pod.

- **iscsi**

The iscsi mouns an iSCSI share into a Pod.

- **secret**

The secret Volume Type facilitates the supply of sensitive information, such as passwords, certificates, keys, or tokens to Pods.

- **configMap**

The configMap objects facilitate the supply of configuration data, or shell commands and arguments into a Pod.

- **persistentVolumeClaim**

A PersistentVolume is consumed by a Pod using a persistentVolumeClaim. 

You can learn more details about Volume Types from the documentation. However, do not be alarmed by the “deprecated” and “removed” notices. They have been added as means of tracking the original in-tree plugins which eventually migrated to the CSI driver implementation. Kubernetes native plugins do not show such a notice.

## PersistentVolumes

In a typical IT environment, storage is managed by the storage/system administrators. The end user will just receive instructions to use the storage but is not involved with the underlying storage management.

In the containerized world, we would like to follow similar rules, but it becomes challenging, given the many Volume Types we have seen earlier. Kubernetes resolves this problem with the PersistentVolume (PV) subsystem, which provides APIs for users and administrators to manage and consume persistent storage. To manage the Volume, it uses the PersistentVolume API resource type, and to consume it, it uses the PersistentVolumeClaim API resource type.

A Persistent Volume is a storage abstraction backed by several storage technologies, which could be local to the host where the Pod is deployed with its application container(s), network attached storage, cloud storage, or a distributed storage solution. A Persistent Volume is statically provisioned by the cluster administrator. 

![pic](asset/2.png)

PersistentVolumes can be dynamically provisioned based on the StorageClass resource. A StorageClass contains predefined provisioners and parameters to create a PersistentVolume. Using PersistentVolumeClaims, a user sends the request for dynamic PV creation, which gets wired to the StorageClass resource.

Some of the Volume Types that support managing storage using PersistentVolumes are:

- GCEPersistentDisk

- AWSElasticBlockStore

- AzureFile

- AzureDisk

- CephFS

- NFS

- iSCSI

For a complete list, as well as more details, you can check out the types of Persistent Volumes. The Persistent Volume types use the same CSI driver implementations as ephemeral Volumes.

## PersistentVolumeClaims
A PersistentVolumeClaim (PVC) is a request for storage by a user. Users request for PersistentVolume resources based on storage class, access mode, size, and optionally volume mode. 

There are four access modes: 
- ReadWriteOnce (read-write by a single node)
- ReadOnlyMany (read-only by many nodes)
- ReadWriteMany (read-write by many nodes)
- ReadWriteOncePod (read-write by a single pod).
  
The optional volume modes, filesystem or block device, allow volumes to be mounted into a pod's directory or as a raw block device respectively. By design Kubernetes does not support object storage, but it can be implemented with the help of custom resource types. Once a suitable PersistentVolume is found, it is bound to a PersistentVolumeClaim. 

![pic](asset/3.png)

After a successful bound, the PersistentVolumeClaim resource can be used by the containers of the Pod.

![pic](asset/4.png)

Once a user finishes its work, the attached PersistentVolumes can be released. The underlying PersistentVolumes can then be reclaimed (for an admin to verify and/or aggregate data), deleted (both data and volume are deleted), or recycled for future usage (only data is deleted), based on the configured persistentVolumeReclaimPolicy property. 

To learn more, you can check out the PersistentVolumeClaims.

## Using a Shared hostPath Volume Type Demo Guide

This exercise guide was prepared for the demonstration available at the end of this blog. It includes a Deployment definition manifest that can be used as a template to define other similar objects as needed. In addition to the ephemeral volume and the volume mounts specified for each container, a command stanza allows us to define a series of desired commands expected to run in one of the containers. The debian container's shell command line interpreter (sh) is invoked to run the echo and sleep commands (-c).

We demonstrate how to use a hostPath volume as a shared storage between the two containers of a pod. we've already configured a deployment.

```bash
$ vim app-blue-shared-vol.yaml
```

The deployment runs a pod. And the pod is configured with two containers and a shared volume.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: blue-app
  name: blue-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blue-app
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: blue-app
        type: canary
    spec:
      volumes:
      - name: host-volume
        hostPath:
          path: /home/docker/blue-shared-volume
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: host-volume
      - image: debian
        name: debian
        volumeMounts:
        - mountPath: /host-vol
          name: host-volume
        command: ["/bin/sh", "-c", "echo Welcome to BLUE App! > /host-vol/index.html ; sleep infinity"]
status: {}
```

So the deployment operator is called the blue-app. We will be using this to also generate later a green-app deployment. But if we're scrolling down to the spec section of the pod template right down here, we see that a volume has been defined: hostPath type.

Two containers are defined, an "nginx" and a "debian" container. Both containers have mountPath directories but they're both mounting the same host-volume, host-volume, volume defined at the top here.

So one volume defined, two containers, both mounting the same volume. Now, in addition the "debian" container is going to run a few commands.

first it will create a file index.html in its own host-volume directory.

And in that file, it will write some text, "Welcome to BLUE App!". And then it will go to sleep indefinitely.

Otherwise the "debian" container would terminate and we don't want that at least not as of yet.

So now let's try to deploy this.

```bash
kubectl apply -f app-blue-shared-vol.yaml
```

But at the same time, we want to expose this deployment via a NodePort type service. The nginx web server of the deployment is already exposing port 80.

```bash
kubectl expose deployment blue-app --type=NodePort
```

So all we have to do is expose the deployment and specify that we want the NodePort type of service.

```bash
kubectl get deploy,po,svc
```

We can validate that our resources have been created.

![pic](asset/5.png)

So the deployment is up and running with one pod replica. The pod, the blue-app pod, is up and running with both containers ready, the "nginx" container and the "debian" container as well.

And then the service "blue-app" has been created and it is a NodePort type service. So now, we can use the 'minikube service list to display the URL of the NodePort type service.

```bash
minikube service list
```

So either from the command line, we could run curl and paste the URL, and here it is, we have "Welcome to BLUE App!".

```bash
curl http://192.168.59.110:30704
#Output will show like ..
Welcome to BLUE App!
```

And if we keep refreshing, we will consistently get the same response.

Now, if we want to do this in a browser, we can right-click on this link, open link and this will open a tab in our favorite browser.

So for now we've only set up the blue-app, but as homework I would invite you to set up a green-ap, pretty much the same way.

Have a deployment called the green-app configure it in such manner that the "debian" container modifies the index.html file of  your web server by using a shared volume.

So by basically using the same pattern, we can easily configure a new application which should be the green-app. And then later we are going to play with services and deployments for a Canary type of,deployment pattern.

So it's a very simple deployment.What is important is to make sure that in the template of the pod, we have a volume defined and then the two containers, they're both mounting the same volume.

Otherwise they cannot share it.

Otherwise the "debian" container cannot override the index.html file, which is the home of the nginx web server.

