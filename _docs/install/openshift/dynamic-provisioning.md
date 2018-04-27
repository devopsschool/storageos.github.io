---
layout: guide
title: StorageOS Docs - OpenShift Dynamic Provisioning
anchor: install
module: install/openshift/dynamic-provisioning
---

# Dynamic Provisioning

StorageOS volumes can be created on-demand through dynamic provisioning.

1. Create the secret needed to authenticate against the StorageOS API.
1. Adminstrators create storage classes to define different types of storage.
1. Users create a persistent volume claim (PVC).
1. The user references the PVC in a pod.

## 1. Create secret

You need to provide the correct credentials to authenticate against the StorageOS API
using [Kubernetes
secrets](https://kubernetes.io/docs/concepts/configuration/secret/). The
configuration secret supports the following parameters:

- `apiAddress`: The address of the StorageOS API. Defaults to `tcp://localhost:5705`.
- `apiUsername`: The username to authenticate to the StorageOS API with.
- `apiPassword`: The password to authenticate to the StorageOS API with.
- `apiVersion`: The API version. Defaults to `1`.

The StorageOS provider has been pre-configured to use the StorageOS API
defaults.  If you have changed the API port, removed the default account or
changed its password (recommended), you must specify the new settings in
`apiAddress`, `apiUsername` and `apiPassword`, encoded as base64 strings.

```bash
echo -n "tcp://127.0.0.1:5705" | base64
dGNwOi8vMTI3LjAuMC4xOjU3MDU=
```

Create the secret:

```bash
cat > storageos-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: storageos-secret
type: "kubernetes.io/storageos"
data:
  apiAddress: dGNwOi8vMTI3LjAuMC4xOjU3MDU=
  apiUsername: c3RvcmFnZW9z
  apiPassword: c3RvcmFnZW9z
EOF
```
```
oc create -f storageos-secret.yaml
secret "storageos-secret" created
```

Verify the secret:

```bash
$ oc describe secret storageos-secret
Name:		storageos-secret
Namespace:	default
Labels:		<none>
Annotations:	<none>

Type:	kubernetes.io/storageos

Data
====
apiAddress:	20 bytes
apiPassword:	8 bytes
apiUsername:	8 bytes

```

For dynamically provisioned volumes using storage classes, the secret can be
created in any namespace.  Note that you would want this to be an
admin-controlled namespace with restricted access to users. Specify the secret
namespace as parameter `adminSecretNamespace` and name as parameter
`adminSecretName` in storage classes.

For Persistent Volumes, secrets must be created in the Pod namespace.  Specify
the secret name using the `secretName` parameter when attaching existing volumes
in Pods or creating new persistent volumes.

Mutiple credentials can be used by creating different secrets.

## 2. Create storage class

StorageOS supports the following storage class parameters:

- `pool`: The name of the StorageOS distributed capacity pool to provision the
  volume from; defaults to `default`.
- `description`: The description to assign to volumes that were created
  dynamically.  All volume descriptions will be the same for the storage class,
  but different storage classes can be used to allow descriptions for different
  use cases.  Defaults to `Kubernetes volume`.
- `fsType`: The default filesystem type to request. Note that user-defined
  rules within StorageOS may override this value. Defaults to `ext4`.
- `adminSecretNamespace`: The namespace where the API configuration secret is
  located. Required if adminSecretName set.
- `adminSecretName`: The name of the secret to use for obtaining the StorageOS
  API credentials. If not specified, default values will be attempted.

1. Create storage class

 ```bash
 cat > storageos-sc.yaml <<EOF
 ---
 kind: StorageClass
 apiVersion: storage.k8s.io/v1beta1
 metadata:
   name: fast
 provisioner: kubernetes.io/storageos
 parameters:
   pool: default
   description: Kubernetes volume
   fsType: ext4
   adminSecretNamespace: default
   adminSecretName: storageos-secret
 ...
 EOF
 ```

 ```
 oc create -f storageos-sc.yaml
 ```

 Verify the storage class has been created:

 ```bash
 oc describe storageclass fast

 Name:           fast
 IsDefaultClass: No
 Annotations:    <none>
 Provisioner:    kubernetes.io/storageos
 Parameters:     adminSecretName=storageos-secret,adminSecretNamespace=default,description=Kubernetes volume,fsType=ext4,pool=default
 Events:         <none>
 ```

## 3. Create a persistent volume claim

 ```bash
 cat > storageos-sc-pvc.yaml <<EOF
 ---
 apiVersion: v1
 kind: PersistentVolumeClaim
 metadata:
   name: fast0001
   annotations:
     volume.beta.kubernetes.io/storage-class: fast
 spec:
   accessModes:
     - ReadWriteOnce
   resources:
     requests:
       storage: 5Gi
 ...
 EOF
 ```

 Create the persistent volume claim (pvc):

 ```bash
 oc create -f storageos-sc-pvc.yaml
 ```

 Verify the pvc has been created:

 ```bash
 oc describe pvc fast0001

 Name:         fast0001
 Namespace:    default
 StorageClass: fast
 Status:       Bound
 Volume:       pvc-480952e7-f8e0-11e6-af8c-08002736b526
 Labels:       <none>
 Annotations:	pv.kubernetes.io/bind-completed=yes
	pv.kubernetes.io/bound-by-controller=yes
	volume.beta.kubernetes.io/storage-class=fast
	volume.beta.kubernetes.io/storage-provisioner=kubernetes.io/storageos
 Capacity:     5Gi
 Access Modes: RWO
 Events:
   <snip>
 ```

 A new persistent volume will also be created and bound to the pvc:

 ```bash
 oc describe pv pvc-480952e7-f8e0-11e6-af8c-08002736b526

 Name:            pvc-480952e7-f8e0-11e6-af8c-08002736b526
 Labels:          storageos.driver=filesystem
 StorageClass:    fast
 Status:          Bound
 Claim:           default/fast0001
 Reclaim Policy:  Delete
 Access Modes:    RWO
 Capacity:        5Gi
 Message:
 Source:
     Type:            StorageOS (a StorageOS Persistent Disk resource)
     VolumeName:      pvc-480952e7-f8e0-11e6-af8c-08002736b526
     VolumeNamespace: default
     FSType:          ext4
     ReadOnly:        false
 Events               <none>
 ```

## 4. Create a pod

 Create a pod which uses the persistent volume claim:

 ```bash
 cat > storageos-sc-pvcpod.yaml <<EOF
 ---
 apiVersion: v1
 kind: Pod
 metadata:
   labels:
     name: nginx
     role: master
   name: test-storageos-nginx-sc-pvc
 spec:
   containers:
     - name: master
       image: nginx
       env:
         - name: MASTER
           value: "true"
       ports:
         - containerPort: 80
       resources:
         limits:
           cpu: "0.1"
       volumeMounts:
         - mountPath: /usr/share/nginx/html
           name: nginx-data
   volumes:
     - name: nginx-data
       persistentVolumeClaim:
         claimName: fast0001
 ...
 EOF

 oc create -f storageos-sc-pvcpod.yaml
 ```

 Verify that the pod has been created:

 ```bash
 oc get pods test-storageos-nginx-sc-pvc

 NAME                          READY     STATUS    RESTARTS   AGE
 test-storageos-nginx-sc-pvc   1/1       Running   0          44s
   ```

## Cleanup

On the master OpenShift server:

```bash
rm -f storageos-{secrets,pod,pv,pvc,pvcpod,sc,sc-pv,sc-pvcpod}.yaml
oc delete pod test-storageos-nginx-sc-pvc test-storageos-nginx-pvc test-storageos-nginx
oc delete pods $(oc get pods |grep ^test-storageos |cut -d' ' -f 1)

oc delete pvc pvc0001 fast0001
oc delete pv pv0001
oc delete secret storageos-secret
oc delete storageclass fast
```

On an OpenShift node:

```bash
storageos volume rm default/nginx-vol01 default/nginx-pv01
```