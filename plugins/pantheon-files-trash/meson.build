INSTALL_DIR = join_paths(PLUGIN_DIR, 'trash')

shared_module (
    'pantheon-files-trash',
    'plugin.vala',

    dependencies : pantheon_files_core_dep,
    install: true,
    install_dir: INSTALL_DIR,
)

install_data (
    'pantheon-files-trash.plug',
    install_dir: INSTALL_DIR
)
