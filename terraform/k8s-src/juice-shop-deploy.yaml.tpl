apiVersion: apps/v1
kind: Deployment
metadata:
  name: snyk-juice-shop
  labels:
    app: snyk-juice-shop
spec:
  selector:
    matchLabels:
      app: snyk-juice-shop
  replicas: 1
  revisionHistoryLimit: 0
  template:
    metadata:
      labels:
        app: snyk-juice-shop
    spec:
      containers:
      - name: juice-shop
        image: ${image}
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
        securityContext:
          privileged: true
