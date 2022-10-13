require "../spec_helper"
require "airgap"
require "kubectl_client"
require "../../src/tasks/utils/kernel_instrospection.cr"
require "file_utils"
require "sam"

describe "KernelInstrospection" do

  it "'#status_by_proc' should return all statuses for all containers in a pod", tags: ["kernel-introspection"] do
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    pods.should_not be_nil

    KubectlClient::Get.resource_wait_for_install("Daemonset", "cri-tools")
    pods.size.should be > 0
    first_node = pods[0]
    statuses = KernelIntrospection::K8s.status_by_proc(first_node.dig("metadata", "name"), "cri-tools")
    LOGGING.info "statuses: #{statuses}"
    (statuses).should_not be_nil

    (statuses.find{|x| x["cmdline"]=="sleep\u0000infinity\u0000"} ).should_not be_nil
  end

  # it "'#find_first_process' should return all statuses for all containers in a pod", tags: ["kernel-introspection"]  do
  #   # KubectlClient::Apply.namespace(TESTSUITE_NAMESPACE)
  #   begin
  #     LOGGING.info `./cnf-testsuite cnf_setup cnf-path=sample-cnfs/sample_coredns`
  #     # Dockerd.install
  #     pod_info = KernelIntrospection::K8s.find_first_process("coredns")
  #     Log.info { "pod_info: #{pod_info}"}
  #     (pod_info).should_not be_nil
  #   ensure
  #     LOGGING.info `./cnf-testsuite cnf_cleanup cnf-path=sample-cnfs/sample_coredns`
  #     $?.success?.should be_true
  #   end
  end

end

