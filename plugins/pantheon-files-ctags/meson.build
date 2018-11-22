INSTALL_DIR = join_paths(PLUGIN_DIR, 'ctags')

shared_module (
    'pantheon-files-ctags',
    'plugin.vala',

    dependencies : pantheon_files_core_dep,
    install: true,
	install_dir: INSTALL_DIR,
)

install_data (
    'pantheon-files-ctags.plug',
    install_dir: INSTALL_DIR
)
