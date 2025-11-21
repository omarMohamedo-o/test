# 🚀 Phase 2 Quick Test Guide

Follow these steps to test your Kubernetes deployment in 10 minutes.

## Step 1: Verify Prerequisites ✅

Check that you have the required tools:

```bash
# Check Docker
docker --version

# Check Minikube
minikube version

# Check kubectl
kubectl version --client

# Check Helm
helm version
```

**Expected**: All commands should return version information without errors.

---

## Step 2: Setup Minikube Cluster 🏗️

```bash
cd /home/omar/Projects/tactful-votingapp-cloud-infra/k8s
./setup-minikube.sh
```

**What this does**:

- Creates Minikube cluster with 4GB RAM, 2 CPUs
- Enables ingress and metrics-server addons
- Builds all Docker images inside Minikube

**Expected output**:

```
✓ Minikube cluster created successfully
✓ Ingress addon enabled
✓ Metrics-server addon enabled
✓ All images built successfully
```

**Verify cluster is running**:

```bash
minikube status
kubectl get nodes
```

Should show cluster running and 1 node Ready.

---

## Step 3: Configure DNS 🌐

Get Minikube IP and update /etc/hosts:

```bash
# Get the IP
minikube ip

# Update /etc/hosts (replace X.X.X.X with the actual IP from above)
echo "X.X.X.X vote.local result.local" | sudo tee -a /etc/hosts
```

**Example**:
If `minikube ip` returns `192.168.49.2`, run:

```bash
echo "192.168.49.2 vote.local result.local" | sudo tee -a /etc/hosts
```

**Verify DNS**:

```bash
ping -c 1 vote.local
```

Should get response from Minikube IP.

---

## Step 4: Deploy with Helm (Recommended) 🎯

Deploy the development environment:

```bash
./deploy-helm.sh dev
```

**What this does**:

- Installs PostgreSQL via Bitnami Helm chart
- Installs Redis via Bitnami Helm chart
- Creates namespace with security policies
- Deploys vote, result, and worker applications
- Sets up ingress routing

**Expected output**:

```
✓ Helm release "voting-app-postgres" installed
✓ Helm release "voting-app-redis" installed
✓ Helm release "voting-app" installed
```

**This takes 2-3 minutes** - databases need time to initialize.

---

## Step 5: Wait for Pods to be Ready ⏳

Watch the pods start:

```bash
kubectl get pods -n voting-app -w
```

Press `Ctrl+C` when all pods show `Running` and `READY 1/1`.

**Or check status once**:

```bash
kubectl get pods -n voting-app
```

**Expected output**:

```
NAME                      READY   STATUS    RESTARTS   AGE
vote-xxxxxxxxx-xxxxx      1/1     Running   0          2m
vote-xxxxxxxxx-xxxxx      1/1     Running   0          2m
result-xxxxxxxxx-xxxxx    1/1     Running   0          2m
result-xxxxxxxxx-xxxxx    1/1     Running   0          2m
worker-xxxxxxxxx-xxxxx    1/1     Running   0          2m
postgres-0                1/1     Running   0          2m
redis-master-0            1/1     Running   0          2m
```

**If pods are not ready after 5 minutes**, see troubleshooting section below.

---

## Step 6: Verify Services 🔍

Check that all services are created:

```bash
kubectl get svc -n voting-app
```

**Expected**: Should see services for vote, result, postgres, redis.

Check ingress:

```bash
kubectl get ingress -n voting-app
```

**Expected**: Should show ingress with hosts `vote.local` and `result.local`.

---

## Step 7: Test Vote Application 🗳️

Open your browser and go to:

```
http://vote.local
```

**Expected**:

- Page loads showing "Cats vs Dogs" voting interface
- Blue background
- Two buttons: CATS and DOGS

**Test voting**:

1. Click on "CATS" button
2. Page should show "Thank you for voting!"

**Via terminal**:

```bash
curl http://vote.local
```

Should return HTML with voting interface.

---

## Step 8: Test Result Application 📊

Open your browser and go to:

```
http://result.local
```

**Expected**:

- Page loads showing vote results
- Real-time vote counts for Cats and Dogs
- Results update automatically (WebSocket connection)

**Via terminal**:

```bash
curl http://result.local
```

Should return HTML with result page.

---

## Step 9: Test End-to-End Flow 🔄

1. **Open two browser windows side by side**:
   - Left: <http://vote.local>
   - Right: <http://result.local>

2. **Vote for Cats** on the left window

3. **Watch the right window** - Cats count should increase (may take 1-2 seconds)

4. **Vote for Dogs** on the left window

5. **Watch the right window** - Dogs count should increase

**This proves**:

- Vote app → Redis queue ✅
- Worker → Processing votes ✅
- Worker → PostgreSQL storage ✅
- Result app → Reading from PostgreSQL ✅
- WebSocket → Real-time updates ✅

---

## Step 10: Verify Security & Resources 🔒

Check Pod Security Standards:

```bash
kubectl get ns voting-app -o yaml | grep pod-security
```

**Expected**: Should show `restricted` enforcement.

Check pods are non-root:

```bash
kubectl get pod -n voting-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].securityContext.runAsUser}{"\n"}{end}'
```

**Expected**: Should show UID 1000 or 999 (not 0).

Check NetworkPolicies:

```bash
kubectl get networkpolicies -n voting-app
```

**Expected**: Should show 3 policies (default-deny, postgres-access, redis-access).

Check resource usage:

```bash
kubectl top pods -n voting-app
```

**Expected**: All pods should be within defined limits.

---

## ✅ Success Criteria

Your deployment is successful if:

- ✅ All pods are `Running` and `Ready`
- ✅ <http://vote.local> loads and accepts votes
- ✅ <http://result.local> displays vote counts
- ✅ Voting on vote.local updates result.local in real-time
- ✅ Security policies enforced (PSA, non-root, NetworkPolicies)
- ✅ No errors in pod logs

---

## 🎉 You're Done

**Congratulations!** Your Kubernetes deployment is working correctly.

### What you've tested

- ✅ Minikube cluster provisioning
- ✅ Helm chart deployment
- ✅ Multi-tier application (vote → redis → worker → postgres → result)
- ✅ Ingress routing with DNS
- ✅ Real-time WebSocket connections
- ✅ Security: PSA, non-root containers, NetworkPolicies
- ✅ Persistence: StatefulSets with PVCs

---

## 🔧 Troubleshooting

### Pods Not Starting

**Check pod status**:

```bash
kubectl describe pod <pod-name> -n voting-app
kubectl logs <pod-name> -n voting-app
```

**Common issues**:

- Image pull errors → Run `./setup-minikube.sh` again to rebuild images
- Resource constraints → Increase Minikube memory: `minikube delete && minikube start --memory=4096`

### Cannot Access vote.local or result.local

**Check /etc/hosts**:

```bash
cat /etc/hosts | grep vote.local
```

Should show Minikube IP with vote.local and result.local.

**Check ingress controller**:

```bash
kubectl get pods -n ingress-nginx
```

Should show ingress-nginx-controller running.

**Get correct Minikube IP**:

```bash
minikube ip
```

Update /etc/hosts with correct IP.

### Votes Not Appearing in Results

**Check worker logs**:

```bash
kubectl logs -n voting-app -l app=worker
```

Should show "Processing vote" messages.

**Check database connectivity**:

```bash
kubectl logs -n voting-app -l app=vote | grep -i error
kubectl logs -n voting-app -l app=result | grep -i error
```

**Verify NetworkPolicies**:

```bash
kubectl describe networkpolicy -n voting-app
```

Should show policies allowing vote/result/worker to access databases.

### Performance Issues

**Check resource usage**:

```bash
kubectl top nodes
kubectl top pods -n voting-app
```

If resources are maxed out, increase Minikube resources:

```bash
minikube delete
minikube start --cpus=2 --memory=4096
```

Then redeploy.

---

## 🧹 Cleanup (When Done Testing)

To remove everything:

```bash
# Delete Helm releases
helm uninstall voting-app-postgres voting-app-redis voting-app -n voting-app

# Delete namespace
kubectl delete ns voting-app

# Stop Minikube
minikube stop

# Delete Minikube cluster (optional)
minikube delete
```

To remove DNS entries from /etc/hosts:

```bash
sudo sed -i '/vote.local/d' /etc/hosts
sudo sed -i '/result.local/d' /etc/hosts
```

---

## 📚 Next Steps

- Read [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed documentation
- Review [TRADEOFFS.md](./TRADEOFFS.md) for Azure migration path
- Check [PHASE2-SUMMARY.md](./PHASE2-SUMMARY.md) for technical details

**Ready for production?** See the Azure AKS migration guide in TRADEOFFS.md.
