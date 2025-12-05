# Helm Chart Changes for EOStat S3 Cache

## Summary

Add support for mounting the S3-backed R package cache (`ungp-eostat-handbook-cache`) into eostat-rstudio pods. This provides faster startup by sharing the pre-installed sitsdata R package (~1.8GB) across all sessions.

Note: The torch backend is bundled with the torch R package in the Docker image - no separate S3 cache needed.

## Prerequisites (Already Done)

- [x] S3 bucket created: `ungp-eostat-handbook-cache`
- [x] IAM policy attached to S3 CSI driver role
- [x] PersistentVolume applied to cluster: `eostat-handbook-cache-pv`

---

## Changes Required

### 1. Add to `values.yaml`

```yaml
# S3-backed R package cache for faster startup
eostatCache:
  enabled: true
  mountPath: /mnt/eostat-cache
  pvcName: eostat-handbook-cache-pvc
  pvName: eostat-handbook-cache-pv
  storageSize: 10Gi
```

### 2. Create `templates/eostat-cache-pvc.yaml`

```yaml
{{- if .Values.eostatCache.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Values.eostatCache.pvcName }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
spec:
  accessModes:
    - ReadOnlyMany
  storageClassName: ""
  resources:
    requests:
      storage: {{ .Values.eostatCache.storageSize }}
  volumeName: {{ .Values.eostatCache.pvName }}
{{- end }}
```

### 3. Modify `templates/deployment.yaml` (or statefulset.yaml)

Add to `spec.template.spec.volumes`:

```yaml
volumes:
  # ... existing volumes ...
  {{- if .Values.eostatCache.enabled }}
  - name: eostat-cache
    persistentVolumeClaim:
      claimName: {{ .Values.eostatCache.pvcName }}
      readOnly: true
  {{- end }}
```

Add to `spec.template.spec.containers[].volumeMounts`:

```yaml
volumeMounts:
  # ... existing mounts ...
  {{- if .Values.eostatCache.enabled }}
  - name: eostat-cache
    mountPath: {{ .Values.eostatCache.mountPath }}
    readOnly: true
  {{- end }}
```

Add to `spec.template.spec.containers[].env`:

```yaml
env:
  # ... existing env vars ...
  {{- if .Values.eostatCache.enabled }}
  - name: EOSTAT_CACHE_MOUNT
    value: {{ .Values.eostatCache.mountPath | quote }}
  {{- end }}
```

---

## How It Works

1. **PVC binds to pre-existing PV** that mounts `s3://ungp-eostat-handbook-cache`
2. **S3 bucket contains** pre-installed R packages:
   ```
   r-packages/
   └── sitsdata/        # ~1.8GB sits example data package
   ```
3. **Init script detects mount** at `/mnt/eostat-cache` and:
   - Sets `R_LIBS_SITE` to include the S3 path (sitsdata loaded from cache)
4. **Fallback**: If mount unavailable, uses packages from Docker image

---

## Testing

After deploying with the new Helm chart:

```bash
# Check PVC is bound
kubectl get pvc eostat-handbook-cache-pvc -n <namespace>

# Check mount in pod
kubectl exec -it <pod> -n <namespace> -- ls /mnt/eostat-cache/r-packages/

# Verify in R console
# .libPaths() should show /mnt/eostat-cache/r-packages first
```

---

## Onyxia Catalog Integration

If using Onyxia's service catalog, add to the service's `Chart.yaml` or catalog config:

```yaml
# In catalog service definition
config:
  eostatCache:
    enabled: true
```

Or expose as a user-configurable option in the Onyxia UI.
