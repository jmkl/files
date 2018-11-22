INSTALL_DIR = join_paths(PLUGIN_DIR, 'core')

shared_module (
    'pantheon-files-contractor',
    'plugin.vala',

    dependencies : pantheon_files_core_dep,
    install: true,
    install_dir: INSTALL_DIR,
)

install_data (
    'contractor.plug',
    install_dir: INSTALL_DIR
)
