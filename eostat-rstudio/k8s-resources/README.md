# EOStat S3 Cache Setup

This directory contains Kubernetes resources for the S3-backed R package cache.

## Architecture

```
S3 Bucket: ungp-eostat-handbook-cache
    └── r-packages/
        ├── sitsdata/          (~500MB R package)
        └── torch-backend/     (~2GB LibTorch)
            │
            ▼ Mountpoint for S3 CSI
            │
    PersistentVolume (cluster-wide)
            │
            ▼ binds
            │
    PersistentVolumeClaim (per namespace)
            │
            ▼ mounts at /mnt/eostat-cache
            │
    eostat-rstudio pods
```

## One-Time Cluster Setup

Apply the PersistentVolume (cluster-scoped):

```bash
kubectl apply -f eostat-cache-pv.yaml
```

## IAM Configuration (Already Done)

The S3 CSI driver role has been granted read access:
- Role: `dev-cluster-s3-csi-driver-irsa`
- Policy: `eostat-handbook-cache-s3-readonly`

## Helm Chart Integration

### Option 1: Helm Creates PVC Automatically

Add to the Helm chart's `templates/pvc.yaml`:

```yaml
{{- if .Values.eostatCache.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: eostat-handbook-cache-pvc
spec:
  accessModes:
    - ReadOnlyMany
  storageClassName: ""
  resources:
    requests:
      storage: 10Gi
  volumeName: eostat-handbook-cache-pv
{{- end }}
```

Add to `values.yaml`:

```yaml
eostatCache:
  enabled: true
  mountPath: /mnt/eostat-cache
```

Add to pod spec in `templates/deployment.yaml`:

```yaml
volumes:
  {{- if .Values.eostatCache.enabled }}
  - name: eostat-cache
    persistentVolumeClaim:
      claimName: eostat-handbook-cache-pvc
      readOnly: true
  {{- end }}

volumeMounts:
  {{- if .Values.eostatCache.enabled }}
  - name: eostat-cache
    mountPath: {{ .Values.eostatCache.mountPath }}
    readOnly: true
  {{- end }}

env:
  {{- if .Values.eostatCache.enabled }}
  - name: EOSTAT_CACHE_MOUNT
    value: {{ .Values.eostatCache.mountPath }}
  {{- end }}
```

### Option 2: Pre-create PVCs Per Namespace

If Helm can't create PVCs, pre-create them:

```bash
# For each user namespace
kubectl apply -f eostat-cache-pvc-template.yaml -n user-xyz
```

## Testing

After deployment, verify in an eostat-rstudio session:

```r
# Check library paths - S3 cache should be first
.libPaths()

# Verify sitsdata loads from cache
library(sitsdata)

# Verify torch backend is available
torch::torch_is_installed()
```

## Troubleshooting

### Mount not available

Check if PV exists:
```bash
kubectl get pv eostat-handbook-cache-pv
```

Check if PVC is bound:
```bash
kubectl get pvc eostat-handbook-cache-pvc -n <namespace>
```

Check S3 CSI driver pods:
```bash
kubectl get pods -n kube-system | grep s3
```

### Permission denied

Verify IAM policy is attached:
```bash
aws iam list-attached-role-policies --role-name dev-cluster-s3-csi-driver-irsa
```
