require "./spec_helper"
require "kubectl_client"
require "./../src/kernel_introspection.cr"
require "file_utils"

describe "KernelInstrospection" do
  before_all do
    KubectlClient::Create.namespace("cnf-testsuite")
    ClusterTools.install
  end

  it "'#status_by_proc' should return all statuses for all containers in a pod", tags: ["status_by_proc"] do
    result = KubectlClient::ShellCmd.run("kubectl run nginx --image=nginx --labels='name=nginx'", "kubectl_run_nginx", force_output=true)
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods.should_not be_nil
    pods = KubectlClient::Get.pods_by_label(pods, "name", "nginx")
    pods.should_not be_nil

    KubectlClient::Get.resource_wait_for_install("pod", "nginx")
    pods.size.should be > 0
    first_node = pods[0]
    statuses = KernelIntrospection::K8s.status_by_proc(first_node.dig("metadata", "name"), "nginx")
    Log.info { "process-statuses: #{statuses}" }
    (statuses).should_not be_nil

    (statuses.find{|x| x["cmdline"].includes?("nginx: master process")} ).should_not be_nil

    KubectlClient::Delete.command("pod/nginx")
  end

  it "'#find_first_process' should return first matching process", tags: ["find_first_proc"]  do
    result = KubectlClient::ShellCmd.run("kubectl run nginx --image=nginx --labels='name=nginx'", "kubectl_run_nginx", force_output=true)
    KubectlClient::Get.resource_wait_for_install("pod", "nginx")
    begin
      KubectlClient::ShellCmd.run("kubectl get pods", "kubectl_get_pods",force_output=true)
      pod_info = KernelIntrospection::K8s.find_first_process("nginx: master process")
      Log.info { "pod_info: #{pod_info}"}
      (pod_info).should_not be_nil
    ensure
      KubectlClient::Delete.command("pod/nginx")
    end
  end

  it "'#find_matching_processes' should return all matching processes", tags: ["find_first_proc"]  do
    result = KubectlClient::ShellCmd.run("kubectl run nginx --image=nginx --labels='name=nginx'", "kubectl_run_nginx", force_output=true)
    KubectlClient::Get.resource_wait_for_install("pod", "nginx")
    KubectlClient::ShellCmd.run("kubectl get pods", "kubectl_get_pods",force_output=true)
    begin
      pods_info = KernelIntrospection::K8s.find_matching_processes("nginx")
      Log.info { "pods_info: #{pods_info}"}
      (pods_info).size.should be > 0
    ensure
      KubectlClient::Delete.command("pod/nginx")
    end
  end

end
