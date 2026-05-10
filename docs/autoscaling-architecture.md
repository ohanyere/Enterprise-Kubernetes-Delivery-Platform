# Autoscaling Architecture

Autoscaling keeps workloads reliable and cost-aware when demand changes. Kubernetes autoscaling usually has two layers: pod autoscaling for application capacity and node autoscaling for cluster capacity.

## Kubernetes Autoscaling Architecture

Horizontal Pod Autoscaler watches metrics such as CPU or memory utilization and changes the replica count of a workload. More replicas increase application serving capacity. Fewer replicas reduce cost and idle resource consumption.

Node autoscaling adds or removes cluster nodes when the scheduler cannot place pods or when capacity is no longer needed. In a future EKS architecture, Karpenter can provision nodes that fit pending pod requirements.

## Traffic Spike Flow

During a traffic spike, application pods consume more CPU or memory. HPA sees the metric pressure and increases the Deployment replica count. If the cluster has enough spare capacity, the scheduler places the new pods immediately.

If there is not enough capacity, the new pods remain Pending. Karpenter would observe unschedulable pods, provision matching nodes, and allow the scheduler to place the pods. Once the workload has enough replicas and node capacity, the service stabilizes.

## Elasticity Concepts

Elasticity means the platform can expand during demand and contract when demand falls. Pod elasticity handles application concurrency. Node elasticity handles infrastructure capacity. Both layers need accurate resource requests so scheduling and scaling decisions reflect real workload needs.

## Reliability Benefits

Autoscaling reduces the chance that a service saturates under normal demand changes. It provides a control loop that reacts faster than manual operations and helps keep enough healthy pods available during spikes.

## Cost Optimization Benefits

Autoscaling prevents every workload from being permanently sized for peak traffic. HPA can lower pod counts when utilization drops, and node autoscaling can eventually remove unused infrastructure capacity.

This phase adds HPA architecture and Karpenter readiness documentation only. It does not install metrics-server, Karpenter, or Cluster Autoscaler.
