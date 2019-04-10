# Sizing and Scaling CloudBees Core on Kubernetes
This document provides general recommendations about sizing and scaling a Kubernetes cluster for CloudBees Core.

## General scaling notes
When sizing and scaling a cluster you should consider the operational characteristics of Jenkins. The relevant ones are:

* Jenkins Masters are memory and disk IOPs bound.

* Build Agents are CPU and memory bound.

* Overall the cluster is memory bound.

## Recomendations for Sizing Cluster

These VM numbers are based on m4.large, a 2GB RAM MM image and a 2GB java build image which runs one job.

Each VM can host up to three MMs or jobs. To calculate the number of machines you need add the number MMs, concurrent jobs across all MMs you plan on running and one. Then divide that number by 3, rounding up.

Then find the auto-scaling group for your cluster and set the number of desired VMs to the calculated number. 

If you use a different size VM, use this formula to estimate the number of jobs and MMs per VM.

Take the RAM in GB of the VM and subtract one, then divide by 2 rounding down. This the number of jobs and MMs that can run on this VM. 

## Other Considerations

If you have a high ratio of concurrent jobs to MMs you may want increase the number of VMs such that each concurrent job has one core in the cluster. This is because most jobs are CPU bound.

If you are seeing build containers failing to start, try scaling the cluster. We have seen some cases where this will help.
