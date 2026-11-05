fn impl_roc_os_read_file(path: RocStr) -> HostOsReadFileResult { abort("os_read_file"); }
fn impl_roc_os_write_file(path: RocStr, bytes: RocList) -> HostOsWriteFileResult { abort("os_write_file"); }
fn impl_roc_os_append_file(path: RocStr, bytes: RocList) -> HostOsWriteFileResult { abort("os_append_file"); }
fn impl_roc_os_file_exists(path: RocStr) -> HostOsFileExistsResult { abort("os_file_exists"); }
fn impl_roc_os_remove_file(path: RocStr) -> HostOsWriteFileResult { abort("os_remove_file"); }
fn impl_roc_os_list_dir(path: RocStr) -> HostOsListDirResult { abort("os_list_dir"); }
fn impl_roc_os_create_dir(path: RocStr) -> HostOsWriteFileResult { abort("os_create_dir"); }
fn impl_roc_os_remove_dir(path: RocStr) -> HostOsWriteFileResult { abort("os_remove_dir"); }
fn impl_roc_os_cwd() -> HostOsCwdResult { abort("os_cwd"); }  // or HostOsCwdResult if distinct
fn impl_roc_os_set_cwd(path: RocStr) -> HostOsWriteFileResult { abort("os_set_cwd"); }
fn impl_roc_os_clock_secs() -> HostOsClockSecsResult { abort("os_clock_secs"); }
fn impl_roc_os_monotonic_secs() -> HostOsClockSecsResult { abort("os_monotonic_secs"); }
fn impl_roc_os_sleep_ms(ms: u64) -> HostOsWriteFileResult { abort("os_sleep_ms"); }
fn impl_roc_os_env_get(key: RocStr) -> HostOsCwdResult { abort("os_env_get"); }
fn impl_roc_os_env_set(key: RocStr, val: RocStr) -> HostOsWriteFileResult { abort("os_env_set"); }
fn impl_roc_os_env_list() -> HostOsEnvListResult { abort("os_env_list"); }
