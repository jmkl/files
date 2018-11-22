pantheon_files_core_name = 'pantheon-files-core'

pantheon_files_core_files = files(
    'AbstractSidebar.vala',
    'AbstractSlot.vala',
    'Bookmark.vala',
    'BookmarkList.vala',
    'ConnectServerOperation.vala',
    'ConnectServerDialog.vala',
    'DndHandler.vala',
    'Enums.vala',
    'PixbufUtils.vala',
    'FileUtils.vala',
    'FileConflictDialog.vala',
    'gof-callwhenready.vala',
    'gof-directory-async.vala',
    'gof-preferences.vala',
    'PluginManager.vala',
    'Plugin.vala',
    'ProgressInfo.vala',
    'ProgressInfoManager.vala',
    'SidebarPluginItem.vala',
    'SoundManager.vala',
    'StockDialogs.vala',
    'TrashMonitor.vala',
    'UserUtils.vala',
    'IconInfo.vala',
    'Thumbnailer.vala',

    'eel-string.c',
    'marlin-file-operations.c',
    'marlin-undostack-manager.c',
    'marlin-file-changes-queue.c',
    'fm-list-model.c',
    'gof-file.c',
)

pantheon_files_core_library = shared_library (
    pantheon_files_core_name,
    pantheon_files_core_files,
    dependencies : [CORE_LIB_DEPS, C_CORE_DEP, OTHER_DEPS],
    install: true,
    install_dir: [true, true, true],
    version: meson.project_version(),
    soversion: '0',
)

pantheon_files_core_dep = declare_dependency (
    link_with: pantheon_files_core_library,
    include_directories: include_directories('.'),
    dependencies : [CORE_LIB_DEPS, C_CORE_DEP, OTHER_DEPS],
)

pantheon_files_core_pkgconfig = pkg.generate (
    libraries: pantheon_files_core_library,
    filebase: pantheon_files_core_name,
    name: 'elementary Files Core Library',
    description: 'Core library io.elementary.files and io.elementary.filechooser',
    version: meson.project_version(),
)

subdir ('tests')
