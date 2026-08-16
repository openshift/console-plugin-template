---
name: openshift-console-plugin-deployment
description: Build, packaging, containerization, and deployment strategies for OpenShift Console plugins
---

# OpenShift Console Plugin Deployment

This skill covers building, packaging, containerizing, and deploying OpenShift Console plugins to OpenShift clusters, including Helm charts, CI/CD integration, and production deployment best practices.

## Build and Packaging

### Webpack Production Build

```typescript
// webpack.config.ts
import * as webpack from 'webpack';
import { ConsoleRemotePlugin } from '@openshift-console/dynamic-plugin-sdk-webpack';
import * as path from 'path';

const config: webpack.Configuration = {
  mode: process.env.NODE_ENV === 'production' ? 'production' : 'development',
  entry: './src/index.ts',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js',
    chunkFilename: '[name].[contenthash].js',
    clean: true,
  },
  resolve: {
    extensions: ['.ts', '.tsx', '.js', '.jsx'],
  },
  module: {
    rules: [
      {
        test: /\.(tsx?|jsx?)$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'ts-loader',
            options: {
              configFile: path.resolve(__dirname, 'tsconfig.json'),
            },
          },
        ],
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(png|jpg|jpeg|gif|svg|woff2?|ttf|eot)$/,
        type: 'asset/resource',
      },
    ],
  },
  plugins: [
    new ConsoleRemotePlugin(),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'development'),
    }),
  ],
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
        },
      },
    },
  },
  devtool: process.env.NODE_ENV === 'production' ? 'source-map' : 'eval-source-map',
};

export default config;
```

### Build Scripts

```json
{
  "scripts": {
    "build": "npm run clean && NODE_ENV=production webpack --mode=production",
    "build:dev": "npm run clean && webpack --mode=development",
    "clean": "rm -rf dist",
    "analyze": "npm run build && npx webpack-bundle-analyzer dist/",
    "prebuild": "npm run lint && npm run test",
    "postbuild": "npm run verify-build"
  }
}
```

### Build Verification

```bash
#!/bin/bash
# scripts/verify-build.sh

echo "Verifying build artifacts..."

# Check required files exist
required_files=(
  "dist/plugin-entry.js"
  "dist/plugin-manifest.json"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Error: Required file $file not found"
    exit 1
  fi
done

# Check bundle size
max_size=5000000  # 5MB
actual_size=$(stat -f%z dist/plugin-entry.js)

if [[ $actual_size -gt $max_size ]]; then
  echo "Warning: Bundle size ${actual_size} bytes exceeds recommended ${max_size} bytes"
  exit 1
fi

echo "Build verification passed"
```

## Containerization

### Multi-stage Dockerfile

```dockerfile
# Dockerfile
FROM registry.access.redhat.com/ubi8/nodejs-18:latest AS builder

# Copy package files
COPY package*.json ./
COPY yarn.lock ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the plugin
RUN npm run build

# Production image
FROM registry.access.redhat.com/ubi8/nginx-120:latest

# Copy build artifacts
COPY --from=builder /opt/app-root/src/dist /opt/app-root/src

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 8080

# Set user
USER 1001

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Nginx Configuration

```nginx
# nginx.conf
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    server {
        listen 8080;
        server_name _;
        root /opt/app-root/src;
        index index.html;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";

        # Plugin entry point
        location /plugin-entry.js {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
            try_files $uri =404;
        }

        # Static assets with caching
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            try_files $uri =404;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Default location
        location / {
            try_files $uri $uri/ =404;
        }
    }
}
```

### Container Build Process

```bash
#!/bin/bash
# scripts/build-container.sh

REGISTRY=${REGISTRY:-"quay.io/my-org"}
IMAGE_NAME=${IMAGE_NAME:-"my-console-plugin"}
VERSION=${VERSION:-"latest"}
PLATFORM=${PLATFORM:-"linux/amd64,linux/arm64"}

echo "Building container image..."

# Build and push multi-architecture image
docker buildx build \
  --platform ${PLATFORM} \
  --tag ${REGISTRY}/${IMAGE_NAME}:${VERSION} \
  --tag ${REGISTRY}/${IMAGE_NAME}:latest \
  --push \
  .

echo "Container image built and pushed: ${REGISTRY}/${IMAGE_NAME}:${VERSION}"
```

## Helm Chart Deployment

### Chart Structure

```
charts/my-console-plugin/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── console-plugin.yaml
│   └── NOTES.txt
└── .helmignore
```

### Chart.yaml

```yaml
apiVersion: v2
name: my-console-plugin
description: A Helm chart for My Console Plugin
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - openshift
  - console
  - plugin
maintainers:
  - name: My Team
    email: team@example.com
sources:
  - https://github.com/my-org/my-console-plugin
```

### values.yaml

```yaml
# Default values for my-console-plugin
replicaCount: 2

image:
  registry: quay.io
  repository: my-org/my-console-plugin
  tag: "latest"
  pullPolicy: IfNotPresent

imagePullSecrets: []

service:
  type: ClusterIP
  port: 8080
  targetPort: 8080

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}

plugin:
  name: my-console-plugin
  displayName: "My Console Plugin"
  description: "Extends OpenShift Console with custom functionality"
  proxy:
    - type: Service
      alias: my-api
      authorize: true
      service:
        name: my-api-service
        namespace: my-namespace
        port: 8080

securityContext:
  enabled: true
  runAsNonRoot: true
  runAsUser: 1001

podSecurityContext:
  fsGroup: 2000

networkPolicy:
  enabled: false

monitoring:
  enabled: false
  serviceMonitor:
    enabled: false
```

### Deployment Template

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-console-plugin.fullname" . }}
  labels:
    {{- include "my-console-plugin.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-console-plugin.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-console-plugin.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if .Values.securityContext.enabled }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ .Values.service.targetPort }}
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- if .Values.securityContext.enabled }}
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            runAsNonRoot: {{ .Values.securityContext.runAsNonRoot }}
            runAsUser: {{ .Values.securityContext.runAsUser }}
            seccompProfile:
              type: RuntimeDefault
          {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

### ConsolePlugin Resource

```yaml
# templates/console-plugin.yaml
apiVersion: console.openshift.io/v1
kind: ConsolePlugin
metadata:
  name: {{ .Values.plugin.name }}
  labels:
    {{- include "my-console-plugin.labels" . | nindent 4 }}
spec:
  displayName: {{ .Values.plugin.displayName }}
  description: {{ .Values.plugin.description }}
  service:
    name: {{ include "my-console-plugin.fullname" . }}
    namespace: {{ .Release.Namespace }}
    port: {{ .Values.service.port }}
    basePath: "/"
  {{- if .Values.plugin.proxy }}
  proxy:
    {{- toYaml .Values.plugin.proxy | nindent 4 }}
  {{- end }}
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  release:
    types: [published]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run linter
        run: npm run lint
        
      - name: Run tests
        run: npm run test
        
      - name: Build plugin
        run: npm run build
        
      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: plugin-build
          path: dist/

  build-container:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'release'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        
      - name: Log in to registry
        uses: docker/login-action@v3
        with:
          registry: quay.io
          username: ${{ secrets.QUAY_USERNAME }}
          password: ${{ secrets.QUAY_PASSWORD }}
          
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: quay.io/my-org/my-console-plugin
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha
            
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: [test, build-container]
    runs-on: ubuntu-latest
    if: github.event_name == 'release'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install OpenShift CLI
        uses: redhat-actions/openshift-tools-installer@v1
        with:
          oc: latest
          helm: latest
          
      - name: Log in to OpenShift
        run: |
          oc login --token=${{ secrets.OPENSHIFT_TOKEN }} --server=${{ secrets.OPENSHIFT_SERVER }}
          
      - name: Deploy with Helm
        run: |
          helm upgrade --install my-console-plugin ./charts/my-console-plugin \
            --namespace my-plugin-namespace \
            --create-namespace \
            --set image.tag=${{ github.event.release.tag_name }} \
            --wait
```

## Production Deployment

### Environment-specific Values

```yaml
# environments/production/values.yaml
replicaCount: 3

image:
  tag: "v1.0.0"
  pullPolicy: Always

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

securityContext:
  enabled: true
  runAsNonRoot: true
  runAsUser: 1001

networkPolicy:
  enabled: true

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

### Deployment Commands

```bash
#!/bin/bash
# scripts/deploy-production.sh

NAMESPACE="my-plugin-production"
RELEASE_NAME="my-console-plugin"
CHART_PATH="./charts/my-console-plugin"
VALUES_FILE="./environments/production/values.yaml"

echo "Deploying to production..."

# Create namespace if it doesn't exist
oc create namespace ${NAMESPACE} --dry-run=client -o yaml | oc apply -f -

# Deploy with Helm
helm upgrade --install ${RELEASE_NAME} ${CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values ${VALUES_FILE} \
  --wait \
  --timeout 10m

# Enable the plugin in console
oc patch consoles.operator.openshift.io cluster \
  --type merge \
  --patch '{"spec":{"plugins":["'${RELEASE_NAME}'"]}}'

echo "Deployment completed successfully"
echo "Plugin URL: https://$(oc get route console -n openshift-console -o jsonpath='{.spec.host}')/my-plugin"
```

## Plugin Registration

### Manual Plugin Enablement

```bash
# Enable plugin in OpenShift Console
oc patch consoles.operator.openshift.io cluster \
  --type merge \
  --patch '{"spec":{"plugins":["my-console-plugin"]}}'

# Verify plugin is enabled
oc get consoles.operator.openshift.io cluster -o jsonpath='{.spec.plugins}'
```

### Automatic Plugin Registration

```yaml
# templates/console-plugin-patch.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "my-console-plugin.fullname" . }}-register
  labels:
    {{- include "my-console-plugin.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      serviceAccountName: {{ include "my-console-plugin.fullname" . }}
      restartPolicy: OnFailure
      containers:
        - name: plugin-register
          image: quay.io/openshift/cli:latest
          command:
            - /bin/bash
            - -c
            - |
              echo "Registering plugin..."
              oc patch consoles.operator.openshift.io cluster \
                --type merge \
                --patch '{"spec":{"plugins":["{{ .Values.plugin.name }}"]}}'
              echo "Plugin registered successfully"
```

## Monitoring and Observability

### ServiceMonitor for Prometheus

```yaml
# templates/servicemonitor.yaml
{{- if and .Values.monitoring.enabled .Values.monitoring.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "my-console-plugin.fullname" . }}
  labels:
    {{- include "my-console-plugin.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "my-console-plugin.selectorLabels" . | nindent 6 }}
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
{{- end }}
```

### Health Checks

```bash
#!/bin/bash
# scripts/health-check.sh

PLUGIN_URL="https://my-console-plugin.example.com"

echo "Performing health checks..."

# Check plugin service
response=$(curl -s -o /dev/null -w "%{http_code}" ${PLUGIN_URL}/health)
if [[ $response -eq 200 ]]; then
  echo "✅ Plugin service is healthy"
else
  echo "❌ Plugin service is unhealthy (HTTP $response)"
  exit 1
fi

# Check plugin loading
response=$(curl -s -o /dev/null -w "%{http_code}" ${PLUGIN_URL}/plugin-entry.js)
if [[ $response -eq 200 ]]; then
  echo "✅ Plugin entry file is accessible"
else
  echo "❌ Plugin entry file is not accessible (HTTP $response)"
  exit 1
fi

echo "All health checks passed"
```

## Rollback and Recovery

### Helm Rollback

```bash
# List releases
helm list -n my-plugin-namespace

# Check release history
helm history my-console-plugin -n my-plugin-namespace

# Rollback to previous version
helm rollback my-console-plugin -n my-plugin-namespace

# Rollback to specific revision
helm rollback my-console-plugin 2 -n my-plugin-namespace
```

### Emergency Plugin Disable

```bash
#!/bin/bash
# scripts/emergency-disable.sh

echo "Disabling plugin in emergency..."

# Get current plugins
current_plugins=$(oc get consoles.operator.openshift.io cluster -o jsonpath='{.spec.plugins}')

# Remove our plugin from the list
new_plugins=$(echo $current_plugins | jq '. - ["my-console-plugin"]')

# Apply the change
oc patch consoles.operator.openshift.io cluster \
  --type merge \
  --patch "{\"spec\":{\"plugins\":$new_plugins}}"

echo "Plugin disabled successfully"
```

## Related Skills

- [openshift-console-plugin-setup](../openshift-console-plugin-setup/SKILL.md) - Project setup and dependencies
- [openshift-console-plugin-development](../openshift-console-plugin-development/SKILL.md) - Build and testing workflow
- [openshift-console-plugin-advanced](../openshift-console-plugin-advanced/SKILL.md) - Security and performance considerations
- [openshift-console-plugin-styling](../openshift-console-plugin-styling/SKILL.md) - Build optimization for assets

## Deployment Checklist

- [ ] Configure webpack for production builds
- [ ] Create multi-stage Dockerfile with security best practices
- [ ] Set up Helm chart with proper templates
- [ ] Configure CI/CD pipeline with automated testing
- [ ] Implement health checks and monitoring
- [ ] Set up environment-specific configurations
- [ ] Configure automatic plugin registration
- [ ] Test rollback procedures
- [ ] Set up container registry and image scanning
- [ ] Configure resource limits and autoscaling
- [ ] Implement network policies if required
- [ ] Set up monitoring and alerting