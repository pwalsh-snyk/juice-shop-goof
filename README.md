*[original Juice Shop readme](./JUICESHOP_README.md)*

# Snyk Juice Shop

This is a vulnerable by design repository for demonstrating Snyk Insights. Do not deploy this in production.

## Prepare Demo Environemnt

### Install Tools

- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [helm](https://helm.sh/docs/intro/install/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [EKSCTL](https://formulae.brew.sh/formula/eksctl)

### Fork & Import

Fork this repository and navigate to it locally

```
git clone https://github.com/pwalsh-snyk/juice-shop-goof
cd juice-shop
```

### Deploy Juice Shop to EKS

In A Cloud Guru create an AWS sandbox environment.

Configure AWS CLI:

```
aws configure
```
When promted, input the AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY from A Cloud Guru

Run the Script:

```
chmod +x deploy.sh
./deploy.sh
```

After the script has been executed and the Juice-Shop app has been deployed on your EKS cluster, you can access Juice Shop locally by running the following:

```
kubectl port-forward deployment/snyk-juice-shop 1337:3000
```
Then access locally at: http://localhost:1337

## Step 1: Deploy the Snyk Runtime Sensor

This demo will be deploying the runtime sensor as a DaemonSet using Helm. 

Create a token for a [Snyk Service Account] (https://docs.snyk.io/enterprise-setup/service-accounts) with one of the following roles:

- Group Admin
- Custom Group Level Role with AppRisk edit permission enabled.

Create the proper namespace:
```
kubectl create namespace snyk-runtime-sensor
```

Create a Secret with Your Snyk Token
```
kubectl create secret generic <<YOUR_SECRET_NAME>> --from-literal=snykToken=<<YOUR_TOKEN>> -n snyk-runtime-sensor
```

Add the Helm Repository
```
helm repo add runtime-sensor https://snyk.github.io/runtime-sensor
```

Note: If your data is hosted in a different region than the default region (USA), you need to set the snykAPIBaseURL while installing the Helm chart in the following format: api.<<REGION>>.snyk.io:443, for example api.eu.snyk.io:443

Install the Snyk Runtime Sensor
```
helm install my-runtime-sensor \
--set workloadType=daemonset \ # Can be ommited, as 'daemonset' is the default
--set secretName=<<YOUR_SECRET_NAME>> \
--set clusterName=<<CLUSTER_NAME>> \
--set snykGroupId=<<YOUR_GROUP_ID>> \
--set snykAPIBaseURL=api.<<REGION>>.snyk.io:443 \ # Optional
-n snyk-runtime-sensor \
runtime-sensor/runtime-sensor
```

Verify successful install
```
kubectl get pods -n snyk-runtime-sensor
```

TO BE DELETED:



## Step 2: Scan and Tag Container projects

See [full docs](https://docs.snyk.io/manage-risk/snyk-apprisk/risk-based-prioritization-for-snyk-apprisk/prioritization-setup/prioritization-setup-associating-snyk-open-source-code-and-container-projects) on tagging format. This is required to link Open Source and Code projects with Container projects.

Add tags to container images: [see example workflow](./.github/workflows/container-build-and-test.yml#L35).

Examples:

```
snyk container monitor your/image:tag --tags="component=pkg:${{ github.repository }}@${{ github.ref_name }}"
snyk container monitor your/image:tag --tags="component=pkg:github/org/repo@branch"
```

## Step 3: Tag Open Source and Code projects

Review script at [insights/apply-tags.py](./insights/apply-tags.py).

```
pip install requests
python3 insights/apply-tags.py --org-id your-org-id --snyk-token your-snyk-token --origin github
```


