Feature: image-inspector test
   # @author wzheng@redhat.com
   # @case_id OCP-9803
   @admin
   Scenario: Test openshift3/aep3 image-inspector
     Given I select a random node's host
     Given I run commands on the host:
       | docker run -ti -d --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -p 8080:8080 <%= product_docker_repo %>openshift3/image-inspector:latest --image=openshift/base-centos7 --serve=0.0.0.0:8080 --scan-type=openscap |
     And the step should succeed
     When I run commands on the host:
       | docker ps \| grep  inspector \| awk -F' ' '{print $1}' |
     Then the step should succeed
     And evaluation of `@result[:response].chomp` is stored in the :containerID clipboard
     Given I run commands on the host:
       | docker exec <%= cb.containerID %> find / -name redhat-release |
     And the output should contain "redhat-release"
