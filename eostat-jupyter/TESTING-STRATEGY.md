# EOStat Image Testing Strategy

## Package Dependency Verification

### Test Script: `test-handbook-packages.R`

Verifies all 25 R packages required by UN-Handbook are installed.

**Package list extracted from**:
```bash
grep -oh "library([^)]*)" UN-Handbook/*.qmd | sed 's/library(\([^)]*\))/\1/' | sort | uniq
```

**Critical packages**:
- `sits` (12 uses) - PRIMARY PACKAGE for satellite image time series
- `sitsdata` (7 uses) - Sample datasets for sits
- `sf`, `terra`, `stars` - Geospatial data handling
- `rstac` - STAC catalog access
- `torch`, `luz` - Deep learning (optional for MVP)

**Packages already in base image** (r-datascience):
- `sf`, `terra`, `stars` (from rocker/geospatial)
- `tidyverse`, `dplyr`, `tidyr`, `ggplot2`
- `arrow`, `duckdb`

**Packages we need to add**:
- `sits`, `sitsdata`, `rstac` (Earth Observation)
- `torch`, `luz` (Machine Learning)
- `FNN`, `kohonen` (Statistical analysis)
- `tmap`, `gdalcubes` (Visualization)
- `kableExtra`, `xml2`, etc. (Utilities)

---

## Testing Workflow

### 1. Build-Time Tests

Run during Docker build to fail fast:

```bash
# In Dockerfile, after installing packages:
RUN Rscript /opt/eostat/test-handbook-packages.R
```

This ensures the image won't be created if packages are missing.

### 2. Container Structure Tests

Uses Google's container-structure-test:

```bash
container-structure-test test \
  --image eostat-test:local \
  --config ./tests.yaml
```

Tests:
- File existence (init scripts, etc.)
- Command availability (R, Python, git-lfs)
- GDAL bindings work
- All handbook packages loadable

### 3. Integration Test

Test with actual handbook code:

```bash
# Create test script from handbook
cat > test-sits-sample.R << 'EOF'
library(sits)
library(sf)
library(terra)
point <- st_sfc(st_point(c(-47.5, -10.5)), crs = 4326)
print(point)
EOF

# Run in container
docker run --rm -v $(pwd):/test eostat-test:local \
  Rscript /test/test-sits-sample.R
```

### 4. Full Chapter Test

Test cloning handbook and running a chapter:

```bash
docker run --rm eostat-test:local bash -c "
  git clone --depth 1 https://github.com/FAO-EOSTAT/UN-Handbook.git
  cd UN-Handbook
  ls data/ct_chile/
  echo 'Testing data access works'
"
```

---

## CI/CD Integration

### GitHub Actions Workflow

```yaml
- name: Test image
  run: |
    container-structure-test test \
      --image eostat-test:latest \
      --config ./eostat/tests.yaml

- name: Test handbook packages
  run: |
    docker run --rm eostat-test:latest \
      Rscript /opt/eostat/test-handbook-packages.R
```

### Success Criteria

- ✅ All 25 R packages available
- ✅ Python geospatial packages work
- ✅ GDAL bindings functional
- ✅ Can clone handbook repo
- ✅ Can access chapter data
- ✅ Sample code executes without error

---

## Failure Modes & Debugging

### Missing R Package

**Symptom**: test-handbook-packages.R reports missing package

**Fix**: Add to `requirements-r.txt` and rebuild

### Compilation Error

**Symptom**: R package fails to compile

**Fix**:
1. Check if binary available from Posit
2. Add system dependencies if needed
3. Check compatibility with R version

### Python Package Conflict

**Symptom**: pip install fails

**Fix**:
1. Check if package already in base image
2. Remove from requirements.txt if redundant
3. Pin version if conflict

---

## Performance Optimization

### Using Posit Package Manager Binaries

The R installation script uses:
```r
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
```

This provides precompiled binaries for Ubuntu 24.04, dramatically reducing build time:
- **Without binaries**: 30-60 minutes
- **With binaries**: 5-10 minutes

### Build Time Breakdown

| Step | Time (binaries) | Time (source) |
|------|----------------|---------------|
| Base image pull | 2-5 min | 2-5 min |
| System packages | 1 min | 1 min |
| R packages | 2-5 min | 20-40 min |
| Python packages | 1-2 min | 5-10 min |
| **Total** | **6-13 min** | **28-56 min** |

---

## Next Steps

After successful build:
1. Run container-structure-test
2. Run test-handbook-packages.R
3. Test with sample handbook code
4. Push to registry (ECR or GHCR)
5. Update Helm chart image reference
6. Test E2E workflow
