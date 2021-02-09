Feature: Regression testing cases

  # @author wduan@redhat.com
  # @case_id OCP-32853
  @admin
  Scenario: Check the binary files and selinux setting used by storage
    Given I store the schedulable nodes in the :nodes clipboard
    Given I repeat the following steps for each :node in cb.nodes:
    """
    When I use the "#{cb.node.name}" node
    And I run commands on the host:
      | ls /sbin/xfs_quota /etc/iscsi/initiatorname.iscsi && which losetup stat find nice du multipath iscsiadm lsattr test udevadm resize2fs xfs_growfs umount mkfs.ext3 mkfs.ext4 mkfs.xfs fsck blkid systemd-run mount.cifs mount.nfs |
    Then the step should succeed
    And the output should contain:
      | /sbin/xfs_quota                |
      | /etc/iscsi/initiatorname.iscsi |
      | /usr/sbin/losetup              |
      | /usr/bin/stat                  |
      | /usr/bin/find                  |
      | /usr/bin/nice                  |
      | /usr/bin/du                    |
      | /usr/sbin/multipath            |
      | /usr/sbin/iscsiadm             |
      | /usr/bin/lsattr                |
      | /usr/bin/test                  |
      | /usr/sbin/udevadm              |
      | /usr/sbin/resize2fs            |
      | /usr/sbin/xfs_growfs           |
      | /usr/bin/umount                |
      | /usr/sbin/mkfs.ext3            |
      | /usr/sbin/mkfs.ext4            |
      | /usr/sbin/mkfs.xfs             |
      | /usr/sbin/fsck                 |
      | /usr/sbin/blkid                |
      | /usr/bin/systemd-run           |
      | /usr/sbin/mount.cifs           |
      | /usr/sbin/mount.nfs            |
    And I run commands on the host:
      | getsebool virt_use_nfs virt_use_samba container_use_cephfs |
    Then the step should succeed
    And the output should contain:
      | container_use_cephfs --> on |
      | virt_use_nfs --> on         |
      | virt_use_samba --> on       |
    """
