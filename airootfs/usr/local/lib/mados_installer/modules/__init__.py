"""
madOS Installer Modules

Modular components for the installation process:
- partitioning: Disk partitioning, formatting, and mounting
- file_copier: File and script copying operations
- packages: Package management (pacman, pacstrap, rsync)
- config_generator: System configuration generation
"""

from .partitioning import (
    get_partition_prefix,
    step_partition_disk,
    create_root_partition,
    step_format_partitions,
    format_partitions_demo,
    format_partitions_real,
    step_mount_filesystems,
)

from .file_copier import (
    copy_item,
    ensure_kernel_in_target,
    step_copy_live_files,
    step_copy_scripts,
    step_copy_desktop_files,
)

from .packages import (
    post_rsync_cleanup,
    rsync_rootfs_with_progress,
    prepare_pacman,
    download_packages_with_progress,
    run_pacstrap_with_progress,
    run_single_pacstrap,
)

from .config_generator import (
    run_chroot_with_progress,
    build_config_script,
)

__all__ = [
    # Partitioning
    "get_partition_prefix",
    "step_partition_disk",
    "create_root_partition",
    "step_format_partitions",
    "format_partitions_demo",
    "format_partitions_real",
    "step_mount_filesystems",
    # File copier
    "copy_item",
    "ensure_kernel_in_target",
    "step_copy_live_files",
    "step_copy_scripts",
    "step_copy_desktop_files",
    # Packages
    "post_rsync_cleanup",
    "rsync_rootfs_with_progress",
    "prepare_pacman",
    "download_packages_with_progress",
    "run_pacstrap_with_progress",
    "run_single_pacstrap",
    # Config generator
    "run_chroot_with_progress",
    "build_config_script",
]
